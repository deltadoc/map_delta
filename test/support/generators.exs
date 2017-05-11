defmodule MapDelta.Generators do
  use EQC.ExUnit

  alias MapDelta.Operation

  @max_item_key_length 25

  def state do
    let adds <- list(add()) do
      MapDelta.new(adds)
    end
  end

  def delta do
    let ops <- list(operation()) do
      MapDelta.new(ops)
    end
  end

  def state_delta(state) do
    let ops <- list(operation_on(item_keys_of(state))) do
      MapDelta.new(ops)
    end
  end

  def operation do
    oneof [add(), remove(), replace(), change()]
  end

  def operation_on(item_keys) when length(item_keys) == 0, do: add()
  def operation_on(item_keys) do
    oneof [add(), remove(item_keys), replace(item_keys), change(item_keys)]
  end

  def add do
    let [key <- item_key(), init <- item_delta()] do
      Operation.add(key, init)
    end
  end

  def remove do
    let key <- item_key() do
      Operation.remove(key)
    end
  end

  def remove(item_keys) do
    let key <- elements(item_keys) do
      Operation.remove(key)
    end
  end

  def replace do
    let [key <- item_key(), init <- item_delta()] do
      Operation.replace(key, init)
    end
  end

  def replace(item_keys) do
    let [key <- elements(item_keys), init <- item_delta()] do
      Operation.replace(key, init)
    end
  end

  def change do
    let [key <- item_key(), delta <- item_delta()] do
      Operation.change(key, delta)
    end
  end

  def change(item_keys) do
    let [key <- elements(item_keys), delta <- item_delta()] do
      Operation.change(key, delta)
    end
  end

  def item_key do
    let length <- choose(1, @max_item_key_length) do
      random_string(length)
    end
  end

  def item_delta do
    oneof [int(), bool(), list(int()), utf8(), nil]
  end

  def priority_side do
    oneof [:left, :right]
  end

  def opposite(:left), do: :right
  def opposite(:right), do: :left

  defp item_keys_of(doc) do
    doc
    |> MapDelta.operations()
    |> Enum.map(&Operation.item_key/1)
  end

  defp random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> String.slice(0, length)
  end
end
