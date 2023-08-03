defmodule SafetensorsTest do
  use ExUnit.Case
  doctest Safetensors

  test "load" do
    # source:
    # https://github.com/huggingface/safetensors/blob/1a65a3fdebcf280ef0ca32934901d3e2ad3b2c65/bindings/python/tests/test_simple.py#L35-L40
    serialized =
      ~s(<\x00\x00\x00\x00\x00\x00\x00{"test":{"dtype":"I32","shape":[2,2],"data_offsets":[0,16]}}\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00)

    assert Safetensors.load!(serialized) == %{"test" => Nx.tensor([[0, 0], [0, 0]], type: :s32)}
  end

  test "load with metadata" do
    # source:
    # https://github.com/huggingface/safetensors/blob/1a65a3fdebcf280ef0ca32934901d3e2ad3b2c65/bindings/python/tests/test_simple.py#L42-L50
    serialized =
      ~s(f\x00\x00\x00\x00\x00\x00\x00{"__metadata__":{"framework":"pt"},"test1":{"dtype":"I32","shape":[2,2],"data_offsets":[0,16]}}       \x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00)

    assert Safetensors.load!(serialized) == %{"test1" => Nx.tensor([[0, 0], [0, 0]], type: :s32)}
  end
end