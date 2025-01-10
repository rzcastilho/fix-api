defmodule FixApi.Messages.Logout do
  alias FixApi.Descriptor

  def request() do
    :logout
    |> Descriptor.new()
  end
end
