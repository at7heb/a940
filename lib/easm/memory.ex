defmodule Easm.Memory do
  alias Easm.Memory
  alias Easm.ADotOut
  alias Easm.Symbol

  defstruct relocatable?: false,
            location: 0,
            content: 999_999_999,
            # address_field_type is one of :no_addr, :shift_addr, :rch_addr, or :mem_addr
            address_field_type: :no_addr,
            address_symbol: Symbol,
            end_action: {}

  def memory(
        relocatable?,
        location,
        content,
        %Symbol{} = address_symbol,
        address_type,
        end_action \\ nil
      ) do
    %Easm.Memory{
      relocatable?: relocatable?,
      location: location,
      content: content,
      address_field_type: address_type,
      address_symbol: address_symbol,
      end_action: end_action
    }
  end

  def get_location(%ADotOut{} = aout) do
    case aout.relocation_reference do
      :absolute ->
        {aout.absolute_location, false}

      :relocatable ->
        {aout.relocatable_location, true}

      # one or the other of these flags normally set, but at "2BAS IDENT" time, not...
      _ ->
        # LIF
        {nil, nil}
    end
  end

  def address_field_type(memory) when is_list(memory) do
    hd(memory).address_field_type
  end

  def content(memory) when is_list(memory) do
    hd(memory).content
  end

  def update_content(%Memory{} = memory, content)
      when is_integer(content) and content > 0 and content < 16_777_216 do
    %{memory | content: content}
  end

  def replace_memory([_hd | rest] = _memory, %Memory{} = new_word) do
    [new_word | rest]
  end
end
