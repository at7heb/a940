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

  test "can find defined but not known" do
    l0 = Easm.Literal.new(nil)
    l1 = Easm.Literal.new({299, 3})
    l2 = Easm.Literal.new({1999, 0})
    l3 = Easm.Literal.new(nil)
    defn0 = [[number: 3], [operator: "*"], [label: "B"], [operator: "-"], [number: 1]]
    defn1 = [[label: "ZZ"]]
    defn2 = [[number: 21]]
    defn3 = [[label: "ZZ"]]
    ls = Easm.Literals.new()
    assert length(Easm.Literals.get_defined_literal_definitions(ls)) == 0
    a0 = {5, 1}
    a1 = {10, 1}
    a2 = {35, 1}
    a3 = {36, 1}

    ls1 =
      ls
      |> Easm.Literals.handle_literal(defn1, l1, a1)
      |> Easm.Literals.handle_literal(defn2, l2, a2)

    assert length(Easm.Literals.get_defined_literal_definitions(ls1)) == 0

    ls2 =
      ls1
      |> Easm.Literals.handle_literal(defn0, l0, a0)
      |> Easm.Literals.handle_literal(defn3, l3, a3)

    defns = Easm.Literals.get_defined_literal_definitions(ls2)
    defns |> dbg
    assert length(defns) == 2
    ls2 |> dbg
  end
end
