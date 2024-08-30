defmodule Easm.Literals do
  defstruct allocation_strategy: :eager, map: %{}

  def new(allocation_strategy \\ :eager) do
    l = %Easm.Literals{}
    %{l | allocation_strategy: allocation_strategy}
  end

  def handle_literal(
        %Easm.Literals{map: map} = l,
        literal_definition,
        {address, relocation} = _where
      ) do
  end
end

defmodule Easm.Literal do
  @moduledoc """
  make a literal.
  states can be: :unknown, :defined, :known, :external
  value and relocation are the literal's value
  the used_at list is a list of {address, relocation} tuples which must be updated
  at the end of compilation
  """
  defstruct state: :defined, value: 0, relocation: 0, used_at: []

  def new(
        {value, relocation} = _value,
        {_used_at_location, _used_at_relocation} = used_at_address
      )
      when is_integer(value) and is_integer(relocation) do
    value = rem(value, 8_388_607)
    %Easm.Literal{state: :known, value: value, relocation: relocation, used_at: [used_at_address]}
  end

  def new(nil = _value, {_used_at_location, _used_at_relocation} = used_at_address) do
    %Easm.Literal{state: :defined, value: nil, relocation: nil, used_at: [used_at_address]}
  end

  def new([number: value], {_used_at_location, _used_at_relocation} = used_at_address) do
    value = rem(value, 8_388_607)
    %Easm.Literal{state: :known, value: value, relocation: 0, used_at: [used_at_address]}
  end
end
