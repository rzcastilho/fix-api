defmodule FixApi.Messages.NewOrderSingle do
  alias FixApi.Descriptor

  @side %{buy: "1", sell: "2"}

  @ord_type_market "1"
  @ord_type_limit "2"
  # @ord_type_stop "3"
  # @ord_type_stop_limit "4"

  def request_market_order(side, symbol, order_qty) do
    :new_order_single
    |> Descriptor.new()
    |> Descriptor.set(
      cl_ord_id: :crypto.strong_rand_bytes(16) |> Base.encode16(),
      ord_type: @ord_type_market,
      symbol: symbol,
      side: @side[side],
      order_qty: order_qty
    )
  end

  def request_limit_order(side, symbol, order_qty, price, time_in_force \\ "1") do
    :new_order_single
    |> Descriptor.new()
    |> Descriptor.set(
      cl_ord_id: :crypto.strong_rand_bytes(16) |> Base.encode16(),
      ord_type: @ord_type_limit,
      symbol: symbol,
      side: @side[side],
      order_qty: order_qty,
      price: price,
      time_in_force: time_in_force
    )
  end
end
