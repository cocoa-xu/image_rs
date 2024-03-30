defmodule ImageRs do
  @moduledoc """

  """

  defstruct [
    :width,
    :height,
    :channels,
    color_type: nil,
    dtype: nil,
    shape: nil,
    resource: nil
  ]

  @type t :: %__MODULE__{
          resource: reference(),
          width: non_neg_integer(),
          height: non_neg_integer(),
          color_type: :l | :la | :rgb | :rgba | :unknown,
          dtype: :u8 | :u16 | :f32,
          shape: [non_neg_integer()],
          channels: non_neg_integer()
        }

  @type output_format ::
          :png
          | :jpeg
          | :pnm
          | :gif
          | :ico
          | :bmp
          | :farbfeld
          | :tga
          | :exr
          | :tiff
          | :avif
          | :qoi
          | :webp

  @doc """
  Decode image from a given file

  - **filename**. Path to the image.

  ## Example
  ```elixir
  {:ok, image} = ImageRs.from_file("/path/to/image")
  width = image.width
  height = image.height
  channels = image.channels
  shape = image.shape
  {^height, ^width, ^channels} = shape
  color_type = image.color_type
  type = image.type
  ```
  """
  @spec from_file(Path.t()) :: {:ok, ImageRs.t()} | {:error, String.t()}
  def from_file(filename) do
    ImageRs.Nif.from_file(filename)
  end

  @doc """
  Similar to from_file/1 but raises on errors
  """
  @spec from_file!(Path.t()) :: ImageRs.t()
  def from_file!(filename) do
    with {:ok, image} <- ImageRs.Nif.from_file(filename) do
      image
    else
      {:error, msg} ->
        raise RuntimeError, msg
    end
  end

  @doc """
  Decode image from buffer in memory

  - **data**. Image data in memory.

  ## Example
  ```elixir
  # image buffer from a file or perhaps download from the Internet
  {:ok, data} = File.read("/path/to/image")

  # decode the image from memory
  {:ok, image} = ImageRs.from_binary(data)
  width = image.width
  height = image.height
  channels = image.channels
  shape = image.shape
  {^height, ^width, ^channels} = shape
  color_type = image.color_type
  type = image.type
  ```
  """
  @spec from_binary(binary()) :: {:ok, ImageRs.t()} | {:error, String.t()}
  def from_binary(data) when is_binary(data) do
    ImageRs.Nif.from_binary(data)
  end

  @doc """
  Similar to from_binary/1 but raises on errors
  """
  @spec from_binary!(binary()) :: ImageRs.t()
  def from_binary!(data) when is_binary(data) do
    with {:ok, image} <- ImageRs.Nif.from_binary(data) do
      image
    else
      {:error, msg} ->
        raise RuntimeError, msg
    end
  end

  @doc """
  Create a new `ImageRs` from given binary with corresponding parameters.
  """
  @spec new(pos_integer(), pos_integer(), :l | :la | :rgb | :rgba, :u8 | :u16 | :f32, binary()) ::
          {:ok, ImageRs.t()} | {:error, String.t()}
  def new(height, width, color_type, dtype, data) do
    ImageRs.Nif.new(height, width, color_type, dtype, data)
  end

  @doc """
  Get binary representation of pixels.
  """
  @spec to_binary(ImageRs.t()) :: {:ok, binary()} | {:error, String.t()}
  def to_binary(image) do
    ImageRs.Nif.to_binary(image)
  end

  @doc """
  Resize this image using the specified filter algorithm.

  Returns a new image. Does not preserve aspect ratio.

  `height` and `width` are the new image's dimensions.
  """
  @spec resize(
          ImageRs.t(),
          non_neg_integer(),
          non_neg_integer(),
          :nearest | :triangle | :catmull_rom | :gaussian | :lanczos3
        ) :: {:ok, ImageRs.t()} | {:error, String.t()}
  def resize(image, height, width, filter_type \\ :lanczos3) do
    ImageRs.Nif.resize(image, height, width, filter_type)
  end

  @doc """
  Resize this image using the specified filter algorithm.

  Returns a new image. The image's aspect ratio is preserved.

  The image is scaled to the maximum possible size that fits within the bounds specified by `width` and `height`.
  """
  @spec resize_preserve_ratio(
          ImageRs.t(),
          non_neg_integer(),
          non_neg_integer(),
          :nearest | :triangle | :catmull_rom | :gaussian | :lanczos3
        ) :: {:ok, ImageRs.t()} | {:error, String.t()}
  def resize_preserve_ratio(image, height, width, filter_type \\ :lanczos3) do
    ImageRs.Nif.resize_preserve_ratio(image, height, width, filter_type)
  end

  @doc """
  Resize this image using the specified filter algorithm.

  Returns a new image. The image's aspect ratio is preserved.

  The image is scaled to the maximum possible size that fits within the larger
  (relative to aspect ratio) of the bounds specified by `height` and `width`,
  then cropped to fit within the other bound.
  """
  @spec resize_to_fill(
          ImageRs.t(),
          non_neg_integer(),
          non_neg_integer(),
          :nearest | :triangle | :catmull_rom | :gaussian | :lanczos3
        ) :: {:ok, ImageRs.t()} | {:error, String.t()}
  def resize_to_fill(image, height, width, filter_type \\ :lanczos3) do
    ImageRs.Nif.resize_to_fill(image, height, width, filter_type)
  end

  @doc """
  Return a cut-out of this image delimited by the bounding rectangle.
  """
  @spec crop(
          ImageRs.t(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer()
        ) :: {:ok, ImageRs.t()} | {:error, String.t()}
  def crop(image, x, y, height, width) do
    ImageRs.Nif.crop(image, x, y, height, width)
  end

  @doc """
  Return a grayscale version of this image.

  Returns Luma images in most cases. However, for f32 images, this will return a grayscale Rgb/Rgba image instead.
  """
  @spec grayscale(ImageRs.t()) ::
          {:ok, ImageRs.t()} | {:error, String.t()}
  def grayscale(image) do
    ImageRs.Nif.grayscale(image)
  end

  @doc """
  Invert the colors of this image.
  """
  @spec invert(ImageRs.t()) :: {:ok, ImageRs.t()} | {:error, String.t()}
  def invert(image) do
    ImageRs.Nif.invert(image)
  end

  @doc """
  Performs a Gaussian blur on this image.

  `sigma` is a measure of how much to blur by.
  """
  @spec blur(ImageRs.t(), float()) ::
          {:ok, ImageRs.t()} | {:error, String.t()}
  def blur(image, sigma) do
    ImageRs.Nif.blur(image, sigma * 1.0)
  end

  @doc """
  Performs an unsharpen mask on this image.

  `sigma` is the amount to blur the image by.

  `threshold` is a control of how much to sharpen.
  """
  @spec unsharpen(ImageRs.t(), float(), integer()) ::
          {:ok, ImageRs.t()} | {:error, String.t()}
  def unsharpen(image, sigma, threshold) do
    ImageRs.Nif.unsharpen(image, sigma * 1.0, threshold)
  end

  @doc """
  Filters this image with the specified 3x3 kernel.
  """
  @spec filter3x3(
          ImageRs.t(),
          [number()]
        ) ::
          {:ok, ImageRs.t()} | {:error, String.t()}
  def filter3x3(image, kernel) when is_list(kernel) do
    kernel = List.flatten(kernel)

    if Enum.count(kernel) == 9 do
      try do
        kernel = Enum.map(kernel, &(&1 * 1.0))
        ImageRs.Nif.filter3x3(image, List.flatten(kernel))
      catch
        _ ->
          {:error, "kernel must be a list of 9 floats or a matrix of 3x3 float type"}
      end
    else
      {:error, "kernel must be a list of 9 floats or a matrix of 3x3 float type"}
    end
  end

  @doc """
  Adjust the contrast of this image.

  `contrast` is the amount to adjust the contrast by.

  Negative values decrease the contrast and positive values increase the contrast.
  """
  @spec adjust_contrast(ImageRs.t(), float()) ::
          {:ok, ImageRs.t()} | {:error, String.t()}
  def adjust_contrast(image, contrast) do
    ImageRs.Nif.adjust_contrast(image, contrast * 1.0)
  end

  @doc """
  Brighten the pixels of this image.

  `value` is the amount to brighten each pixel by.

  Negative values decrease the brightness and positive values increase it.
  """
  @spec brighten(ImageRs.t(), integer()) ::
          {:ok, ImageRs.t()} | {:error, String.t()}
  def brighten(image, value) do
    ImageRs.Nif.brighten(image, value)
  end

  @doc """
  Hue rotate the supplied image.

  `value` is the degrees to rotate each pixel by.

  0 and 360 do nothing, the rest rotates by the given degree value.

  just like the css webkit filter hue-rotate(180)
  """
  @spec huerotate(ImageRs.t(), integer()) ::
          {:ok, ImageRs.t()} | {:error, String.t()}
  def huerotate(image, value) do
    ImageRs.Nif.huerotate(image, value)
  end

  @doc """
  Flip this image vertically
  """
  @spec flipv(ImageRs.t()) ::
          {:ok, ImageRs.t()} | {:error, String.t()}
  def flipv(image) do
    ImageRs.Nif.flipv(image)
  end

  @doc """
  Flip this image horizontally
  """
  @spec fliph(ImageRs.t()) ::
          {:ok, ImageRs.t()} | {:error, String.t()}
  def fliph(image) do
    ImageRs.Nif.fliph(image)
  end

  @doc """
  Rotate this image 90 degrees clockwise.
  """
  @spec rotate90(ImageRs.t()) ::
          {:ok, ImageRs.t()} | {:error, String.t()}
  def rotate90(image) do
    ImageRs.Nif.rotate90(image)
  end

  @doc """
  Rotate this image 180 degrees clockwise.
  """
  @spec rotate180(ImageRs.t()) ::
          {:ok, ImageRs.t()} | {:error, String.t()}
  def rotate180(image) do
    ImageRs.Nif.rotate180(image)
  end

  @doc """
  Rotate this image 270 degrees clockwise.
  """
  @spec rotate270(ImageRs.t()) ::
          {:ok, ImageRs.t()} | {:error, String.t()}
  def rotate270(image) do
    ImageRs.Nif.rotate270(image)
  end

  @doc """
  Encode this image as format.
  """
  @spec encode_as(ImageRs.t(), output_format(), Keyword.t()) ::
          {:ok, binary()} | {:error, String.t()}
  def encode_as(image, format, options \\ []) do
    with {:ok, checked_options} <- validate_output_format_and_options(format, options) do
      ImageRs.Nif.encode_as(image, format, checked_options)
    end
  end

  @doc """
  Saves the buffer to a file at the path specified.
  """
  @spec save(ImageRs.t(), Path.t()) :: :ok | {:error, String.t()}
  def save(image, path) do
    ImageRs.Nif.save(image, path)
  end

  @doc """
  Saves the buffer to a file at the path specified in the specified format.
  """
  @spec save_with_format(ImageRs.t(), Path.t(), output_format()) :: :ok | {:error, String.t()}
  def save_with_format(image, path, format) do
    supported_formats = supported_formats()

    if format in supported_formats do
      ImageRs.Nif.save_with_format(image, path, format)
    else
      {:error, "`:format` parameter must be one of #{inspect(supported_formats)}"}
    end
  end

  defp validate_output_format_and_options(:jpeg, options) do
    q = options[:quality]

    case q do
      nil ->
        {:error, "`:quality` parameter for `:jpeg` output format must be an integer in [0, 100]"}

      q when is_integer(q) ->
        if 0 <= q and q <= 100 do
          {:ok, %{"quality" => "#{q}"}}
        else
          {:error,
           "`:quality` parameter for `:jpeg` output format must be an integer in [0, 100]"}
        end

      q when is_binary(q) ->
        case Integer.parse(q, 10) do
          {q, ""} ->
            if 0 <= q and q <= 100 do
              {:ok, %{"quality" => "#{q}"}}
            else
              {:error,
               "`:quality` parameter for `:jpeg` output format must be an integer in [0, 100]"}
            end

          :error ->
            {:error,
             "`:quality` parameter for `:jpeg` output format must be an integer in [0, 100]"}
        end

      _ ->
        {:error, "`:quality` parameter for `:jpeg` output format must be an integer in [0, 100]"}
    end
  end

  defp validate_output_format_and_options(:pnm, options) do
    subtype = options[:subtype]

    if subtype in [:bitmap, :graymap, :pixmap, :arbitrarymap] do
      if subtype != :arbitarymap do
        encoding = options[:encoding]

        if encoding in [:binary, :ascii] do
          {:ok, %{"subtype" => to_string(subtype), "encoding" => to_string(encoding)}}
        else
          {:error,
           "`:encoding` parameter for output format `:pnm` with subtype `#{subtype}` must be either `:binary` or `:ascii`"}
        end
      else
        {:ok, %{"subtype" => to_string(subtype)}}
      end
    else
      {:error,
       "`:subtype` parameter for output format `:pnm` must exist and is one of `:bitmap`, `:graymap`, `:pixmap` or `:arbitrarymap`"}
    end
  end

  defp validate_output_format_and_options(format, _options) do
    supported_formats = supported_formats()

    if !(format in supported_formats) do
      {:error, "`:format` parameter must be one of #{inspect(supported_formats)}"}
    else
      {:ok, %{}}
    end
  end

  defp supported_formats do
    [
      :png,
      :jpeg,
      :pnm,
      :gif,
      :ico,
      :bmp,
      :farbfeld,
      :tga,
      :exr,
      :tiff,
      :avif,
      :qoi,
      :webp
    ]
  end

  if Code.ensure_loaded?(Nx) do
    @doc """
    Converts an `ImageRs` to a Nx tensor.

    It accepts the same options as `Nx.from_binary/3`.
    """
    def to_nx(%ImageRs{dtype: dtype, shape: shape} = image, opts \\ []) do
      with {:ok, data} <- ImageRs.to_binary(image) do
        Nx.from_binary(data, dtype, opts)
        |> Nx.reshape(List.to_tuple(shape), names: [:height, :width, :channels])
      end
    end

    @doc """
    Creates an `ImageRs` from a Nx tensor.

    The tensor is expected to have the shape `{h, w, c}`
    and one of the supported types (u8/u16/f32).
    """
    def from_nx(tensor) when is_struct(tensor, Nx.Tensor) do
      data = Nx.to_binary(tensor)
      dtype = tensor_type(Nx.type(tensor))

      {h, w, color_type} =
        case tensor_shape(Nx.shape(tensor)) do
          {h, w, c} ->
            {h, w, channel_to_image_rs_color_type(c)}

          {h, w} ->
            {h, w, :l}
        end

      new(h, w, color_type, dtype, data)
    end

    defp channel_to_image_rs_color_type(1) do
      :l
    end

    defp channel_to_image_rs_color_type(2) do
      :la
    end

    defp channel_to_image_rs_color_type(3) do
      :rgb
    end

    defp channel_to_image_rs_color_type(4) do
      :rgba
    end

    defp channel_to_image_rs_color_type(c) do
      raise RuntimeError, """
      Unsupported number of channels: `#{inspect(c)}`.
      Valid number of channels should be in [1,2,3,4].
      """
    end

    defp tensor_type({:u, 8}), do: :u8
    defp tensor_type({:u, 16}), do: :u16
    defp tensor_type({:f, 32}), do: :f32

    defp tensor_type(type),
      do: raise(ArgumentError, "unsupported tensor type: #{inspect(type)} (expected u8/u16/f32)")

    defp tensor_shape({_, _, c} = shape) when c in 1..4,
      do: shape

    defp tensor_shape(shape),
      do:
        raise(
          ArgumentError,
          "unsupported tensor shape: #{inspect(shape)} (expected height-width-channel)"
        )

    defimpl Nx.LazyContainer do
      def traverse(%ImageRs{dtype: dtype, shape: shape} = image, acc, fun) do
        fun.(Nx.template(List.to_tuple(shape), dtype), fn -> ImageRs.to_nx(image) end, acc)
      end
    end
  end

  if Code.ensure_loaded?(Kino.Render) do
    defimpl Kino.Render do
      defp within_maximum_size(image) do
        max_size = Application.fetch_env!(:image_rs, :kino_render_max_size)

        case max_size do
          {max_height, max_width} when is_integer(max_height) and is_integer(max_width) ->
            [h, w, _c] = image.shape
            h <= max_height and w <= max_width

          _ ->
            raise """
            invalid :kino_render_max_size configuration. Expected a 2-tuple, {height, width},
            where height and width are both integers. Got: #{inspect(max_size)}
            """
        end
      end

      def to_livebook(image) when is_struct(image, ImageRs) do
        render_types = Application.fetch_env!(:image_rs, :kino_render_tab_order)

        Enum.map(render_types, fn
          :raw ->
            {"Raw", Kino.Inspect.new(image)}

          :numerical ->
            if Code.ensure_loaded?(Nx) do
              {"Numerical", Kino.Inspect.new(ImageRs.to_nx(image))}
            else
              {"Numerical",
               Kino.Markdown.new("""
               The `Numerical` tab requires application `:nx`, please add `{:nx, "~> 0.4"}` to the dependency list.
               """)}
            end

          :image ->
            render_encoding = Application.fetch_env!(:image_rs, :kino_render_encoding)

            {image_format, kino_format} =
              case render_encoding do
                :jpg ->
                  {:jpg, :jpeg}

                :jpeg ->
                  {:jpg, :jpeg}

                :png ->
                  {:png, :png}

                _ ->
                  raise "invalid :kino_render_encoding configuration. Expected one of :png, :jpg, or :jpeg. Got: #{inspect(render_encoding)}"
              end

            with true <- within_maximum_size(image),
                 {:ok, encoded} <- ImageRs.encode_as(image, image_format),
                 true <- is_binary(encoded) do
              {"Image", Kino.Image.new(encoded, kino_format)}
            else
              _ ->
                nil
            end

          type ->
            raise """
            invalid :kino_render_tab_order configuration. The set of supported types are [:image, :raw, :numerical].
            Got: #{inspect(type)}
            """
        end)
        |> Enum.reject(&is_nil/1)
        |> to_livebook_tabs(render_types, image)
      end

      defp to_livebook_tabs([], [:image], image) do
        Kino.Layout.tabs([{"Raw", Kino.Inspect.new(image)}])
        |> Kino.Render.to_livebook()
      end

      defp to_livebook_tabs(_tabs, [], image) do
        Kino.Inspect.new(image)
        |> Kino.Render.to_livebook()
      end

      defp to_livebook_tabs(tabs, _types, _mat) do
        Kino.Layout.tabs(tabs)
        |> Kino.Render.to_livebook()
      end
    end
  end
end
