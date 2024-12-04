defmodule FixApi.Messages.Heartbeat do
  use FixApi.Message,
    msg_type: "0"

  field(:test_req_id, 112, :string, false)

  def build(msg_seq_num, sender_comp_id, test_req_id) do
    init()
    |> set([
      {34, msg_seq_num},
      {49, sender_comp_id},
      {112, test_req_id}
    ])
    |> calculated_fields()
  end
end
