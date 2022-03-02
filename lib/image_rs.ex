defmodule ImageRs do
  @moduledoc """
  Documentation for `ImageRs`.
  """

  @doc """
  Decode image from a given file

  - **filename**. Path to the image.

  ## Example
  ```elixir
  {:ok, img, shape, type} = ImageRs.from_file("/path/to/image")
  {h, w, c} = shape
  ```
  """
  def from_file(filename) do
    case ImageRs.Nif.from_file(filename) do
      {:error, reason} ->
        {:error, reason}

      {:ok, result} ->
        {img, shape, type, channels} = result
        {:ok, img, shape, String.to_atom(type), String.to_atom(channels)}
    end
  end

  @doc """
  Decode image from buffer in memory

  - **buffer**. Buffered raw file data in memory.

  ## Example
  ```elixir
  # image buffer from a file or perhaps download from Internet
  {:ok, buffer} = File.read("/path/to/image")
  # decode the image from memory
  {:ok, img, shape, type} = ImageRs.from_memory(buffer)
  {h, w, c} = shape
  ```
  """
  def from_memory(buffer) do
    case ImageRs.Nif.from_memory(buffer) do
      {:error, reason} ->
        {:error, reason}

      {:ok, result} ->
        {img, shape, type, channels} = result
        {:ok, img, shape, String.to_atom(type), String.to_atom(channels)}
    end
  end
end
