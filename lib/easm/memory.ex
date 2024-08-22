defmodule Easm.Memory do
  alias Easm.Memory
  alias Easm.ADotOut
  # alias Easm.Symbol

  defstruct address_relocation: 0,
            location: 0,
            instruction_relocation: 1,
            content: 999_999_999,
            # address_field_type is one of :no_addr, :shift_addr, :rch_addr, or :mem_addr
            address_field_type: :no_addr,
            symbol_name: "",
            end_action: {}

  def memory(
        address_relocation,
        location,
        instruction_relocation,
        content,
        symbol_name,
        address_type,
        end_action \\ nil
      )
      when is_integer(address_relocation) and is_integer(instruction_relocation) do
    %Easm.Memory{
      address_relocation: address_relocation,
      location: location,
      instruction_relocation: instruction_relocation,
      content: content,
      address_field_type: address_type,
      symbol_name: symbol_name,
      end_action: end_action
    }
  end

  def get_location(%ADotOut{} = aout) do
    case aout.relocation_reference do
      :absolute ->
        {aout.absolute_location, 0}

      :relocatable ->
        {aout.relocatable_location, 1}

      # one or the other of these flags normally set, but at "2BAS IDENT" time, not...
      _ ->
        # LIF
        {nil, nil}
    end
  end

  def address_field_type(memory) when is_list(memory) do
    hd(memory).address_field_type
  end

  def clean_for_new_statement(%ADotOut{} = aout) do
    aout
  end

  def get_content(%Memory{} = memory), do: memory.content

  def update_content(%Memory{} = memory, content)
      when is_integer(content) and content > 0 and content < 16_777_216,
      do: %{memory | content: content}

  def replace_memory([_hd | rest] = _memory, %Memory{} = new_word), do: [new_word | rest]
end
