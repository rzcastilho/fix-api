defmodule FixApi.Messages.OrderCancelRequest do
  alias FixApi.Descriptor
  import FixApi.Helper

  def request(symbol, orig_cl_ord_id) do
    :order_cancel_request
    |> Descriptor.new()
    |> Descriptor.set(
      cl_ord_id: generate_ord_id(),
      symbol: symbol,
      orig_cl_ord_id: orig_cl_ord_id
    )
  end
end
