defprotocol MapDelta.ItemDelta do
  @fallback_to_any true
  @spec compose(any, any) :: any
  def compose(first, second)
end

defimpl MapDelta.ItemDelta, for: MapDelta do
  defdelegate compose(a, b), to: MapDelta
end

defimpl MapDelta.ItemDelta, for: Any do
  def compose(_first, second), do: second
end
