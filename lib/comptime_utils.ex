defmodule ImageRs.ComptimeUtils do
  @moduledoc false
  # This module is useful to control some aspects of compilation.
  # It is copy-pasted from
  # https://raw.githubusercontent.com/elixir-explorer/explorer/521fef02a3f12cf46fa8be32c48c472642e0e827/lib/explorer/comptime_utils.ex

  # Only works for Linux targets today, but we don't need more.
  @doc false
  def cpu_with_all_caps?(needed_flags, opts \\ []) do
    opts = Keyword.validate!(opts, cpu_info_file_path: "/proc/cpuinfo", target: nil)

    case File.read(opts[:cpu_info_file_path]) do
      {:ok, contents} ->
        flags =
          contents
          |> String.split("\n")
          |> Stream.filter(&String.starts_with?(&1, "flags"))
          |> Stream.map(fn line ->
            [_, flags] = String.split(line, ": ")
            String.split(flags)
          end)
          |> Stream.uniq()
          |> Enum.to_list()
          |> List.flatten()

        Enum.all?(needed_flags, fn flag -> flag in flags end)

      {:error, _} ->
        # There is no way to say, so we default to false.
        false
    end
  end
end
