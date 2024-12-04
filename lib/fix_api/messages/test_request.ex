defmodule FixApi.Messages.TestRequest do
  use FixApi.Message,
    msg_type: "1"

  field(:test_req_id, 112, :string, false)
end
