defmodule ResolverTest do
  use ExUnit.Case
  doctest Easm.Resolver
  alias Easm.Resolver
  alias Easm.Expression
  # alias Easm.Symbol
  # alias Easm.Symbol
  # alias Easm.Address
  # alias Easm.Memory
  # alias Easm.ADotOut

  test "can count # of resolved symbols" do
    # symbols = make_test_symbols() |> dbg
    # addresses = make_test_addresses(symbols) |> dbg
    # memory = make_test_memory(addresses)
    aout = make_test_aout()
    # addresses are in the memory list
    memory = aout.memory

    memory_with_known_addresses =
      Enum.filter(memory, fn location ->
        location.address_field_type == :mem_addr and location.symbol_name == ""
      end)

    assert length(memory_with_known_addresses) == 13
  end

  test "count # of known symbols" do
    aout = make_test_aout()
    symbols = aout.symbols
    symbol_list = Map.to_list(symbols)

    known_symbols =
      symbol_list |> Enum.filter(fn {_name, defn} -> defn.state == :known end)

    count = length(known_symbols)
    assert count == 2
  end

  test "can find address to resolve" do
    aout = make_test_aout()
    in_need_of_resolution = Resolver.addresses_needing_resolution(aout)
    assert length(in_need_of_resolution) == 2
  end

  test "can resolve an address" do
    aout = make_test_aout()
    in_need_of_resolution = Resolver.addresses_needing_resolution(aout)
    symbols = aout.symbols

    new_expressions =
      Enum.map(in_need_of_resolution, fn {_name, symbol} = _sym ->
        Expression.try_evaluating_expression(symbol.definition, symbols) |> dbg
      end)
      |> Enum.filter(fn expression -> expression != nil end)

    new_expressions |> dbg
  end

  test "can resolve an expression" do
  end

  test "can detect when unresolvable address exists" do
  end

  test "can detect when unresolvable expression exists" do
  end

  def make_test_symbols() do
    _symbols = %{
      "A" => %Easm.Symbol{
        state: :known,
        value: 4,
        relocatable: true,
        relocation: 1,
        definition: [],
        exported: true
      },
      "B" => %Easm.Symbol{
        state: :known,
        value: 17,
        relocatable: true,
        relocation: 1,
        definition: [],
        exported: false
      },
      "E_19026803-b2a1-1016-8471-1299fae6ff71" => %Easm.Symbol{
        state: :unknown,
        value: nil,
        relocatable: false,
        relocation: 0,
        definition: [symbol: "A", operator: "+", number: "5"],
        exported: false
      },
      "E_19027018-b2a1-1016-8472-1299fae6ff71" => %Easm.Symbol{
        state: :unknown,
        value: nil,
        relocatable: false,
        relocation: 0,
        definition: [symbol: "B"],
        exported: false
      }
    }
  end

  def make_test_addresses(symbols_map) when is_map(symbols_map) do
  end

  def make_test_memory(addresses_map) when is_map(addresses_map) do
    _test_memory = [
      %Easm.Memory{
        address_relocation: 1,
        location: 17,
        instruction_relocatable?: true,
        content: 2_064_393,
        address_field_type: :mem_addr,
        symbol_name: "",
        end_action: nil
      },
      %Easm.Memory{
        address_relocation: 0,
        location: 16,
        instruction_relocatable?: true,
        content: 6_258_687,
        address_field_type: :mem_addr,
        symbol_name: "",
        end_action: nil
      },
      %Easm.Memory{
        address_relocation: 0,
        location: 15,
        instruction_relocatable?: true,
        content: 6_242_303,
        address_field_type: :mem_addr,
        symbol_name: "",
        end_action: nil
      },
      %Easm.Memory{
        address_relocation: 0,
        location: 14,
        instruction_relocatable?: true,
        content: 2_047_999,
        address_field_type: :mem_addr,
        symbol_name: "",
        end_action: nil
      },
      %Easm.Memory{
        address_relocation: 0,
        location: 13,
        instruction_relocatable?: true,
        content: 1_245_196,
        address_field_type: :no_addr,
        symbol_name: %Easm.Symbol{
          state: false,
          value: [1_000_000_000],
          relocatable: true,
          relocation: 0,
          definition: [],
          exported: false
        },
        end_action: nil
      },
      %Easm.Memory{
        address_relocation: 0,
        location: 12,
        instruction_relocatable?: true,
        content: 1_245_568,
        address_field_type: :no_addr,
        symbol_name: %Easm.Symbol{
          state: false,
          value: [1_000_000_000],
          relocatable: true,
          relocation: 0,
          definition: [],
          exported: false
        },
        end_action: nil
      },
      %Easm.Memory{
        address_relocation: 0,
        location: 11,
        instruction_relocatable?: true,
        content: 1_245_188,
        address_field_type: :no_addr,
        symbol_name: %Easm.Symbol{
          state: false,
          value: [1_000_000_000],
          relocatable: true,
          relocation: 0,
          definition: [],
          exported: false
        },
        end_action: nil
      },
      %Easm.Memory{
        address_relocation: 0,
        location: 10,
        instruction_relocatable?: true,
        content: 967_266,
        address_field_type: :mem_addr,
        symbol_name: "",
        end_action: nil
      },
      %Easm.Memory{
        address_relocation: 0,
        location: 9,
        instruction_relocatable?: true,
        content: 950_872,
        address_field_type: :mem_addr,
        symbol_name: "",
        end_action: nil
      },
      %Easm.Memory{
        address_relocation: 0,
        location: 8,
        instruction_relocatable?: true,
        content: 2_032_116,
        address_field_type: :mem_addr,
        symbol_name: "",
        end_action: nil
      },
      %Easm.Memory{
        address_relocation: 0,
        location: 7,
        instruction_relocatable?: true,
        content: 32868,
        address_field_type: :mem_addr,
        symbol_name: "",
        end_action: nil
      },
      %Easm.Memory{
        address_relocation: 1,
        location: 6,
        instruction_relocatable?: true,
        content: 2_031_620,
        address_field_type: :mem_addr,
        symbol_name: "",
        end_action: nil
      },
      %Easm.Memory{
        address_relocation: 0,
        location: 5,
        instruction_relocatable?: true,
        content: 2_031_616,
        address_field_type: :mem_addr,
        symbol_name: "E_19027018-b2a1-1016-8472-1299fae6ff71",
        end_action: nil
      },
      %Easm.Memory{
        address_relocation: 0,
        location: 4,
        instruction_relocatable?: true,
        content: 524_288,
        address_field_type: :mem_addr,
        symbol_name: "",
        end_action: nil
      },
      %Easm.Memory{
        address_relocation: 0,
        location: 3,
        instruction_relocatable?: true,
        content: 32868,
        address_field_type: :mem_addr,
        symbol_name: "",
        end_action: nil
      },
      %Easm.Memory{
        address_relocation: 0,
        location: 2,
        instruction_relocatable?: true,
        content: 2_064_384,
        address_field_type: :mem_addr,
        symbol_name: "E_19026803-b2a1-1016-8471-1299fae6ff71",
        end_action: nil
      },
      %Easm.Memory{
        address_relocation: 1,
        location: 1,
        instruction_relocatable?: true,
        content: 32774,
        address_field_type: :mem_addr,
        symbol_name: "",
        end_action: nil
      },
      %Easm.Memory{
        address_relocation: 1,
        location: 0,
        instruction_relocatable?: true,
        content: 49147,
        address_field_type: :mem_addr,
        symbol_name: "",
        end_action: nil
      }
    ]
  end

  # def make_test_aout(_addresses, _memory), do: %ADotOut{}

  def make_test_aout() do
    %Easm.ADotOut{
      memory: [
        %Easm.Memory{
          address_relocation: 1,
          location: 17,
          instruction_relocatable?: true,
          content: 2_064_393,
          address_field_type: :mem_addr,
          symbol_name: "",
          end_action: nil
        },
        %Easm.Memory{
          address_relocation: 0,
          location: 16,
          instruction_relocatable?: true,
          content: 6_258_687,
          address_field_type: :mem_addr,
          symbol_name: "",
          end_action: nil
        },
        %Easm.Memory{
          address_relocation: 0,
          location: 15,
          instruction_relocatable?: true,
          content: 6_242_303,
          address_field_type: :mem_addr,
          symbol_name: "",
          end_action: nil
        },
        %Easm.Memory{
          address_relocation: 0,
          location: 14,
          instruction_relocatable?: true,
          content: 2_047_999,
          address_field_type: :mem_addr,
          symbol_name: "",
          end_action: nil
        },
        %Easm.Memory{
          address_relocation: 0,
          location: 13,
          instruction_relocatable?: true,
          content: 1_245_196,
          address_field_type: :no_addr,
          symbol_name: "",
          end_action: nil
        },
        %Easm.Memory{
          address_relocation: 0,
          location: 12,
          instruction_relocatable?: true,
          content: 1_245_568,
          address_field_type: :no_addr,
          symbol_name: "",
          end_action: nil
        },
        %Easm.Memory{
          address_relocation: 0,
          location: 11,
          instruction_relocatable?: true,
          content: 1_245_188,
          address_field_type: :no_addr,
          symbol_name: "",
          end_action: nil
        },
        %Easm.Memory{
          address_relocation: 0,
          location: 10,
          instruction_relocatable?: true,
          content: 967_266,
          address_field_type: :mem_addr,
          symbol_name: "",
          end_action: nil
        },
        %Easm.Memory{
          address_relocation: 0,
          location: 9,
          instruction_relocatable?: true,
          content: 950_872,
          address_field_type: :mem_addr,
          symbol_name: "",
          end_action: nil
        },
        %Easm.Memory{
          address_relocation: 0,
          location: 8,
          instruction_relocatable?: true,
          content: 2_032_116,
          address_field_type: :mem_addr,
          symbol_name: "",
          end_action: nil
        },
        %Easm.Memory{
          address_relocation: 0,
          location: 7,
          instruction_relocatable?: true,
          content: 32868,
          address_field_type: :mem_addr,
          symbol_name: "",
          end_action: nil
        },
        %Easm.Memory{
          address_relocation: 1,
          location: 6,
          instruction_relocatable?: true,
          content: 2_031_620,
          address_field_type: :mem_addr,
          symbol_name: "",
          end_action: nil
        },
        %Easm.Memory{
          address_relocation: 0,
          location: 5,
          instruction_relocatable?: true,
          content: 2_031_616,
          address_field_type: :mem_addr,
          symbol_name: "E_925a7865-b2d1-1016-9c98-1299fae6ff71",
          end_action: nil
        },
        %Easm.Memory{
          address_relocation: 0,
          location: 4,
          instruction_relocatable?: true,
          content: 524_288,
          address_field_type: :mem_addr,
          symbol_name: "",
          end_action: nil
        },
        %Easm.Memory{
          address_relocation: 0,
          location: 3,
          instruction_relocatable?: true,
          content: 32868,
          address_field_type: :mem_addr,
          symbol_name: "",
          end_action: nil
        },
        %Easm.Memory{
          address_relocation: 0,
          location: 2,
          instruction_relocatable?: true,
          content: 2_064_384,
          address_field_type: :mem_addr,
          symbol_name: "E_925a62ab-b2d1-1016-9c97-1299fae6ff71",
          end_action: nil
        },
        %Easm.Memory{
          address_relocation: 1,
          location: 1,
          instruction_relocatable?: true,
          content: 32774,
          address_field_type: :mem_addr,
          symbol_name: "",
          end_action: nil
        },
        %Easm.Memory{
          address_relocation: 1,
          location: 0,
          instruction_relocatable?: true,
          content: 49147,
          address_field_type: :mem_addr,
          symbol_name: "",
          end_action: nil
        }
      ],
      symbols: %{
        "A" => %Easm.Symbol{
          state: :known,
          value: 4,
          relocatable: true,
          relocation: 1,
          definition: [],
          exported: true
        },
        "B" => %Easm.Symbol{
          state: :known,
          value: 17,
          relocatable: true,
          relocation: 1,
          definition: [],
          exported: false
        },
        "E_925a62ab-b2d1-1016-9c97-1299fae6ff71" => %Easm.Symbol{
          state: :unknown,
          value: nil,
          relocatable: false,
          relocation: 0,
          # definition: [symbol: "A", operator: "+", number: "5"],
          definition: [symbol: "C", operator: "+", number: "5"],
          exported: false
        },
        "E_925a7865-b2d1-1016-9c98-1299fae6ff71" => %Easm.Symbol{
          state: :unknown,
          value: nil,
          relocatable: false,
          relocation: 0,
          definition: [symbol: "B"],
          exported: false
        }
      },
      lines: %{
        1 => %Easm.LexicalLine{
          tokens: [
            white_space: " ",
            symbol: "BRU",
            white_space: " ",
            asterisk: "*",
            operator: "-",
            number: "5"
          ],
          original: " BRU *-5",
          label_tokens: [],
          operation_tokens: [symbol: "BRU"],
          address_tokens: [asterisk: "*", operator: "-", number: "5"],
          is_op: true,
          is_pseudo: true
        },
        2 => %Easm.LexicalLine{
          tokens: [
            white_space: " ",
            symbol: "BRU",
            white_space: " ",
            asterisk: "*",
            operator: "+",
            number: "5"
          ],
          original: " BRU *+5",
          label_tokens: [],
          operation_tokens: [symbol: "BRU"],
          address_tokens: [asterisk: "*", operator: "+", number: "5"],
          is_op: true,
          is_pseudo: true
        },
        3 => %Easm.LexicalLine{
          tokens: [
            white_space: " ",
            symbol: "EAX",
            white_space: " ",
            symbol: "A",
            operator: "+",
            number: "5"
          ],
          original: " EAX A+5",
          label_tokens: [],
          operation_tokens: [symbol: "EAX"],
          address_tokens: [symbol: "A", operator: "+", number: "5"],
          is_op: true,
          is_pseudo: true
        },
        4 => %Easm.LexicalLine{
          tokens: [white_space: " ", symbol: "BRU", white_space: " ", number: "100"],
          original: " BRU 100",
          label_tokens: [],
          operation_tokens: [symbol: "BRU"],
          address_tokens: [number: "100"],
          is_op: true,
          is_pseudo: true
        },
        5 => %Easm.LexicalLine{
          tokens: [operator: "$", symbol: "A", white_space: " ", symbol: "NOP"],
          original: "$A NOP",
          label_tokens: [operator: "$", symbol: "A"],
          operation_tokens: [symbol: "NOP"],
          address_tokens: [],
          is_op: true,
          is_pseudo: true
        },
        6 => %Easm.LexicalLine{
          tokens: [white_space: " ", symbol: "LDA", white_space: " ", symbol: "B"],
          original: " LDA B",
          label_tokens: [],
          operation_tokens: [symbol: "LDA"],
          address_tokens: [symbol: "B"],
          is_op: true,
          is_pseudo: true
        },
        7 => %Easm.LexicalLine{
          tokens: [white_space: " ", symbol: "LDA", white_space: " ", symbol: "A"],
          original: " LDA A",
          label_tokens: [],
          operation_tokens: [symbol: "LDA"],
          address_tokens: [symbol: "A"],
          is_op: true,
          is_pseudo: true
        },
        8 => %Easm.LexicalLine{
          tokens: [white_space: " ", symbol: "BRU", white_space: " ", number: "100"],
          original: "  BRU 100",
          label_tokens: [],
          operation_tokens: [symbol: "BRU"],
          address_tokens: [number: "100"],
          is_op: true,
          is_pseudo: true
        },
        9 => %Easm.LexicalLine{
          tokens: [white_space: " ", symbol: "LDA", white_space: " ", number: "500"],
          original: " LDA 500",
          label_tokens: [],
          operation_tokens: [symbol: "LDA"],
          address_tokens: [number: "500"],
          is_op: true,
          is_pseudo: true
        },
        10 => %Easm.LexicalLine{
          tokens: [white_space: " ", symbol: "STA", white_space: " ", number: "600"],
          original: " STA 600",
          label_tokens: [],
          operation_tokens: [symbol: "STA"],
          address_tokens: [number: "600"],
          is_op: true,
          is_pseudo: true
        },
        11 => %Easm.LexicalLine{
          tokens: [
            white_space: " ",
            symbol: "STA",
            asterisk: "*",
            white_space: " ",
            number: "610"
          ],
          original: " STA* 610",
          label_tokens: [],
          operation_tokens: [symbol: "STA", asterisk: "*"],
          address_tokens: [number: "610"],
          is_op: true,
          is_pseudo: true
        },
        12 => %Easm.LexicalLine{
          tokens: [white_space: " ", symbol: "CAB"],
          original: " CAB",
          label_tokens: [],
          operation_tokens: [symbol: "CAB"],
          address_tokens: [],
          is_op: true,
          is_pseudo: true
        },
        13 => %Easm.LexicalLine{
          tokens: [white_space: " ", symbol: "XXA"],
          original: " XXA",
          label_tokens: [],
          operation_tokens: [symbol: "XXA"],
          address_tokens: [],
          is_op: true,
          is_pseudo: true
        },
        14 => %Easm.LexicalLine{
          tokens: [white_space: " ", symbol: "XAB"],
          original: " XAB",
          label_tokens: [],
          operation_tokens: [symbol: "XAB"],
          address_tokens: [],
          is_op: true,
          is_pseudo: true
        },
        15 => %Easm.LexicalLine{
          tokens: [
            white_space: " ",
            symbol: "LDA",
            white_space: " ",
            operator: "-",
            number: "1"
          ],
          original: " LDA -1",
          label_tokens: [],
          operation_tokens: [symbol: "LDA"],
          address_tokens: [operator: "-", number: "1"],
          is_op: true,
          is_pseudo: true
        },
        16 => %Easm.LexicalLine{
          tokens: [
            white_space: " ",
            symbol: "LDA",
            white_space: " ",
            operator: "-",
            number: "1",
            operator: ",",
            number: "2"
          ],
          original: " LDA -1,2",
          label_tokens: [],
          operation_tokens: [symbol: "LDA"],
          address_tokens: [operator: "-", number: "1", operator: ",", number: "2"],
          is_op: true,
          is_pseudo: true
        },
        17 => %Easm.LexicalLine{
          tokens: [
            white_space: " ",
            symbol: "LDA",
            asterisk: "*",
            white_space: " ",
            operator: "-",
            number: "1",
            operator: ",",
            number: "2"
          ],
          original: " LDA* -1,2",
          label_tokens: [],
          operation_tokens: [symbol: "LDA", asterisk: "*"],
          address_tokens: [operator: "-", number: "1", operator: ",", number: "2"],
          is_op: true,
          is_pseudo: true
        },
        18 => %Easm.LexicalLine{
          tokens: [
            symbol: "B",
            white_space: " ",
            symbol: "EAX",
            white_space: " ",
            symbol: "A",
            operator: "+",
            number: "5"
          ],
          original: "B EAX A+5",
          label_tokens: [symbol: "B"],
          operation_tokens: [symbol: "EAX"],
          address_tokens: [symbol: "A", operator: "+", number: "5"],
          is_op: true,
          is_pseudo: true
        },
        19 => %Easm.LexicalLine{
          tokens: [],
          original: "",
          label_tokens: [],
          operation_tokens: [],
          address_tokens: [],
          is_op: true,
          is_pseudo: true
        },
        :location => 0,
        :current_line => 19,
        :content => 0,
        :line_cursor => 0,
        :relocatable => true,
        :finished_with_line => true,
        :line_ok => true
      },
      line_count: 19,
      if_status: [true],
      relocation_reference: :relocatable,
      absolute_location: 0,
      relocatable_location: 18,
      needs: [:ident, :end],
      label: nil,
      file_ok: true,
      listing: [
        " 00021  07700011  ",
        " 00021  07700011  B EAX A+5",
        " 00020  27677777   LDA* -1,2",
        " 00017  27637777   LDA -1,2",
        " 00016  07637777   LDA -1",
        " 00015  04600014   XAB",
        " 00014  04600600   XXA",
        " 00013  04600004   CAB",
        " 00012  03541142   STA* 610",
        " 00011  03501130   STA 600",
        " 00010  07600764   LDA 500",
        " 00007  00100144    BRU 100",
        " 00006  07600004   LDA A",
        " 00005  07600000   LDA B",
        " 00004  02000000  $A NOP",
        " 00003  00100144   BRU 100",
        " 00002  07700000   EAX A+5",
        " 00001  00100006   BRU *+5",
        " 00000  00137773   BRU *-5"
      ],
      flags: []
    }
  end
end
