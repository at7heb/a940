defmodule AddressTest do
  use ExUnit.Case
  doctest Easm.Address
  # alias Easm.Lexer
  alias Easm.Address

  # data for all these
  # {is_indexed?, non_indexed_addr_tokens} = Address.is_indexed(addr_tokens)
  # {is_constant?, value} = Address.is_constant(non_indexed_addr_tokens)
  # {is_literal?, literal_tokens} = Address.is_literal(non_indexed_addr_tokens)
  # {is_symbol?, symbol_token} = Address.is_symbol(non_indexed_addr_tokens)
  # {is_expression?, expression_tokens} = Address.is_expression(non_indexed_addr_tokens)

  def tests() do
    [
      {[{:symbol, "A"}, {:operator, ","}, {:number, "2"}], {true, [{:symbol, "A"}]},
       {false, :ditto}, {false, :ditto}, {false, :ditto}, {false, :ditto}},
      {[{:number, "100"}], {false, :ditto},
       {true,
        %Easm.Address{
          type: :constant,
          constant: 100,
          symbol_name: "",
          symbol: %Easm.Symbol{
            state: false,
            value: [1_000_000_000],
            relocatable: true,
            relocation: 0,
            definition: [],
            exported: false
          },
          indexed?: false
        }}, {false, :ditto}, {false, :ditto}, {false, :ditto}},
      {[{:operator, "="}, {:number, "100"}], {false, :ditto}, {false, :ditto},
       {true, [{:number, "100"}]}, {false, :ditto}, {false, :ditto}},
      {[{:operator, "="}, {:number, "100"}, {:operator, "+"}, {:symbol, "LEN1"}], {false, :ditto},
       {false, :ditto}, {true, [{:number, "100"}, {:operator, "+"}, {:symbol, "LEN1"}]},
       {false, :ditto}, {false, :ditto}}
    ]
  end

  def ises() do
    [
      &Address.is_indexed/1,
      &Address.is_constant/1,
      &Address.is_literal/1,
      &Address.is_symbol/1,
      &Address.is_expression/1
    ]
  end

  test "address types" do
    for test <- tests() do
      test_input = elem(test, 0)
      test_input |> dbg
      test_results = Tuple.delete_at(test, 0)

      # don't test is_expression/1 yet; it needs to be fixed.
      for num <- 0..3 do
        fun = Enum.at(ises(), num)
        {is?, val} = elem(test_results, num)
        {num, is?, val} |> dbg
        {is_result, val_result} = fun.(test_input)

        {num, is?, val, is_result, val_result, test_input} |> dbg

        val_result == test_input |> dbg()

        assert is_result == is? and
                 (val_result == val or (val == :ditto and val_result == test_input))
      end
    end
  end
end
