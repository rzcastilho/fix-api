defmodule FixApi.Messages.Logout do
  use FixApi.Message,
    msg_type: "5"

  field(:text, 58, :string, false)
end
