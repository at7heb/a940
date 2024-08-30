defmodule LiteralsTest do
  use ExUnit.Case
  doctest Easm.Literals
  doctest Easm.Literal

  test "can create literal struct" do
    value0 = 15
    value1 = [number: 15]
    expected = {15, 0}
    l = Easm.Literal.new(value0)
    assert l.state == :known
    assert l.value == expected
    l = Easm.Literal.new(value1)
    assert l.value == expected
  end

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
    value = {99, 0}
    memory_address = {30, 1}
    defn = [label: "B"]

    ls = Easm.Literals.new()
    l = Easm.Literal.new(value)

    ls1 = Easm.Literals.handle_literal(ls, defn, l, memory_address)
    assert ls1.used_at == [memory_address]
    assert Map.keys(ls1.map) == [defn]
    assert Map.get(ls1.map, defn) == l
    assert Map.get(ls1.map, defn).value == value
  end

  test "can add same literal..." do
    "add same" |> dbg
    l0 = Easm.Literal.new(15)
    ls = Easm.Literals.new()
    a0 = {5, 1}
    a1 = {10, 1}

    ls =
      Easm.Literals.handle_literal(ls, [number: "15"], l0, a0)
      |> Easm.Literals.handle_literal([number: "15"], l0, a1)

    assert length(ls.used_at) == 2
    assert a0 in ls.used_at
    assert a1 in ls.used_at
    assert length(Map.to_list(ls.map)) == 1
  end

  test "can add same literal defined later..." do
    l0 = Easm.Literal.new(nil)
    l1 = Easm.Literal.new({299, 3})
    defn = [[number: 3], [operator: "*"], [label: "B"], [operator: "-"], [number: 1]]
    ls = Easm.Literals.new()
    a0 = {5, 1}
    a1 = {10, 1}

    ls1 =
      Easm.Literals.handle_literal(ls, defn, l0, a0)
      |> Easm.Literals.handle_literal(defn, l1, a1)

    assert length(ls1.used_at) == 2
    assert a0 in ls1.used_at
    assert a1 in ls1.used_at
    assert length(Map.to_list(ls1.map)) == 1
  end
end
