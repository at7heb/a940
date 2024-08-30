defmodule Easm.Literal do
  @moduledoc """
  make a literal.
  states can be: :unknown, :defined, :known, :external
  value and relocation are the literal's value
  the used_at list is a list of {address, relocation} tuples which must be updated
  at the end of compilation
  """
  defstruct state: :defined, value: {0, 0}

  def new({value, relocation} = _value)
      when is_integer(value) and is_integer(relocation) do
    if value < 0 or value > 8_388_607 do
      raise "literal value out of range"
    end

    %Easm.Literal{state: :known, value: {value, relocation}}
  end

  def new(nil = _value) do
    %Easm.Literal{state: :defined, value: {nil, nil}}
  end

  def new(number: value) do
    if value < 0 or value > 8_388_607 do
      raise "literal value out of range"
    end

    %Easm.Literal{state: :known, value: {value, 0}}
  end

  def new(value) when is_integer(value) do
    if value < 0 or value > 8_388_607 do
      raise "literal value out of range"
    end

    %Easm.Literal{state: :known, value: {value, 0}}
  end

  def new(v) do
    {"erroneous call to Literal.new()", v} |> dbg
    %Easm.Literal{state: :unknown, value: nil}
  end
end

defmodule Easm.Literals do
  defstruct allocation_strategy: :eager, map: %{}, used_at: []

  def new(allocation_strategy \\ :eager) do
    l = %Easm.Literals{}
    %{l | allocation_strategy: allocation_strategy}
  end

  def handle_literal(
        %Easm.Literals{map: map, used_at: uses} = literals,
        literal_definition,
        %Easm.Literal{} = literal,
        {_address, _relocation} = memory_address
      )
      when is_list(literal_definition) do
    entry = Map.get(map, literal_definition, literal)

    if literal.state == entry.state and literal != entry do
      raise "literal not identical with literals' entry"
    end

    new_uses = [memory_address | uses]
    new_map = Map.put(map, literal_definition, literal)
    %{literals | map: new_map, used_at: new_uses}
  end
end
