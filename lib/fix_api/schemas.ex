defmodule FixApi.Schemas do
  defmodule Field do
    defstruct [:name, :type, :tag, allowed_values: nil]
  end

  defmodule FieldRef do
    defstruct [:name, field: Field.__struct__(), required: false]
  end

  defmodule Component do
    defstruct [:name, :children]
  end

  defmodule Group do
    defstruct [:name, :children, :field_list, required: false]
  end

  defmodule ComponentRef do
    defstruct [:name, component: Component.__struct__(), required: false]
  end

  defmodule Metadata do
    defstruct [:fields]
  end

  defmodule Data do
    defstruct fields: [], errors: [], valid?: false
  end

  defmodule Message do
    defstruct [:name, :type, :category, data: Data.__struct__(), metadata: Metadata.__struct__()]

    defimpl String.Chars, for: __MODULE__ do
      def to_string(%Message{
            name: name,
            type: type,
            category: category,
            data: data
          }) do
        "##{__MODULE__}<[#{type}] #{category}: #{name} - valid?: #{data.valid?}>"
      end
    end
  end
end
