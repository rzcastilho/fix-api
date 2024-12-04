defmodule FixApi.Messages.Reject do
  use FixApi.Message,
    msg_type: "3"

  field(:ref_seq_num, 45, :int, false)
  field(:ref_tag_id, 371, :int, false)
  field(:ref_msg_type, 372, :string, false)
  field(:session_reject_reason, 373, :int, false)
  field(:error_code, 25016, :int, false)
  field(:text, 58, :string, false)
end
