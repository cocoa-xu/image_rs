defmodule ImageRs.Nif do
  @moduledoc false

  mix_config = Mix.Project.config()
  version = mix_config[:version]
  github_url = mix_config[:package][:links]["GitHub"]
  # Since Rustler 0.27.0, we need to change manually the mode for each env.
  # We want "debug" in dev and test because it's faster to compile.
  mode = if Mix.env() in [:dev, :test], do: :debug, else: :release

  use_legacy =
    Application.compile_env(
      :image_rs,
      :use_legacy_artifacts,
      System.get_env("IMAGE_RS_USE_LEGACY_ARTIFACTS") in ["true", "1"]
    )

  variants_for_linux = [
    legacy_cpu: fn ->
      # These are the same from the release workflow.
      # See the meaning in: https://unix.stackexchange.com/a/43540
      needed_caps = ~w[fxsr sse sse2 ssse3 sse4_1 sse4_2 popcnt avx fma]

      use_legacy or
        (is_nil(use_legacy) and
           not Explorer.ComptimeUtils.cpu_with_all_caps?(needed_caps))
    end
  ]

  other_variants = [legacy_cpu: fn -> use_legacy end]

  use RustlerPrecompiled,
    otp_app: :image_rs,
    version: version,
    base_url: "#{github_url}/releases/download/v#{version}",
    targets: ~w(
      aarch64-apple-darwin
      aarch64-unknown-linux-gnu
      x86_64-apple-darwin
      x86_64-pc-windows-msvc
      x86_64-pc-windows-gnu
      x86_64-unknown-linux-gnu
      x86_64-unknown-freebsd
    ),
    variants: %{
      "x86_64-unknown-linux-gnu" => variants_for_linux,
      "x86_64-pc-windows-msvc" => other_variants,
      "x86_64-pc-windows-gnu" => other_variants,
      "x86_64-unknown-freebsd" => other_variants
    },
    # We don't use any features of newer NIF versions, so 2.15 is enough.
    nif_versions: ["2.15"],
    mode: mode,
    force_build: System.get_env("IMAGE_RS_BUILD") in ["1", "true"]

  def from_file(_filename), do: :erlang.nif_error(:not_loaded)
  def from_binary(_data), do: :erlang.nif_error(:not_loaded)
  def new(_height, _width, _color_type, _dtype, _data), do: :erlang.nif_error(:not_loaded)
  def to_binary(_image), do: :erlang.nif_error(:not_loaded)
  def resize(_image, _height, _width, _filter_type), do: :erlang.nif_error(:not_loaded)

  def resize_preserve_ratio(_image, _height, _width, _filter_type),
    do: :erlang.nif_error(:not_loaded)

  def resize_to_fill(_image, _height, _width, _filter_type), do: :erlang.nif_error(:not_loaded)

  def crop(_image, _x, _y, _height, _width), do: :erlang.nif_error(:not_loaded)
  def grayscale(_image), do: :erlang.nif_error(:not_loaded)
  def invert(_image), do: :erlang.nif_error(:not_loaded)
  def blur(_image, _sigma), do: :erlang.nif_error(:not_loaded)
  def unsharpen(_image, _sigma, _threshold), do: :erlang.nif_error(:not_loaded)
  def filter3x3(_image, _kernel), do: :erlang.nif_error(:not_loaded)
  def adjust_contrast(_image, _contrast), do: :erlang.nif_error(:not_loaded)
  def brighten(_image, _value), do: :erlang.nif_error(:not_loaded)
  def huerotate(_image, _value), do: :erlang.nif_error(:not_loaded)
  def flipv(_image), do: :erlang.nif_error(:not_loaded)
  def fliph(_image), do: :erlang.nif_error(:not_loaded)
  def rotate90(_image), do: :erlang.nif_error(:not_loaded)
  def rotate180(_image), do: :erlang.nif_error(:not_loaded)
  def rotate270(_image), do: :erlang.nif_error(:not_loaded)
  def encode_as(_image, _format, _options), do: :erlang.nif_error(:not_loaded)
  def save(_image, _path), do: :erlang.nif_error(:not_loaded)
  def save_with_format(_image, _path, _format), do: :erlang.nif_error(:not_loaded)
end
