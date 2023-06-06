defmodule Changelog.MixProject do
  use Mix.Project

  def project do
    [
      app: :changelog_cicd,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dagger_ex, github: "dagger/dagger", sparse: "sdk/elixir", branch: "main"}
    ]
  end
end
