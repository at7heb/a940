defmodule Easm.Lexer do
  alias Easm.LexicalLine
  alias Easm.ADotOut
  import Bitwise

  def analyze(lines) when is_list(lines) do
    Enum.map(lines, &analyze(&1))
    |> Enum.reduce({[], 1}, fn linemap, {lines, linecount} ->
      l = Map.put(linemap, :linenumber, linecount)
      {[l | lines], linecount + 1}
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  def analyze(line) when is_binary(line) do
    %{original: line, tokens: tokens(line)}
  end

  def tokens(line) when is_binary(line) do
    tokens(line, [])
  end

  def tokens("", token_list), do: Enum.reverse(token_list)

  def tokens(line, [{:asterisk, "*"}] = tokens), do: [hd(tokens) | [{:comment, line}]]

  def tokens(line, token_list) do
    white_space_count =
      Enum.filter(token_list, fn {type, _string} = _ -> type == :white_space end) |> length()

    if white_space_count >= 3 do
      [{:comment, line} | token_list] |> Enum.reverse()
    else
      tokens_no_short_circuit(line, token_list)
    end
  end

  def tokens_no_short_circuit(line, token_list) do
    cond do
      false != match_number(line) ->
        {true, token, rest_of_line} = match_number(line)
        tokens(rest_of_line, [token | token_list])

      false != match_operator(line) ->
        {true, token, rest_of_line} = match_operator(line)
        tokens(rest_of_line, [token | token_list])

      false != match_symbol(line) ->
        {true, token, rest_of_line} = match_symbol(line)
        tokens(rest_of_line, [token | token_list])

      false != match_octal_number(line) ->
        {true, token, rest_of_line} = match_octal_number(line)
        tokens(rest_of_line, [token | token_list])

      false != match_white_space(line) ->
        {true, token, rest_of_line} = match_white_space(line)
        tokens(rest_of_line, [token | token_list])

      false != match_asterisk(line) ->
        {true, token, rest_of_line} = match_asterisk(line)
        tokens(rest_of_line, [token | token_list])

      false != match_quoted(line) ->
        {true, token, rest_of_line} = match_quoted(line)
        tokens(rest_of_line, [token | token_list])

      true ->
        tokens("", [{:unknown, line} | token_list])
    end
  end

  def match_white_space(line) when is_binary(line) do
    case Regex.run(~r{^( +)(.*)$}, line, capture: :all_but_first) do
      [_token, rest] -> {true, {:white_space, " "}, rest}
      _ -> false
    end
  end

  def match_operator(line) when is_binary(line) do
    case Regex.run(~r{^([-$+/,=:;&@()\[\]><?!%.])(.*)$}, line, capture: :all_but_first) do
      [token, rest] -> {true, {:operator, token}, rest}
      _ -> false
    end
  end

  def match_asterisk(line) when is_binary(line) do
    case Regex.run(~r{^(\*)(.*)$}, line, capture: :all_but_first) do
      [token, rest] -> {true, {:asterisk, token}, rest}
      _ -> false
    end
  end

  def match_octal_number(line) when is_binary(line) do
    case Regex.run(~r{^(-?[0-7]+B[0-9]?)(.*)$}, line, capture: :all_but_first) do
      [token, rest] -> {true, {:octal_number, token}, rest}
      _ -> false
    end
  end

  def match_number(line) when is_binary(line) do
    case Regex.run(~r{^(-?[0-9]+D?)(.*)$}, line, capture: :all_but_first) do
      [token, rest] -> {true, {:number, token}, rest}
      _ -> false
    end
  end

  def match_quoted(line) when is_binary(line) do
    fields0 = Regex.run(~r{^'([^']+)'(.*)$}, line, capture: :all_but_first)
    fields1 = Regex.run(~r{^"([^"]+)"(.*)$}, line, capture: :all_but_first)

    cond do
      is_list(fields0) ->
        [token, rest] = fields0
        {true, {:quoted, token}, rest}

      is_list(fields1) ->
        [token, rest] = fields1
        {true, {:quoted, token}, rest}

      true ->
        false
    end
  end

  def match_symbol(line) when is_binary(line) do
    case Regex.run(~r{^([A-Z][A-Z0-9]*)(.*)$}, line, capture: :all_but_first) do
      [token, rest] -> {true, {:symbol, token}, rest}
      _ -> match_symbol_starting_like_a_number0(line)
    end
  end

  def match_symbol_starting_like_a_number0(line) when is_binary(line) do
    case Regex.run(~r{^([0-7]*[89][0-9]*B[A-Z0-9]*)(.*)$}, line, capture: :all_but_first) do
      [token, rest] -> {true, {:symbol, token}, rest}
      _ -> match_symbol_starting_like_a_number1(line)
    end
  end

  def match_symbol_starting_like_a_number1(line) when is_binary(line) do
    case Regex.run(~r{^([0-9]+D[A-Z0-9]+)(.*)$}, line, capture: :all_but_first) do
      [token, rest] -> {true, {:symbol, token}, rest}
      _ -> match_symbol_starting_like_a_number2(line)
    end
  end

  def match_symbol_starting_like_a_number2(line) when is_binary(line) do
    case Regex.run(~r{^([0-9]+[BD][A-Z0-9]+)(.*)$}, line, capture: :all_but_first) do
      [token, rest] -> {true, {:symbol, token}, rest}
      _ -> match_symbol_starting_like_a_number3(line)
    end
  end

  def match_symbol_starting_like_a_number3(line) when is_binary(line) do
    case Regex.run(~r{^([0-9]+[ACE-Z][A-Z0-9]*)(.*)$}, line, capture: :all_but_first) do
      [token, rest] -> {true, {:symbol, token}, rest}
      _ -> false
    end
  end

  def find_parts(%LexicalLine{tokens: tokens} = lexical_line) do
    cond do
      is_comment?(tokens) ->
        no_tokens(lexical_line)

      true ->
        identify_part_tokens(
          lexical_line,
          make_whitespace_token_list(tokens)
        )
    end
  end

  # add the label, operation, and address parts' tokens to the lexical line.
  def identify_part_tokens(%LexicalLine{tokens: tokens} = lexical_line, ws_token_list)
      when is_list(ws_token_list) do
    [ws0 | [ws1 | [ws2 | _rest]]] = ws_token_list
    label_tokens = Enum.slice(tokens, 0, ws0)
    op_tokens = Enum.slice(tokens, ws0 + 1, ws1 - ws0 - 1)
    address_tokens = Enum.slice(tokens, ws1 + 1, ws2 - ws1 - 1)

    %{
      lexical_line
      | label_tokens: label_tokens,
        operation_tokens: op_tokens,
        address_tokens: address_tokens
    }
  end

  # def identify_part_tokens(%LexicalLine{tokens: tokens} = lexical_line, [first | rest]) do
  #   identify_part_tokens_rest(%{lexical_line | label_tokens: Enum.slice(tokens, 0,)})
  # end

  def number_value(text_value) when is_binary(text_value) do
    # decimal value or octal:  123B or 4B7, for example
    size = String.length(text_value)

    value =
      cond do
        String.match?(text_value, ~r/B$/) ->
          String.to_integer(String.slice(text_value, 0, size - 1), 8)

        String.match?(text_value, ~r/B[0-7]$/) ->
          String.to_integer(String.slice(text_value, 0, size - 2), 8) <<<
            (3 * String.to_integer(String.slice(text_value, size - 1, 1)))

        true ->
          String.to_integer(text_value)
      end

    value
  end

  def token_type({type, _}), do: type

  def token_value({_, value}), do: value

  def is_comment?(tokens) when is_list(tokens) do
    tokens |> dbg
    number_of_tokens = length(tokens)

    cond do
      0 == number_of_tokens ->
        true

      1 <= number_of_tokens and token_type(hd(tokens)) == :asterisk ->
        true

      2 <= number_of_tokens and token_type(hd(tokens)) == :white_space and
          token_type(hd(tl(tokens))) == :asterisk ->
        true

      true ->
        false
    end
  end

  def make_whitespace_token_list(tokens) when is_list(tokens) do
    tokens = tokens ++ [{:white_space, " "}, {:white_space, " "}, {:white_space, " "}]
    range = 0..(length(tokens) - 1)

    Enum.zip(range, tokens)
    |> Enum.reduce([], fn {index, {token_type, _}}, acc ->
      if token_type == :white_space, do: [index | acc], else: acc
    end)
    |> Enum.reverse()
    |> Enum.take(3)
  end

  def no_tokens(%LexicalLine{} = lexical_line) do
    %{lexical_line | label_tokens: [], operation_tokens: [], address_tokens: []}
  end

  def clean_for_new_statement(%ADotOut{} = aout) do
    aout
  end
end
