# ImgDecodeRs

A tiny Elixir library for image decoding task using [image_rs](https://github.com/image-rs/image) as the backend.

| OS               | Build Status |
|------------------|--------------|
| Ubuntu 20.04     | [![CI](https://github.com/cocoa-xu/img_decode_rs/actions/workflows/linux.yml/badge.svg)](https://github.com/cocoa-xu/img_decode_rs/actions/workflows/linux.yml) |
| macOS 11         | [![CI](https://github.com/cocoa-xu/img_decode_rs/actions/workflows/macos.yml/badge.svg)](https://github.com/cocoa-xu/img_decode_rs/actions/workflows/macos.yml) |

There is an alternative version of this repo, [img_decode](https://github.com/cocoa-xu/img_decode_rs), which uses [stb_image.h](https://github.com/nothings/stb/blob/master/stb_image.h)
as the backend. It is implemented in C++, so you only need a working C++ compiler. But the number of supported image formats are less
less than the `image_rs` backend.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `img_decode_rs` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:img_decode_rs, "~> 0.1.0", github: "cocoa-xu/img_decode_rs"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/img_decode](https://hexdocs.pm/img_decode).

