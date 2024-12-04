defmodule FixApi.Messages.NewOrderSingle do
  @moduledoc """
  Example:
  8=FIX.4.4|9=114|35=D|34=2|49=qNXO12fH|52=20240611-09:01:46.228|56=SPOT|11=1718096506197867067|38=5|40=2|44=10|54=1|55=LTCBNB|59=4|10=016|
  """
  use FixApi.Message,
    msg_type: "D"

  field(:cl_ord_id, 11, :string, true)
  field(:order_qty, 38, :qty, false)
  field(:ord_type, 40, :char, true)
  field(:exec_inst, 18, :char, false)
  field(:price, 44, :price, false)
  field(:side, 54, :char, true)
  field(:symbol, 55, :string, true)
  field(:time_in_force, 59, :char, false)
  field(:max_floor, 111, :qty, false)
  field(:cash_order_qty, 152, :qty, false)
  field(:target_strategy, 847, :int, false)
  field(:strategy_id, 7940, :int, false)
  field(:self_trade_prevention_mode, 25001, :char, false)
  field(:trigger_type, 1100, :char, false)
  field(:trigger_action, 1101, :char, false)
  field(:trigger_price, 1102, :price, false)
  field(:trigger_price_type, 1107, :char, false)
  field(:trigger_price_direction, 1109, :char, false)
  field(:trigger_trailing_delta_bips, 25009, :int, false)
  field(:sor, 25032, :boolean, false)

  def build(msg_seq_num, sender_comp_id, order_type, side, qty, price, symbol, time_in_force) do
    init()
    |> set([
      {34, msg_seq_num},
      {49, sender_comp_id},
      {11, DateTime.utc_now() |> DateTime.to_unix()},
      {40, order_type},
      {54, side},
      {55, symbol},
      {38, qty},
      {44, price},
      {59, time_in_force}
    ])
    |> calculated_fields()
  end
end
