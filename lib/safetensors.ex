defmodule Safetensors do
  @moduledoc """
  Documentation for `Safetensors`.
  """

  # https://huggingface.co/docs/safetensors/index#format

  @header_metadata_key "__metadata__"

  @type_to_dtype %{
    {:bf, 16} => "BF16",
    {:f, 64} => "F64",
    {:f, 32} => "F32",
    {:f, 16} => "F16",
    {:s, 64} => "I64",
    {:s, 32} => "I32",
    {:s, 16} => "I16",
    {:s, 8} => "I8",
    {:u, 64} => "U64",
    {:u, 32} => "U32",
    {:u, 16} => "U16",
    {:u, 8} => "U8"
  }

  @dtype_to_type for {k, v} <- @type_to_dtype, into: %{}, do: {v, k}

  def dump(tensors) when is_map(tensors) do
    {header, buffer} =
      tensors
      |> Enum.map_reduce(
        <<>>,
        fn {tensor_name, tensor}, buffer ->
          binary = Nx.to_binary(tensor)
          offset = byte_size(buffer)

          {
            {
              tensor_name,
              Jason.OrderedObject.new(
                dtype: tensor |> Nx.type() |> type_to_dtype(),
                shape: tensor |> Nx.shape() |> Tuple.to_list(),
                data_offsets: [offset, offset + byte_size(binary)]
              )
            },
            buffer <> binary
          }
        end
      )

    header_json =
      header
      |> Jason.OrderedObject.new()
      |> Jason.encode!()

    <<
      String.length(header_json)::unsigned-64-integer-little,
      header_json::binary,
      buffer::binary
    >>
  end

  def load!(data) when is_binary(data) do
    <<
      header_size::unsigned-64-integer-little,
      header_json::binary-size(header_size),
      buffer::binary
    >> = data

    {_metadata, header} =
      header_json
      |> Jason.decode!()
      |> Map.pop(@header_metadata_key)

    header
    |> Enum.into(%{}, fn {tensor_name, tensor_info} ->
      %{
        "data_offsets" => [offset_start, offset_end],
        "dtype" => dtype,
        "shape" => shape
      } = tensor_info

      {
        tensor_name,
        buffer
        |> binary_part(offset_start, offset_end - offset_start)
        |> Nx.from_binary(dtype |> dtype_to_type())
        |> Nx.reshape(List.to_tuple(shape))
      }
    end)
  end

  defp type_to_dtype(type) do
    @type_to_dtype[type] || raise "unrecognized type #{inspect(type)}"
  end

  defp dtype_to_type(dtype) do
    @dtype_to_type[dtype] || raise "unrecognized dtype #{inspect(dtype)}"
  end
end
