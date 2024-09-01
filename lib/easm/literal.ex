defmodule Easm.Literal do
  @moduledoc """
  make a literal.
  states can be: :unknown, :defined, :known, :external
  value and relocation are the literal's value
  the used_at list is a list of {address, relocation} tuples which must be updated
  at the end of compilation
  """
  defstruct state: :defined, value: {0, 0}, used_at: []

  def new({value, relocation} = _value, {vu, ru} = used_at)
      when is_integer(value) and is_integer(relocation) and is_integer(vu) and is_integer(ru) do
    if value < 0 or value > 8_388_607 do
      raise "literal value out of range"
    end

    %Easm.Literal{state: :known, value: {value, relocation}, used_at: [used_at]}
  end

  def new(nil = _value, {vu, ru} = used_at) when is_integer(vu) and is_integer(ru) do
    %Easm.Literal{state: :defined, value: {nil, nil}, used_at: [used_at]}
  end

  def new(number: value) when is_integer(vu) and is_integer(ru) do
    if value < 0 or value > 8_388_607 do
      raise "literal value out of range"
    end

    %Easm.Literal{state: :known, value: {value, 0}, used_at: [used_at]}
  end

  def new(value) when is_integer(value) when is_integer(vu) and is_integer(ru) do
    if value < 0 or value > 8_388_607 do
      raise "literal value out of range"
    end

    %Easm.Literal{state: :known, value: {value, 0}, used_at: [used_at]}
  end

  def new(v) when is_integer(vu) and is_integer(ru) do
    {"erroneous call to Literal.new()", v} |> dbg
    %Easm.Literal{state: :unknown, value: nil, used_at: [used_at]}
  end
end
