defprotocol MapDelta.ItemDelta do
  @fallback_to_any true
  @spec compose(any, any) :: any
  def compose(first, second)

  @spec transform(any, any, :left | :right) :: any
  def transform(left, right, priority)
end

defimpl MapDelta.ItemDelta, for: MapDelta do
  defdelegate compose(a, b), to: MapDelta
  defdelegate transform(l, r, priority), to: MapDelta
end

defimpl MapDelta.ItemDelta, for: Any do
  def compose(_first, second), do: second
  def transform(left, _right, :left), do: left
  def transform(_left, right, :right), do: right
end
