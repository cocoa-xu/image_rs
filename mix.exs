defmodule ImgDecode.MixProject do
  use Mix.Project

  def project do
    [
      app: :img_decode_rs,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      source_url: "https://github.com/cocoa-xu/img_decode_rs"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description() do
    "A tiny Elixir library for image decoding task."
  end

  defp deps do
    [
      {:rustler, "~> 0.23.0"},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false}
    ]
  end

  defp package() do
    [
      name: "img_decode_rs",
      files: ~w(native lib .formatter.exs mix.exs),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/cocoa-xu/img_decode_rs"}
    ]
  end
end
