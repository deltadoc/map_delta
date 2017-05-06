defprotocol MapDelta.PropertyDelta do
  @fallback_to_any true
  @spec compose(any, any) :: any
  def compose(first, second)
end

defimpl MapDelta.PropertyDelta, for: MapDelta do
  defdelegate compose(a, b), to: MapDelta
end

defimpl MapDelta.PropertyDelta, for: Any do
  def compose(_first, second), do: second
end
