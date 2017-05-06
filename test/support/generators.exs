defmodule MapDelta.Generators do
  use EQC.ExUnit

  alias MapDelta.Operation

  @max_property_length 25

  def document do
    let adds <- list(add()) do
      MapDelta.new(adds)
    end
  end

  def delta do
    let ops <- list(operation()) do
      MapDelta.new(ops)
    end
  end

  def operation do
    oneof [add(), remove(), replace(), change()]
  end

  def add do
    let [prop <- property(), init <- property_delta()] do
      Operation.add(prop, init)
    end
  end

  def remove do
    let prop <- property() do
      Operation.remove(prop)
    end
  end

  def replace do
    let [prop <- property(), init <- property_delta()] do
      Operation.replace(prop, init)
    end
  end

  def change do
    let [prop <- property(), delta <- property_delta()] do
      Operation.change(prop, delta)
    end
  end

  def property_delta do
    oneof [int(), bool(), list(int()), utf8(), nil]
  end

  def property do
    let length <- choose(1, @max_property_length) do
      random_string(length)
    end
  end

  defp random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> String.slice(0, length)
  end
end
