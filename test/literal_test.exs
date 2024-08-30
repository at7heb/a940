defmodule LiteralTest do
  use ExUnit.Case
  doctest Easm.Literal

  test "can create literal struct" do
    l = Easm.Literal.new({15, 0}, {1, 1})
    assert l.state == :known
    assert length(l.used_at) == 1
    assert l.value == 15
    assert l.relocation == 0
    assert hd(l.used_at) == {1, 1}
  end
end
