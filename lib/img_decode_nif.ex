defmodule ImgDecode.ImageRs do
  @moduledoc false

  use Rustler, otp_app: :img_decode_rs, crate: "img_decode_rs"

  def from_file(_filename), do: :erlang.nif_error(:not_loaded)
  def from_memory(_buffer), do: :erlang.nif_error(:not_loaded)
end
