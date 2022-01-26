# ImageRs-Elixir

A tiny Elixir library for image decoding task using [image_rs](https://github.com/image-rs/image) as the backend.

| OS               | Arch   | Build Status |
|------------------|--------|--------------|
| Ubuntu 20.04     | x86_64 |[![CI](https://github.com/cocoa-xu/image_rs/actions/workflows/linux.yml/badge.svg)](https://github.com/cocoa-xu/image_rs/actions/workflows/linux.yml) |
| Ubuntu 20.04     | others |[![CI](https://github.com/cocoa-xu/image_rs/actions/workflows/nerves.yml/badge.svg)](https://github.com/cocoa-xu/image_rs/actions/workflows/nerves.yml) |
| macOS 11         | arm64/x86_64 | [![CI](https://github.com/cocoa-xu/image_rs/actions/workflows/macos.yml/badge.svg)](https://github.com/cocoa-xu/image_rs/actions/workflows/macos.yml) |

There is an alternative version of this repo, [stb_image](https://github.com/cocoa-xu/stb_image), which uses [stb_image.h](https://github.com/nothings/stb/blob/master/stb_image.h)
as the backend. It is implemented in C++, so you only need a working C++ compiler. But the number of supported image formats are 
less than the `image_rs` backend.

## Nerves Support

[![Nerves](https://github-actions.40ants.com/cocoa-xu/image_rs/matrix.svg?only=nerves)](https://github.com/cocoa-xu/image_rs)

Prebuilt firmwares are available [here](https://github.com/cocoa-xu/image_rs/actions/workflows/nerves.yml?query=is%3Asuccess).
Select the most recent run and scroll down to the `Artifacts` section, download the firmware file for your board and run

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `image_rs` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:image_rs, "~> 0.1.0", github: "cocoa-xu/image_rs"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/image_rs](https://hexdocs.pm/image_rs).

