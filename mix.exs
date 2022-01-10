defmodule ImgDecode.MixProject do
  use Mix.Project

  @github_url "https://github.com/cocoa-xu/image_rs"
  def project do
    [
      app: :image_rs,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      source_url: @github_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description() do
    "A tiny Elixir library for image decoding task with image_rs as the backend."
  end

  defp deps do
    [
      {:rustler, "~> 0.23.0"},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false}
    ]
  end

  defp package() do
    [
      name: "image_rs",
      files: ~w(native lib .formatter.exs mix.exs),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @github_url}
    ]
  end
end
