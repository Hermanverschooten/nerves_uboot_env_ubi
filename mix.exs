defmodule NervesUbootEnvUBI.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/Hermanverschooten/nerves_uboot_env_ubi"

  def project do
    [
      app: :nerves_uboot_env_ubi,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      source_url: @source_url
    ]
  end

  def cli do
    [
      preferred_envs: %{
        docs: :docs,
        "hex.build": :docs,
        "hex.publish": :docs
      }
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:nerves_runtime, "~> 0.13"},
      {:uboot_env, "~> 1.0"},
      {:ex_doc, "~> 0.31", only: :docs, runtime: false}
    ]
  end

  defp description do
    "Nerves.Runtime.KVBackend that reads and writes a U-Boot environment stored in UBI volumes"
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib mix.exs README.md CHANGELOG.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end
end
