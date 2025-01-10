defmodule FixApi.Messages.Heartbeat do
  alias FixApi.Descriptor

  def request(test_req_id) do
    :heartbeat
    |> Descriptor.new()
    |> Descriptor.set(test_req_id: test_req_id)
  end
end
