defmodule Easm.Memory do
  alias Easm.ADotOut
  alias Easm.Symbol

  defstruct relocatable?: false,
            location: 0,
            content: 999_999_999,
            address_field_type: :atom,
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
end
