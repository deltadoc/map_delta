defmodule MapDelta.Mixfile do
  use Mix.Project

  def project do
    [app: :map_delta,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     aliases: aliases()]
  end

  def application, do: []

  defp aliases do
    [lint: ["credo --strict"]]
  end

  defp deps do
    [{:ex_doc, "~> 0.15", only: [:dev], runtime: false},
     {:credo, "~> 0.7", only: [:dev, :test], runtime: false},
     {:eqc_ex, "~> 1.4", only: [:dev, :test], runtime: false}]
  end
end
