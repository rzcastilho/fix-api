# FixApi

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `fix_api` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:fix_api, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/fix_api>.

## Schemas

### Fields

#### DSL

```elixir
...
field :exec_type, number: 150, type: :char do
  value "0", description: "NEW"
  value "4", description: "CANCELED"
  value "5", description: "REPLACED"
  ...
end

field :head_line, 148, :string
...
```

#### Data Structure

```elixir
%{
  exec_type: %{
    number: 150,
    type: :char,
    allowed_values: [
      {"0", "NEW"},
      {"4", "CANCELED"},
      {"5", "REPLACED"}
    ]
  },
  head_line: %{
    number: 148,
    type: :string
  }
}
```


### Components

#### DSL

```elixir
component :triggering_instruction do
  group :no_list_triggering_instructions, required: false do
    field :list_trigger_type, required: true
    field :list_trigger_trigger_index, required: true
    field :list_trigger_action, required: true
  end
end

component :new_order do
  field :cl_ord_id, required: true
  field :order_qty, required: false
  field :ord_type,  required: true
  field :exec_inst, required: false
  field :price, required: false
  component :triggering_instruction, required: false
end
```

#### Data Strructure

```elixir
%{
  triggering_instruction: [
    group: [
      name: :no_list_triggering_instructions,
      required: false,
      children: [
        field: [
          name: :list_trigger_type,
          required: true
        ],
        field: [
          name: :list_trigger_trigger_index,
          required: true
        ],
        field: [
          name: :list_trigger_action,
          required: true
        ]
      ]
    ]
  ]
}
```
