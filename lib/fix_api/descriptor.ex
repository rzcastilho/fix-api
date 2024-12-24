defmodule FixApi.Descriptor do
  use FixApi.DSL

  field :begin_string, tag: 8, type: :string do
    value("FIX.4.4", description: "FIX44")
  end

  field(:body_length, tag: 9, type: :length)
  field(:check_sum, tag: 10, type: :string)
  field(:cl_ord_id, tag: 11, type: :string)
  field(:cum_qty, tag: 14, type: :qty)
  field(:exec_id, tag: 17, type: :int)

  field :exec_inst, tag: 18, type: :char do
    value("6", description: "PARTICIPATE_DONT_INITIATE")
  end

  field(:last_px, tag: 31, type: :price)
  field(:last_qty, tag: 32, type: :qty)
  field(:msg_seq_num, tag: 34, type: :seqnum)

  field(:msg_type, tag: 35, type: :string) do
    value("0", description: "HEARTBEAT")
    value("1", description: "TEST_REQUEST")
    value("3", description: "REJECT")
    value("5", description: "LOGOUT")
    value("8", description: "EXECUTION_REPORT")
    value("9", description: "ORDER_CANCEL_REJECT")
    value("A", description: "LOGON")
    value("B", description: "NEWS")
    value("D", description: "NEW_ORDER_SINGLE")
    value("E", description: "NEW_ORDER_LIST")
    value("F", description: "ORDER_CANCEL_REQUEST")
    value("N", description: "LIST_STATUS")
    value("q", description: "ORDER_MASS_CANCEL_REQUEST")
    value("r", description: "ORDER_MASS_CANCEL_REPORT")
    value("XCN", description: "ORDER_CANCEL_REQUEST_AND_NEW_ORDER_SINGLE")
    value("XLQ", description: "LIMIT_QUERY")
    value("XLR", description: "LIMIT_RESPONSE")
  end

  field(:order_id, tag: 37, type: :int)
  field(:order_qty, tag: 38, type: :qty)

  field(:ord_status, tag: 39, type: :char) do
    value("0", description: "NEW")
    value("1", description: "PARTIALLY_FILLED")
    value("2", description: "FILLED")
    value("4", description: "CANCELED")
    value("6", description: "PENDING_CANCEL")
    value("8", description: "REJECTED")
    value("A", description: "PENDING_NEW")
    value("C", description: "EXPIRED")
  end

  field(:ord_type, tag: 40, type: :char) do
    value("1", description: "MARKET")
    value("2", description: "LIMIT")
    value("3", description: "STOP")
    value("4", description: "STOP_LIMIT")
  end

  field(:orig_cl_ord_id, tag: 41, type: :string)
  field(:price, tag: 44, type: :price)
  field(:ref_seq_num, tag: 45, type: :int)
  field(:sender_comp_id, tag: 49, type: :string)
  field(:sending_time, tag: 52, type: :utctimestamp)

  field(:side, tag: 54, type: :char) do
    value("1", description: "BUY")
    value("2", description: "SELL")
  end

  field(:symbol, tag: 55, type: :string)
  field(:target_comp_id, tag: 56, type: :string)
  field(:text, tag: 58, type: :string)

  field(:time_in_force, tag: 59, type: :char) do
    value("1", description: "GOOD_TILL_CANCEL")
    value("3", description: "IMMEDIATE_OR_CANCEL")
    value("4", description: "FILL_OR_KILL")
  end

  field(:transact_time, tag: 60, type: :utctimestamp)
  field(:list_id, tag: 66, type: :int)
  field(:alloc_id, tag: 70, type: :int)
  field(:no_orders, tag: 73, type: :numingroup)
  field(:raw_data_length, tag: 95, type: :length)
  field(:raw_data, tag: 96, type: :data)

  field(:encrypt_method, tag: 98, type: :int) do
    value("0", description: "NONE")
  end

  field(:ord_rej_reason, tag: 103, type: :int) do
    value("99", description: "OTHER")
  end

  field(:heart_bt_int, tag: 108, type: :int)
  field(:max_floor, tag: 111, type: :qty)
  field(:test_req_id, tag: 112, type: :string)
  field(:no_misc_fees, tag: 136, type: :numingroup)
  field(:misc_fee_amt, tag: 137, type: :qty)
  field(:misc_fee_curr, tag: 138, type: :string)

  field(:misc_fee_type, tag: 139, type: :int) do
    value("4", description: "EXCHANGE_FEES")
  end

  field(:reset_seq_num_flag, tag: 141, type: :boolean) do
    value("Y", description: "YES")
    value("N", description: "NO")
  end

  field(:headline, tag: 148, type: :string)

  field(:exec_type, tag: 150, type: :char) do
    value("0", description: "NEW")
    value("4", description: "CANCELED")
    value("5", description: "REPLACED")
    value("8", description: "REJECTED")
    value("F", description: "TRADE")
    value("C", description: "EXPIRED")
  end

  field(:leaves_qty, tag: 151, type: :qty)
  field(:cash_order_qty, tag: 152, type: :qty)
  field(:ref_tag_id, tag: 371, type: :int)
  field(:ref_msg_type, tag: 372, type: :string)

  field(:session_reject_reason, tag: 373, type: :int) do
    value("0", description: "INVALID_TAG_NUMBER")
    value("1", description: "REQUIRED_TAG_MISSING")
    value("2", description: "TAG_NOT_DEFINED_FOR_THIS_MESSAGE_TYPE")
    value("3", description: "UNDEFINED_TAG")
    value("5", description: "VALUE_IS_INCORRECT")
    value("6", description: "INCORRECT_DATA_FORMAT_FOR_VALUE")
    value("8", description: "SIGNATURE_PROBLEM")
    value("10", description: "SENDINGTIME_ACCURACY_PROBLEM")
    value("13", description: "TAG_APPEARS_MORE_THAN_ONCE")
    value("14", description: "TAG_SPECIFIED_OUT_OF_REQUIRED_ORDER")
    value("15", description: "REPEATING_GROUP_FIELDS_OUT_OF_ORDER")
    value("16", description: "INCORRECT_NUMINGROUP_COUNT_FOR_REPEATING_GROUP")
    value("99", description: "OTHER")
  end

  field(:list_status_type, tag: 429, type: :int) do
    value("2", description: "RESPONSE")
    value("4", description: "EXEC_STARTED")
    value("5", description: "ALL_DONE")
  end

  field(:list_order_status, tag: 431, type: :int) do
    value("3", description: "EXECUTING")
    value("6", description: "ALL_DONE")
    value("7", description: "REJECT")
  end

  field(:cxl_rej_response_to, tag: 434, type: :char) do
    value("1", description: "ORDER_CANCEL_REQUEST")
  end

  field(:mass_cancel_request_type, tag: 530, type: :char) do
    value("1", description: "CANCEL_SYMBOL_ORDERS")
  end

  field(:mass_cancel_response, tag: 531, type: :char) do
    value("0", description: "CANCEL_REQUEST_REJECTED")
    value("1", description: "CANCEL_SYMBOL_ORDERS")
  end

  field(:mass_cancel_reject_reason, tag: 532, type: :int) do
    value("99", description: "OTHER")
  end

  field(:total_affected_orders, tag: 533, type: :int)
  field(:username, tag: 553, type: :string)

  field(:match_type, tag: 574, type: :string) do
    value("1", description: "ONE_PARTY_TRADE_REPORT")
    value("4", description: "AUTO_MATCH")
  end

  field(:working_indicator, tag: 636, type: :boolean)
  field(:price_delta, tag: 811, type: :int)
  field(:target_strategy, tag: 847, type: :int)
  field(:trade_id, tag: 1003, type: :int)

  field(:aggressor_indicator, tag: 1057, type: :boolean) do
    value("Y", description: "ORDER_INITIATOR_IS_AGGRESSOR")
    value("N", description: "ORDER_INITIATOR_IS_PASSIVE")
  end

  field(:trigger_type, tag: 1100, type: :char) do
    value("4", description: "PRICE_MOVEMENT")
  end

  field(:trigger_action, tag: 1101, type: :char) do
    value("1", description: "ACTIVATE")
  end

  field(:trigger_price, tag: 1102, type: :price)

  field(:trigger_price_type, tag: 1107, type: :char) do
    value("2", description: "LAST_TRADE")
  end

  field(:trigger_price_direction, tag: 1109, type: :char) do
    value("U",
      description:
        "TRIGGER_IF_THE_PRICE_OF_THE_SPECIFIED_TYPE_GOES_UP_TO_OR_THROUGH_THE_SPECIFIED_TRIGGER_PRICE"
    )

    value("D",
      description:
        "TRIGGER_IF_THE_PRICE_OF_THE_SPECIFIED_TYPE_GOES_DOWN_TO_OR_THROUGH_THE_SPECIFIED_TRIGGER_PRICE"
    )
  end

  field(:contingency_type, tag: 1385, type: :int) do
    value("1", description: "ONE_CANCELS_THE_OTHER")
    value("2", description: "ONE_TRIGGERS_THE_OTHER")
  end

  field(:list_reject_reason, tag: 1386, type: :int) do
    value("99", description: "OTHER")
  end

  field(:req_id, tag: 6136, type: :string)
  field(:strategy_id, tag: 7940, type: :int)
  field(:drop_copy_flag, tag: 9406, type: :boolean)
  field(:recv_window, tag: 25000, type: :int)

  field(:self_trade_prevention_mode, tag: 25001, type: :char) do
    value("1", description: "NONE")
    value("2", description: "EXPIRE_TAKER")
    value("3", description: "EXPIRE_MAKER")
    value("4", description: "EXPIRE_BOTH")
  end

  field(:cancel_restrictions, tag: 25002, type: :int) do
    value("1", description: "ONLY_NEW")
    value("2", description: "ONLY_PARTIALLY_FILLED")
  end

  field(:no_limit_indicators, tag: 25003, type: :numingroup)

  field(:limit_type, tag: 25004, type: :char) do
    value("1", description: "ORDER_LIMIT")
    value("2", description: "MESSAGE_LIMIT")
  end

  field(:limit_count, tag: 25005, type: :int)

  field(:limit_max, tag: 25006, type: :int)

  field(:limit_reset_interval, tag: 25007, type: :int)

  field(:limit_reset_interval_resolution, tag: 25008, type: :char) do
    value("s", description: "SECOND")
    value("m", description: "MINUTE")
    value("h", description: "HOUR")
    value("d", description: "DAY")
  end

  field(:trigger_trailing_delta_bips, tag: 25009, type: :int)

  field(:no_list_triggering_instructions, tag: 25010, type: :numingroup)

  field(:list_trigger_type, tag: 25011, type: :char) do
    value("1", description: "ACTIVATED")
    value("2", description: "PARTIALLY_FILLED")
    value("3", description: "FILLED")
  end

  field(:list_trigger_trigger_index, tag: 25012, type: :int)

  field(:list_trigger_action, tag: 25013, type: :char) do
    value("1", description: "RELEASE")
    value("2", description: "CANCEL")
  end

  field(:cl_list_id, tag: 25014, type: :string)
  field(:orig_cl_list_id, tag: 25015, type: :string)
  field(:error_code, tag: 25016, type: :int)
  field(:cum_quote_qty, tag: 25017, type: :qty)
  field(:order_creation_time, tag: 25018, type: :utctimestamp)

  field(:working_floor, tag: 25021, type: :int) do
    value("1", description: "EXCHANGE")
    value("2", description: "BROKER")
    value("3", description: "SOR")
  end

  field(:trailing_time, tag: 25022, type: :utctimestamp)
  field(:working_time, tag: 25023, type: :utctimestamp)
  field(:prevented_match_id, tag: 25024, type: :int)
  field(:prevented_execution_price, tag: 25025, type: :price)
  field(:prevented_execution_qty, tag: 25026, type: :qty)
  field(:trade_group_id, tag: 25027, type: :int)
  field(:counter_symbol, tag: 25028, type: :string)
  field(:counter_order_id, tag: 25029, type: :int)
  field(:prevented_qty, tag: 25030, type: :qty)
  field(:last_prevented_qty, tag: 25031, type: :qty)
  field(:sor, tag: 25032, type: :boolean)

  field(:order_cancel_request_and_new_order_single_mode, tag: 25033, type: :int) do
    value("1", description: "STOP_ON_FAILURE")
    value("2", description: "ALLOW_FAILURE")
  end

  field(:cancel_cl_ord_id, tag: 25034, type: :string)

  field(:message_handling, tag: 25035, type: :int) do
    value("1", description: "UNORDERED")
    value("2", description: "SEQUENTIAL")
  end

  field(:response_mode, tag: 25036, type: :int) do
    value("1", description: "EVERYTHING")
    value("2", description: "ONLY_ACKS")
  end

  field(:uuid, tag: 25037, type: :string)

  field(:order_rate_limit_exceeded_mode, tag: 25038, type: :int) do
    value("1", description: "DO_NOTHING")
    value("2", description: "CANCEL_ONLY")
  end

  trailer do
    field_ref(:check_sum, required: true)
  end

  header do
    field_ref(:begin_string, required: true)
    field_ref(:body_length, required: true)
    field_ref(:msg_type, required: true)
    field_ref(:sender_comp_id, required: true)
    field_ref(:target_comp_id, required: true)
    field_ref(:msg_seq_num, required: true)
    field_ref(:sending_time, required: true)
    field_ref(:recv_window, required: false)
  end

  component(:triggering_instruction) do
    field_ref(:trigger_type, required: false)
    field_ref(:trigger_action, required: false)
    field_ref(:trigger_price, required: false)
    field_ref(:trigger_price_type, required: false)
    field_ref(:trigger_price_direction, required: false)
    field_ref(:trigger_trailing_delta_bips, required: false)
  end

  component(:list_triggering_instruction) do
    group(:no_list_triggering_instructions, required: false) do
      field_ref(:list_trigger_type, required: true)
      field_ref(:list_trigger_trigger_index, required: true)
      field_ref(:list_trigger_action, required: true)
    end
  end

  component(:new_order) do
    field_ref(:cl_ord_id, required: true)
    field_ref(:order_qty, required: false)
    field_ref(:ord_type, required: true)
    field_ref(:exec_inst, required: false)
    field_ref(:price, required: false)
    component_ref(:triggering_instruction, required: false)
    field_ref(:side, required: true)
    field_ref(:symbol, required: true)
    field_ref(:time_in_force, required: false)
    field_ref(:max_floor, required: false)
    field_ref(:cash_order_qty, required: false)
    field_ref(:target_strategy, required: false)
    field_ref(:strategy_id, required: false)
    field_ref(:self_trade_prevention_mode, required: false)
  end

  message(:heartbeat, category: :admin, type: "0") do
    field_ref(:test_req_id, required: false)
  end

  message(:test_request, category: :admin, type: "1") do
    field_ref(:test_req_id, required: true)
  end

  message(:reject, category: :admin, type: "3") do
    field_ref(:ref_seq_num, required: false)
    field_ref(:ref_tag_id, required: false)
    field_ref(:ref_msg_type, required: false)
    field_ref(:session_reject_reason, required: false)
    field_ref(:error_code, required: false)
    field_ref(:text, required: false)
  end

  message(:logout, category: :admin, type: "5") do
    field_ref(:text, required: false)
  end

  message(:execution_report, category: :app, type: "8") do
    field_ref(:exec_id, required: false)
    field_ref(:cl_ord_id, required: false)
    field_ref(:orig_cl_ord_id, required: false)
    field_ref(:order_id, required: false)
    field_ref(:order_qty, required: false)
    field_ref(:ord_type, required: true)
    field_ref(:side, required: true)
    field_ref(:symbol, required: true)
    field_ref(:exec_inst, required: false)
    field_ref(:price, required: false)
    component_ref(:triggering_instruction, required: false)
    field_ref(:time_in_force, required: false)
    field_ref(:transact_time, required: false)
    field_ref(:order_creation_time, required: false)
    field_ref(:max_floor, required: false)
    field_ref(:list_id, required: false)
    field_ref(:cash_order_qty, required: false)
    field_ref(:target_strategy, required: false)
    field_ref(:strategy_id, required: false)
    field_ref(:self_trade_prevention_mode, required: false)
    field_ref(:exec_type, required: true)
    field_ref(:cum_qty, required: true)
    field_ref(:leaves_qty, required: false)
    field_ref(:cum_quote_qty, required: false)
    field_ref(:aggressor_indicator, required: false)
    field_ref(:trade_id, required: false)
    field_ref(:last_px, required: false)
    field_ref(:last_qty, required: true)
    field_ref(:ord_status, required: true)
    field_ref(:alloc_id, required: false)
    field_ref(:match_type, required: false)
    field_ref(:working_floor, required: false)
    field_ref(:working_indicator, required: false)
    field_ref(:working_time, required: false)
    field_ref(:trailing_time, required: false)
    field_ref(:prevented_match_id, required: false)
    field_ref(:prevented_execution_price, required: false)
    field_ref(:prevented_execution_qty, required: false)
    field_ref(:trade_group_id, required: false)
    field_ref(:counter_symbol, required: false)
    field_ref(:counter_order_id, required: false)
    field_ref(:prevented_qty, required: false)
    field_ref(:last_prevented_qty, required: false)
    field_ref(:sor, required: false)

    group(:no_misc_fees, required: false) do
      field_ref(:misc_fee_amt, required: true)
      field_ref(:misc_fee_curr, required: true)
      field_ref(:misc_fee_type, required: true)
    end

    field_ref(:ord_rej_reason, required: false)
    field_ref(:error_code, required: false)
    field_ref(:text, required: false)
  end

  message(:order_cancel_reject, category: :app, type: "9") do
    field_ref(:cl_ord_id, required: true)
    field_ref(:orig_cl_ord_id, required: false)
    field_ref(:order_id, required: false)
    field_ref(:orig_cl_list_id, required: false)
    field_ref(:list_id, required: false)
    field_ref(:symbol, required: true)
    field_ref(:cancel_restrictions, required: false)
    field_ref(:cxl_rej_response_to, required: true)
    field_ref(:error_code, required: true)
    field_ref(:text, required: true)
  end

  message(:order_cancel_request_and_new_order_single, category: :app, type: "XCN") do
    field_ref(:order_cancel_request_and_new_order_single_mode, required: true)
    field_ref(:order_rate_limit_exceeded_mode, required: false)
    field_ref(:order_id, required: false)
    field_ref(:cancel_cl_ord_id, required: false)
    field_ref(:orig_cl_ord_id, required: false)
    field_ref(:cancel_restrictions, required: false)
    component_ref(:new_order, required: true)
  end

  message(:logon, category: :admin, type: "A") do
    field_ref(:encrypt_method, required: false)
    field_ref(:heart_bt_int, required: true)
    field_ref(:raw_data_length, required: false)
    field_ref(:raw_data, required: false)
    field_ref(:reset_seq_num_flag, required: false)
    field_ref(:username, required: false)
    field_ref(:message_handling, required: false)
    field_ref(:response_mode, required: false)
    field_ref(:drop_copy_flag, required: false)
    field_ref(:uuid, required: false)
  end

  message(:new_order_single, category: :app, type: "D") do
    component_ref(:new_order, required: true)
    field_ref(:sor, required: false)
  end

  message(:new_order_list, category: :app, type: "E") do
    field_ref(:cl_list_id, required: true)
    field_ref(:contingency_type, required: true)

    group(:no_orders, required: false) do
      component_ref(:new_order, required: true)
      component_ref(:list_triggering_instruction, required: false)
    end
  end

  message(:order_cancel_request, category: :app, type: "F") do
    field_ref(:cl_ord_id, required: true)
    field_ref(:orig_cl_ord_id, required: false)
    field_ref(:order_id, required: false)
    field_ref(:orig_cl_list_id, required: false)
    field_ref(:list_id, required: false)
    field_ref(:symbol, required: true)
    field_ref(:cancel_restrictions, required: false)
  end

  message(:list_status, category: :app, type: "N") do
    field_ref(:symbol, required: true)
    field_ref(:list_id, required: false)
    field_ref(:cl_list_id, required: false)
    field_ref(:orig_cl_list_id, required: false)
    field_ref(:contingency_type, required: false)
    field_ref(:list_status_type, required: true)
    field_ref(:list_order_status, required: true)
    field_ref(:list_reject_reason, required: false)
    field_ref(:transact_time, required: false)

    group(:no_orders, required: false) do
      field_ref(:cl_ord_id, required: true)
      field_ref(:symbol, required: true)
      field_ref(:order_id, required: false)
      component_ref(:list_triggering_instruction, required: false)
      field_ref(:ord_rej_reason, required: false)
      field_ref(:error_code, required: false)
      field_ref(:text, required: false)
    end
  end

  message(:order_mass_cancel_request, category: :app, type: "q") do
    field_ref(:symbol, required: true)
    field_ref(:cl_ord_id, required: true)
    field_ref(:mass_cancel_request_type, required: true)
  end

  message(:order_mass_cancel_report, category: :app, type: "r") do
    field_ref(:symbol, required: true)
    field_ref(:cl_ord_id, required: true)
    field_ref(:mass_cancel_request_type, required: true)
    field_ref(:mass_cancel_response, required: true)
    field_ref(:mass_cancel_reject_reason, required: false)
    field_ref(:total_affected_orders, required: false)
    field_ref(:error_code, required: false)
    field_ref(:text, required: false)
  end

  message(:limit_query, category: :app, type: "XLQ") do
    field_ref(:req_id, required: true)
  end

  message(:limit_response, category: :app, type: "XLR") do
    field_ref(:req_id, required: true)

    group(:no_limit_indicators, required: true) do
      field_ref(:limit_type, required: true)
      field_ref(:limit_count, required: true)
      field_ref(:limit_max, required: true)
      field_ref(:limit_reset_interval, required: false)
      field_ref(:limit_reset_interval_resolution, required: false)
    end
  end

  message(:news, category: :app, type: "B") do
    field_ref(:headline, required: true)
  end
end
