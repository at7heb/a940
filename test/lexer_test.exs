defmodule LexerTest do
  use ExUnit.Case
  doctest Easm.Lexer
  alias Easm.Lexer

  test "recognize white space" do
    rv = Lexer.match_white_space("   CAX")
    assert {true, {:white_space, " "}, "CAX"} = rv
    assert false == Lexer.match_white_space("* A COMMENT")
  end

  test "recognize operator" do
    assert {true, {:operator, "/"}, "   CAX"} = Lexer.match_operator("/   CAX")
    assert false == Lexer.match_operator("* A COMMENT")
    assert false == Lexer.match_operator("12345")
  end

  test "recognize octal number" do
    assert {true, {:octal_number, "123B"}, "CAX"} = Lexer.match_octal_number("123BCAX")
    assert {true, {:octal_number, "144B9"}, "8CAX"} = Lexer.match_octal_number("144B98CAX")
  end

  test "recognize number" do
    assert {true, {:number, "987"}, "CAX"} = Lexer.match_number("987CAX")
    assert {true, {:number, "1289D"}, "+5"} = Lexer.match_number("1289D+5")
    assert false == Lexer.match_number("A123D")
  end

  test "recognize symbol" do
    assert {true, {:symbol, "ABC"}, " CAX"} = Lexer.match_symbol("ABC CAX")
    assert {true, {:symbol, "D9"}, " LDA =55"} = Lexer.match_symbol("D9 LDA =55")
    assert {true, {:symbol, "1BASIC"}, " IDENT"} = Lexer.match_symbol("1BASIC IDENT")
    assert {true, {:symbol, "1B88"}, ""} = Lexer.match_symbol("1B88")
    assert {true, {:symbol, "128B"}, ",2"} = Lexer.match_symbol("128B,2")
    assert {true, {:symbol, "1Z"}, ",2"} = Lexer.match_symbol("1Z,2")
    assert false == Lexer.match_symbol("127B")
    assert false == Lexer.match_symbol("127B,2")
    assert false == Lexer.match_symbol("129")
    assert false == Lexer.match_symbol("129D")
  end

  test "analyze" do
    # Lexer.analyze("1BASIC IDENT") |> dbg()
    # Lexer.analyze("1Z EQU *-*") |> dbg()
  end

  test "quoted string" do
    assert {true, {:quoted, "ABCD"}, ",2"} = Lexer.match_quoted("'ABCD',2")
    assert false == Lexer.match_quoted("NEW LDA =55")
  end
end
