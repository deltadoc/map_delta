defprotocol MapDelta.ItemDelta do
  @moduledoc """
  Item delta represents a delta of map item value.

  There are three requirements for any item delta:

  1. It must be composable.
  2. It must be transformable.
  3. It must be applicable.

  These requirements are outlines in this protocol, which must be implemented
  for any new value type you want maps to support.
  """

  @fallback_to_any true

  alias MapDelta.{Transformation, Application}

  @typedoc """
  Result of `&MapDelta.appy/2` operation.

  Either a successful new state or an error with a clear reason.
  """
  @type application_result :: {:ok, any}
                            | {:error, Application.item_path, atom}

  @doc """
  Composes two given item values together.

  The deltas must be composed in such a way that the resulting delta has the
  same effect on document state as applying one delta and then the other:

    S ○ compose(Oa, Ob) = S ○ Oa ○ Ob
  """
  @spec compose(any, any) :: any
  def compose(first, second)

  @doc """
  Transforms `right` delta against the `left` one.

  Transformation allows optimistic conflict resolution in concurrent editing.
  Given a delta A that occurred at the same time as delta B against the same
  map state, we can transform the operations of delta A such that the state of
  the map after applying delta A and then delta B is the same as after applying
  delta B and then the transformation of delta A against delta B:

    S ○ Oa ○ transform(Ob, Oa) = S ○ Ob ○ transform(Oa, Ob)

  The function also takes a third `t:MapDelta.Transformation.priority/0`
  argument that indicates which delta came first. This is important when
  resolving conflicts.
  """
  @spec transform(any, any, Transformation.priority) :: any
  def transform(left, right, priority)

  @doc """
  Applies given delta to a particular item state, resulting in a new state.

  Each type of item should define for itself what valid state is, but all of
  them must ensure that if application results in invalid state, `:error`
  tuple must be returned instead.

  Apply must return either `:ok` tuple with a new state or an `:error` tuple
  with `t:MapDelta.Application.item_path/0` and
  `t:MapDelta.Application.error_reason/0`.
  """
  @spec apply(any, any) :: application_result
  def apply(state, delta)
end

defimpl MapDelta.ItemDelta, for: MapDelta do
  @moduledoc """
  Implementation of item delta for map deltas themselves.

  Allows support of recusrive map transformations.
  """

  defdelegate compose(first, second), to: MapDelta
  defdelegate transform(left, right, priority), to: MapDelta
  defdelegate apply(state, delta), to: MapDelta
end

defimpl MapDelta.ItemDelta, for: Any do
  @moduledoc """
  Fallback implementation of item delta for simple values.

  Operates on a simple premise of non-incremental updates - new values
  completely override previous ones.
  """

  def compose(_first, second), do: second
  def transform(left, _right, :left), do: left
  def transform(_left, right, :right), do: right
  def apply(_state, delta), do: {:ok, delta}
end
