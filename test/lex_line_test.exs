defmodule LexLineTest do
  use ExUnit.Case
  doctest Easm.LexicalLine
  alias Easm.LexicalLine
  alias Easm.Lexer

  def comment_tokens_indented(), do: [{:white_space, " "}, {:asterisk, "*"}, {:symbol, "This"}]
  def comment_tokens(), do: [{:asterisk, "*"}, {:symbol, "That"}]
  def labeled_tokens(), do: [{:symbol, "START"}, {:white_space, " "}, {:symbol, "CLEAR"}]
  # def statement1_tokens(), do: [{:, ""}, {:, ""}, {:, ""}, {:, ""}]
  def statement1_tokens(),
    do: [{:white_space, " "}, {:symbol, "LDA"}, {:white_space, " "}, {:number, "300"}]

  def statement2_tokens(),
    do: [
      {:symbol, "LBL"},
      {:white_space, " "},
      {:symbol, "LDA"},
      {:white_space, " "},
      {:number, "300"}
    ]

  def statement3_tokens(),
    do: [
      {:operator, "$"},
      {:symbol, "LBL"},
      {:white_space, " "},
      {:symbol, "LDA"},
      {:white_space, " "},
      {:number, "300"}
    ]

  def statement4_tokens(),
    do: [
      {:white_space, " "},
      {:symbol, "LDA"},
      {:asterisk, "*"},
      {:white_space, " "},
      {:number, "300"}
    ]

  def statement5_tokens(),
    do: [
      {:symbol, "LBL2"},
      {:white_space, " "},
      {:symbol, "LDA"},
      {:asterisk, "*"},
      {:white_space, " "},
      {:number, "300"},
      {:white_space, " "},
      {:symbol, "This"}
    ]

  def ll(tokens) when is_list(tokens) do
    LexicalLine.new(%{:original => "dummy text", :tokens => tokens})
  end

  test "recognize comments" do
    assert Lexer.is_comment?(comment_tokens())
    assert Lexer.is_comment?(comment_tokens_indented())
    assert !Lexer.is_comment?(labeled_tokens())
  end

  test "identify whitespace" do
    answers = [[0, 2, 4], [1, 3, 5], [2, 4, 6], [0, 3, 5], [1, 4, 6]]

    funs = [
      &statement1_tokens/0,
      &statement2_tokens/0,
      &statement3_tokens/0,
      &statement4_tokens/0,
      &statement5_tokens/0
    ]

    Enum.zip(funs, answers)
    |> Enum.each(fn {f, ans} ->
      result = f.() |> Lexer.make_whitespace_token_list()
      assert result == ans
    end)
  end

  test "find parts" do
    answer = [{:number, "300"}]

    for fun <- [
          &statement1_tokens/0,
          &statement2_tokens/0,
          &statement3_tokens/0,
          &statement4_tokens/0,
          &statement5_tokens/0
        ] do
      line = Lexer.find_parts(ll(fun.()))
      assert line.address_tokens == answer
    end

    # Lexer.make_whitespace_token_list(statement5_tokens()) |> dbg()
  end
end
