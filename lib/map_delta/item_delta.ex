defprotocol MapDelta.ItemDelta do
  @moduledoc """
  Item delta represents a delta of map item value.

  There are only two requirements for any item delta - it should be composable
  and transformable, same as the `MapDelta` itself.
  """

  @fallback_to_any true

  alias MapDelta.Transformation

  @doc """
  Composes two given item values together.
  """
  @spec compose(any, any) :: any
  def compose(first, second)

  @doc """
  Transforms right value against the left one with a set priority.
  """
  @spec transform(any, any, Transformation.priority) :: any
  def transform(left, right, priority)
end

defimpl MapDelta.ItemDelta, for: MapDelta do
  defdelegate compose(first, second), to: MapDelta
  defdelegate transform(left, right, priority), to: MapDelta
end

defimpl MapDelta.ItemDelta, for: Any do
  def compose(_first, second), do: second
  def transform(left, _right, :left), do: left
  def transform(_left, right, :right), do: right
end
