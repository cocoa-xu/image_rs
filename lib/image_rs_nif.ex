defmodule ImageRs.Nif do
  @moduledoc false

  use Rustler, otp_app: :image_rs, crate: "image_rs_nif"

  def from_file(_filename), do: :erlang.nif_error(:not_loaded)
  def from_memory(_buffer), do: :erlang.nif_error(:not_loaded)
end
