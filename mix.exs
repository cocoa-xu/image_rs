defmodule ImgDecode.MixProject do
  use Mix.Project

  @version "0.3.0-dev"
  @github_url "https://github.com/cocoa-xu/image_rs"
  @dev? String.ends_with?(@version, "-dev")
  @force_build? System.get_env("IMAGE_RS_BUILD") in ["1", "true"]

  @nerves_rust_target_triple_mapping %{
    "armv6-nerves-linux-gnueabihf": "arm-unknown-linux-gnueabihf",
    "armv7-nerves-linux-gnueabihf": "armv7-unknown-linux-gnueabihf",
    "aarch64-nerves-linux-gnu": "aarch64-unknown-linux-gnu"
  }

  def project do
    if is_binary(System.get_env("NERVES_SDK_SYSROOT")) do
      components =
        System.get_env("CC")
        |> tap(&System.put_env("RUSTFLAGS", "-C linker=#{&1}"))
        |> Path.basename()
        |> String.split("-")

      target_triple =
        components
        |> Enum.slice(0, Enum.count(components) - 1)
        |> Enum.join("-")

      mapping = Map.get(@nerves_rust_target_triple_mapping, String.to_atom(target_triple))

      if is_binary(mapping) do
        System.put_env("RUSTLER_TARGET", mapping)
      end
    end

    [
      app: :image_rs,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      source_url: @github_url,
      aliases: [
        "rust.lint": ["cmd cargo clippy --manifest-path=native/image_rs/Cargo.toml -- -Dwarnings"],
        "rust.fmt": ["cmd cargo fmt --manifest-path=native/image_rs/Cargo.toml --all"],
        ci: ["format", "rust.fmt", "rust.lint", "test"]
      ]
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
      {:castore, "~> 1.0 or ~> 0.1"},
      {:rustler, "~> 0.30.0", optional: not (@dev? or @force_build?)},
      {:rustler_precompiled, "~> 0.7"},
      {:ex_doc, "~> 0.29", only: :docs, runtime: false}
    ]
  end

  defp package() do
    [
      name: "image_rs",
      files: ~w(
        lib
        native
        checksum-*.exs
        mix.exs
        README.md
        LICENSE),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @github_url}
    ]
  end
end
