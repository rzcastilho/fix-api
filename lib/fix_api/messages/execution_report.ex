defmodule FixApi.Messages.ExecutionReport do
  @moduledoc """
  8=FIX.4.4|
  9=0000357|
  35=8|
  49=SPOT|
  56=283A5DC9|
  34=3943|
  52=20250411-21:35:00.425618|
  17=3041720|
  11=D60E9B3E8E04391F617BC2CF8E45D56C|
  37=1367668|
  38=16.00000000|
  40=2|
  54=1|
  55=XRPUSDT|
  44=2.03350000|
  59=1|
  60=20250411-21:35:00.425225|
  25018=20250411-21:35:00.425225|
  25001=3|
  150=0|
  14=0.00000000|
  151=16.00000000|
  25017=0.00000000|
  1057=Y|

  
  32=0.00000000|
  39=0|
  636=Y|
  25023=20250411-21:35:00.425225|
  10=055|
  -----------------------------------------------
  8=FIX.4.4|
  9=0000379|
  35=8|
  49=SPOT|
  56=283A5DC9|
  34=3944|
  52=20250411-21:35:00.425621|
  17=3041721|
  11=D60E9B3E8E04391F617BC2CF8E45D56C|
  37=1367668|
  38=16.00000000|
  40=2|
  54=1|
  55=XRPUSDT|
  44=2.03350000|
  59=1|
  60=20250411-21:35:00.425225|
  25018=20250411-21:35:00.425225|
  25001=3|
  150=F|
  14=16.00000000|
  151=0.00000000|
  25017=32.53120000|
  1057=Y|
  1003=308640|
  31=2.03320000|
  32=16.00000000|
  39=2|
  
  25023=20250411-21:35:00.425225|
  10=081|
  """
  alias FixApi.Descriptor
  alias FixApi.Schemas.{
    Data,
    Message
  }
  import FixApi.Helper

  def mock_from(%Message{name: :new_order_single, data: %Data{fields: fields}}) do
    :execution_report
    |> Descriptor.new()
    |> Descriptor.set(
      cl_ord_id: Keyword.get(fields, :cl_ord_id),
      sender_comp_id: Keyword.get(fields, :target_comp_id),
      target_comp_id: Keyword.get(fields, :sender_comp_id),
      exec_id: Enum.random(9999..9999999),
      order_id: Enum.random(9999..9999999),
      order_qty: Keyword.get(fields, :order_qty),
      ord_type: Keyword.get(fields, :ord_type),
      side: Keyword.get(fields, :side),
      symbol: Keyword.get(fields, :symbol),
      price: Keyword.get(fields, :price),
      time_in_force: Keyword.get(fields, :time_in_force),
      transact_time: DateTime.utc_now() |> Calendar.strftime("%Y%m%d-%H:%M:%S.%f"),
      order_creation_time: DateTime.utc_now() |> Calendar.strftime("%Y%m%d-%H:%M:%S.%f"),
      self_trade_prevention_mode: "3",
      exec_type: "0", # NEW
      cum_qty: 0.0,
      leaves_qty: Keyword.get(fields, :order_qty),
      cum_quote_qty: 0.0,
      aggressor_indicator: "Y",
      last_qty: 0.0,
      ord_status: "0", # NEW
      working_indicator: "Y",
      working_time: DateTime.utc_now() |> Calendar.strftime("%Y%m%d-%H:%M:%S.%f")
    )
  end

  def mock_from(%Message{name: :execution_report, data: %Data{fields: fields}}) do
    cum_quote_qty =
      to_float(Keyword.get(fields, :order_qty)) * to_float(Keyword.get(fields, :price))
    :execution_report
    |> Descriptor.new()
    |> Descriptor.set(fields)
    |> Descriptor.set(
      exec_id: Enum.random(9999..9999999),
      exec_type: "F", # TRADE
      cum_qty: Keyword.get(fields, :leaves_qty),
      leaves_qty: 0.0,
      cum_quote_qty: cum_quote_qty,
      trade_id: Enum.random(9999..9999999),
      last_px: Keyword.get(fields, :price),
      last_qty: Keyword.get(fields, :order_qty),
      ord_status: "2", # FILLED
      working_indicator: nil
    )
  end
end
