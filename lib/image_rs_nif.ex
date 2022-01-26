defmodule ImageRs.Nif do
  @moduledoc false

  # defp make_target_flag(args, target) when is_binary(target)
  # so it is fine if we get `:nil`
  use Rustler, otp_app: :image_rs, crate: "image_rs_nif", target: System.get_env("RUSTLER_TARGET")

  def from_file(_filename), do: :erlang.nif_error(:not_loaded)
  def from_memory(_buffer), do: :erlang.nif_error(:not_loaded)
end
