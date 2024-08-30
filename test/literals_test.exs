defmodule LiteralsTest do
  use ExUnit.Case
  doctest Easm.Literals

  test "can create literals struct" do
    l = Easm.Literals.new()
    assert l.allocation_strategy == :eager
  end

  test "can create lazy allocation literals struct" do
    l = Easm.Literals.new(:lazy)
    assert l.allocation_strategy == :lazy
    assert l.map == %{}
  end

  test "can add literal" do
    ls = Easm.Literals.new()
    l = Easm.Literal.new({15, 0}, {1, 1})

    Easm.Literals.handle_literal(ls, [[type: 1]], {7, 1})
  end
end
