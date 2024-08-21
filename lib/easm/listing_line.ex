defmodule Easm.ListingLine do
  alias Easm.ListingLine
  defstruct location: 0, relocation: 0, content: 0, text: ""

  def new(location, relocation, content, text) do
    %ListingLine{location: location, relocation: relocation, content: content, text: text}
  end

  def update_content(%ListingLine{} = ll, new_content)
      when is_integer(new_content) and new_content >= 0 and new_content <= 8_388_607 do
    cond do
      ll.content == new_content -> ll
      true -> %{ll | content: new_content}
    end
  end

  def to_string(
        %ListingLine{location: location, relocation: relocation, content: content, text: text} =
          _ll
      ) do
    to_string(:location, location) <>
      to_string(:relocation, relocation) <>
      to_string(:content, content) <>
      text
  end

  def to_string(type, value) when is_atom(type) and is_integer(value) do
    {width, trailing_spaces} =
      case type do
        :location -> {5, 0}
        :relocation -> {1, 2}
        :content -> {8, 2}
      end

    text =
      cond do
        type == :relocation and value == 0 -> "A"
        type == :relocation and value == 1 -> "R"
        true -> Integer.to_string(value, 8)
      end

    zero_padding = String.duplicate("0", width - String.length(text))
    zero_padding <> text <> String.duplicate(" ", trailing_spaces)
  end
end
