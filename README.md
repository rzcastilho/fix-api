# FixApi

## Schemas

### Field

#### DSL

```elixir
...
field :exec_type, tag: 150, type: :char do
  value "0", description: "NEW"
  value "4", description: "CANCELED"
  value "5", description: "REPLACED"
  ...
end

field :headline, tag: 148, type: :string
...
```

#### Data Structure

```elixir
%FixApi.Schemas.Field{
  name: :exec_type,
  type: :char,
  tag: 150,
  allowed_values: [
    {"0", "NEW"},
    {"4", "CANCELED"},
    {"5", "REPLACED"},
    {"8", "REJECTED"},
    {"F", "TRADE"},
    {"C", "EXPIRED"}
  ]
}

%FixApi.Schemas.Field{
  name: :headline,
  type: :string,
  tag: 148,
  allowed_values: nil
}
```

### Header

#### DSL

```elixir
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
```

#### Data Structure

```elixir
[
  begin_string: %{required: true, ref: :field},
  body_length: %{required: true, ref: :field},
  msg_type: %{required: true, ref: :field},
  sender_comp_id: %{required: true, ref: :field},
  target_comp_id: %{required: true, ref: :field},
  msg_seq_num: %{required: true, ref: :field},
  sending_time: %{required: true, ref: :field},
  recv_window: %{required: false, ref: :field}
]
```


### Trailer

#### DSL

```elixir
trailer do
  field_ref(:check_sum, required: true)
end
```

#### Data Structure

```elixir
[check_sum: %{required: true, ref: :field}]
```


### Components

#### DSL

```elixir
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
```

#### Data Strructure

```elixir
%FixApi.Schemas.Component{
  name: :triggering_instruction,
  children: [
    trigger_type: %{required: false, ref: :field},
    trigger_action: %{required: false, ref: :field},
    trigger_price: %{required: false, ref: :field},
    trigger_price_type: %{required: false, ref: :field},
    trigger_price_direction: %{required: false, ref: :field},
    trigger_trailing_delta_bips: %{required: false, ref: :field}
  ]
}

%FixApi.Schemas.Component{
  name: :list_triggering_instruction,
  children: [
    no_list_triggering_instructions: %FixApi.Schemas.Group{
      name: :no_list_triggering_instructions,
      children: [
        list_trigger_type: %{required: true, ref: :field},
        list_trigger_trigger_index: %{required: true, ref: :field},
        list_trigger_action: %{required: true, ref: :field}
      ],
      required: false
    }
  ]
}
```

### Messages

#### DSL

```elixir
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
```

#### Data Strructure

```elixir
%FixApi.Schemas.Message{
  name: :list_status,
  type: "N",
  category: :app,
  data: %FixApi.Schemas.Data{fields: [], errors: [], valid?: false},
  metadata: %FixApi.Schemas.Metadata{
    header: [
      begin_string: %{required: true, ref: :field},
      body_length: %{required: true, ref: :field},
      msg_type: %{required: true, ref: :field},
      sender_comp_id: %{required: true, ref: :field},
      target_comp_id: %{required: true, ref: :field},
      msg_seq_num: %{required: true, ref: :field},
      sending_time: %{required: true, ref: :field},
      recv_window: %{required: false, ref: :field}
    ],
    body: [
      symbol: %{required: true, ref: :field},
      list_id: %{required: false, ref: :field},
      cl_list_id: %{required: false, ref: :field},
      orig_cl_list_id: %{required: false, ref: :field},
      contingency_type: %{required: false, ref: :field},
      list_status_type: %{required: true, ref: :field},
      list_order_status: %{required: true, ref: :field},
      list_reject_reason: %{required: false, ref: :field},
      transact_time: %{required: false, ref: :field},
      no_orders: %FixApi.Schemas.Group{
        name: :no_orders,
        children: [
          cl_ord_id: %{required: true, ref: :field},
          symbol: %{required: true, ref: :field},
          order_id: %{required: false, ref: :field},
          list_triggering_instruction: %{required: false, ref: :component},
          ord_rej_reason: %{required: false, ref: :field},
          error_code: %{required: false, ref: :field},
          text: %{required: false, ref: :field}
        ],
        required: false
      }
    ],
    trailer: [check_sum: %{required: true, ref: :field}]
  }
}
```

## Message Examples

```
8=FIX.4.4|9=247|35=A|34=1|49=EXAMPLE|52=20240627-11:17:25.223|56=SPOT|95=88|96=4MHXelVVcpkdwuLbl6n73HQUXUf1dse2PCgT1DYqW9w8AVZ1RACFGM+5UdlGPrQHrgtS3CvsRURC1oj73j8gCA==|98=0|108=30|141=Y|553=sBRXrJx2DsOraMXOaUovEhgVRcjOvCtQwnWj8VxkOh1xqboS02SPGfKi2h8spZJb|25035=2|10=227|
8=FIX.4.4|9=113|35=A|34=1|49=SPOT|52=20240612-08:52:21.636837|56=5JQmUOsm|98=0|108=30|25037=4392a152-3481-4499-921a-6d42c50702e2|10=051|
8=FIX.4.4|9=248|35=A|34=1|49=5JQmUOsm|52=20240612-08:52:21.613|56=SPOT|95=88|96=KhJLbZqADWknfTAcp0ZjyNz36Kxa4ffvpNf9nTIc+K5l35h+vA1vzDRvLAEQckyl6VDOwJ53NOBnmmRYxQvQBQ==|98=0|108=30|141=Y|553=W5rcOD30c0gT4jHK8oX5d5NbzWoa0k4SFVoTHIFNJVZ3NuRpYb6ZyJznj8THyx5d|25035=1|10=000|
8=FIX.4.4|9=113|35=A|34=1|49=SPOT|52=20240612-08:52:21.636837|56=5JQmUOsm|98=0|108=30|25037=4392a152-3481-4499-921a-6d42c50702e2|10=051|
8=FIX.4.4|9=55|35=5|34=3|49=GhQHzrLR|52=20240611-09:44:25.543|56=SPOT|10=249|
8=FIX.4.4|9=84|35=5|34=4|49=SPOT|52=20240611-09:44:25.544001|56=GhQHzrLR|58=Logout acknowledgment.|10=212|
8=FIX.4.4|9=0000113|35=B|49=SPOT|56=OE|34=4|52=20240924-21:07:35.773537|148=Your connection is about to be closed. Please reconnect.|10=165|
8=FIX.4.4|9=114|35=D|34=2|49=qNXO12fH|52=20240611-09:01:46.228|56=SPOT|11=1718096506197867067|38=5|40=2|44=10|54=1|55=LTCBNB|59=4|10=016|
8=FIX.4.4|9=330|35=8|34=2|49=SPOT|52=20240611-09:01:46.228950|56=qNXO12fH|11=1718096506197867067|14=0.00000000|17=144|32=0.00000000|37=76|38=5.00000000|39=0|40=2|44=10.00000000|54=1|55=LTCBNB|59=4|60=20240611-09:01:46.228000|150=0|151=5.00000000|636=Y|1057=Y|25001=1|25017=0.00000000|25018=20240611-09:01:46.228000|25023=20240611-09:01:46.228000|10=095|
8=FIX.4.4|9=93|35=F|34=2|49=ieBwvCKy|52=20240613-01:11:13.784|56=SPOT|11=1718241073695674483|37=2|55=LTCBNB|10=210|
8=FIX.4.4|9=137|35=9|34=2|49=SPOT|52=20240613-01:12:41.320869|56=OlZb8ht8|11=1718241161272843932|37=2|55=LTCBNB|58=Unknown order sent.|434=1|25016=-1013|10=087|
8=FIX.4.4|9=160|35=XCN|34=2|49=JS8iiXK6|52=20240613-02:31:53.753|56=SPOT|11=1718245913721036458|37=8|38=5|40=2|44=4|54=1|55=LTCBNB|59=1|111=1|25033=1|25034=1718245913721036819|10=229|
8=FIX.4.4|9=94|35=q|34=2|49=dpYPesqv|52=20240613-01:24:36.948|56=SPOT|11=1718241876901971671|55=ABCDEF|530=1|10=110|
8=FIX.4.4|9=109|35=r|34=2|49=SPOT|52=20240613-01:24:36.949763|56=dpYPesqv|11=1718241876901971671|55=LTCBNB|530=1|531=1|533=5|10=083|
8=FIX.4.4|9=236|35=E|34=2|49=Eg13pOvN|52=20240607-02:19:07.836|56=SPOT|73=2|11=w1717726747805308656|55=LTCBNB|54=2|38=1|40=2|44=0.25|59=1|11=p1717726747805308656|55=LTCBNB|54=2|38=1|40=1|25010=1|25011=3|25012=0|25013=1|1385=2|25014=1717726747805308656|10=171|
8=FIX.4.4|9=290|35=N|34=2|49=SPOT|52=20240607-02:19:07.837191|56=Eg13pOvN|55=ABCDEF|60=20240607-02:19:07.836000|66=25|73=2|55=LTCBNB|37=52|11=w1717726747805308656|55=ABCDEF|37=53|11=p1717726747805308656|25010=1|25011=3|25012=0|25013=1|429=4|431=3|1385=2|25014=1717726747805308656|25015=1717726747805308656|10=019|
8=FIX.4.4|9=82|35=XLQ|34=2|49=7buKHZxZ|52=20240614-05:35:35.357|56=SPOT|6136=1718343335357229749|10=170|
8=FIX.4.4|9=225|35=XLR|34=2|49=SPOT|52=20240614-05:42:42.724057|56=uGnG0ef8|6136=1718343762723730315|25003=3|25004=2|25005=1|25006=1000|25007=10|25008=s|25004=1|25005=0|25006=200|25007=10|25008=s|25004=1|25005=0|25006=200000|25007=1|25008=d|10=241|
```

