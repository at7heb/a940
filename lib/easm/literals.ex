defmodule Easm.Literals do
  defstruct allocation_strategy: :eager, map: %{}

  def new(allocation_strategy \\ :eager) do
    l = %Easm.Literals{}
    %{l | allocation_strategy: allocation_strategy}
  end

  def handle_literal(
        %Easm.Literals{map: map} = literals,
        literal_definition,
        %Easm.Literal{} = literal
      )
      when is_list(literal_definition) do
    entry = Map.get(map, literal_definition, nil)
    # if literal is new, then entry and literal will be identical

    new_map =
      case entry do
        # literal not used before
        nil -> Map.put(map, literal_definition, literal)
        _ -> new_used_at = [literal.used_at(entry.used_at)]
      end

    # end

    if literal != entry and literal.state == entry.state and literal != entry do
      raise "literal not identical with literals' entry"
    end

    new_uses =
      if entry == literal do
        literal.used_at
      else
        [literal.used_at | entry.used_at]
      end

    new_literal = %{literal | used_at: new_uses}
    new_map = Map.put(map, literal_definition, literal)
    %{literals | map: new_map, used_at: new_uses}
  end

  def get_defined_literal_definitions(%Easm.Literals{map: map} = _l) do
    Enum.filter(map, fn {_k, v} -> v.state == :defined end)
    |> Enum.map(fn {k, _v} -> k end)
  end

  @doc """
  return a list of {{val, reloc}, [{address, reloc}, ...]
  sorted by reloc ascending and then val ascending
  only for :known literals
  """
  def get_defined_literal_values_and_used_addresses(%Easm.Literals{map: map} = _l) do
    map
    |> Enum.filter(fn {_k, v} -> v.state == :known end)
    |> Enum.map(fn {_k, v} -> {v.val, 99} end)
  end
end
