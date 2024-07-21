defmodule ResolverTest do
  use ExUnit.Case
  doctest Easm.Resolver
  alias Easm.Resolver
  alias Easm.Symbol
  alias Easm.Address
  alias Easm.Memory
  alias Easm.ADotOut

  test "can count # of known addresses" do
    symbols = make_test_symbols()
    addresses = make_test_addresses(symbols)
    memory = make_test_memory(addresses)
    aout = make_test_aout(symbols, addresses, memory)
    rv = Lexer.match_white_space("   CAX")
    assert {true, {:white_space, " "}, "CAX"} = rv
    assert false == Lexer.match_white_space("* A COMMENT")
  end

  test "count # of defined addresses" do
  end

  test "can resolve an address" do
  end

  test "can detect when unresolvable address exists" do
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

  def make(test_addresses(symbols_map) when is_map(symbols_map)) do
  end

  def make(test_memory(addresses_map) when is_map(addresses_map)) do
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

  make test_a_out(symbols_map, addresses_map, memory_map)
       when is_map(symbols_map) and is_map(addresses_map) and is_map(memory_map) do
  end
end
