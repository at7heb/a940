defmodule Easm.Lexer do
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

  def tokens(line, token_list) do
    cond do
      false != match_operator(line) ->
        {true, token, rest_of_line} = match_operator(line)
        tokens(rest_of_line, [token | token_list])

      false != match_symbol(line) ->
        {true, token, rest_of_line} = match_symbol(line)
        tokens(rest_of_line, [token | token_list])

      false != match_octal_number(line) ->
        {true, token, rest_of_line} = match_octal_number(line)
        tokens(rest_of_line, [token | token_list])

      false != match_number(line) ->
        {true, token, rest_of_line} = match_number(line)
        tokens(rest_of_line, [token | token_list])

      false != match_white_space(line) ->
        {true, token, rest_of_line} = match_white_space(line)
        tokens(rest_of_line, [token | token_list])

      false != match_asterisk(line) ->
        {true, token, rest_of_line} = match_asterisk(line)
        tokens(rest_of_line, [token | token_list])

      true ->
        tokens("", [{:unknown, line} | token_list])
    end
  end

  def match_white_space(line) when is_binary(line) do
    case Regex.run(~r{^( +)(.*)$}, line, capture: :all_but_first) do
      [token, rest] -> {true, {:white_space, token}, rest}
      _ -> false
    end
  end

  def match_operator(line) when is_binary(line) do
    case Regex.run(~r{^([-$+/,=:()><?!%.])(.*)$}, line, capture: :all_but_first) do
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
    case Regex.run(~r{^([0-7]+B[0-9]?)(.*)$}, line, capture: :all_but_first) do
      [token, rest] -> {true, {:octal_number, token}, rest}
      _ -> false
    end
  end

  def match_number(line) when is_binary(line) do
    case Regex.run(~r{^([0-9]+D?)(.*)$}, line, capture: :all_but_first) do
      [token, rest] -> {true, {:number, token}, rest}
      _ -> false
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
end
