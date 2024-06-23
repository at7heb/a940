defmodule LexLineTest do
  use ExUnit.Case
  doctest Easm.LexicalLine
  alias Easm.LexicalLine
  alias Easm.Lexer

  def comment_tokens_indented(), do: [{:white_space, " "}, {:asterisk, "*"}, {:symbol, "This"}]
  def comment_tokens(), do: [{:asterisk, "*"}, {:symbol, "That"}]
  def labeled_tokens(), do: [{:symbol, "START"}, {:white_space, " "}, {:symbol, "CLEAR"}]
  # def statement1_tokens(), do: [{:, ""}, {:, ""}, {:, ""}, {:, ""}]
  def statement1_tokens(), do: [{white_space:, " "}, {symbol:, "LDA"}, {:white_space, " "}, {:number, "300"}]

  def ll(tokens) when is_list(tokens) do
    LexicalLine.new(%{:original => "dummy text", :tokens => tokens})
  end

  test "recognize white space" do
    assert Lexer.is_comment?(ll(comment_tokens()))
    assert Lexer.is_comment?(ll(comment_tokens_indented()))
    assert !Lexer.is_comment?(ll(labeled_tokens()))
  end

  test "find parts" do
    ll = Lexer.find_parts(ll(statement1_tokens))
  end
end
