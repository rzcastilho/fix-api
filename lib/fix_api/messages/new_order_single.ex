defmodule FixApi.Messages.NewOrderSingle do
  alias FixApi.Descriptor
  import FixApi.Helper

  @side %{buy: "1", sell: "2"}

  @ord_type_market "1"
  @ord_type_limit "2"
  # @ord_type_stop "3"
  # @ord_type_stop_limit "4"

  def request_market_order(side, symbol, order_qty) do
    :new_order_single
    |> Descriptor.new()
    |> Descriptor.set(
      cl_ord_id: generate_ord_id(),
      ord_type: @ord_type_market,
      symbol: symbol,
      side: @side[side],
      order_qty: format_qty(order_qty)
    )
  end

  def request_limit_order(side, symbol, order_qty, price, time_in_force \\ "1") do
    :new_order_single
    |> Descriptor.new()
    |> Descriptor.set(
      cl_ord_id: generate_ord_id(),
      ord_type: @ord_type_limit,
      symbol: symbol,
      side: @side[side],
      order_qty: format_qty(order_qty),
      price: format_price(price),
      time_in_force: time_in_force
    )
  end
end
