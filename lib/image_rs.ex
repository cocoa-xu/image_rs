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
  {:ok, image} = ImageRs.DynamicImage.from_file("/path/to/image")
  width = image.width
  height = image.height
  channels = image.channels
  shape = image.shape
  {^height, ^width, ^channels} = shape
  color_type = image.color_type
  type = image.type
  ```
  """
  @spec from_file(Path.t()) :: {:ok, ImageRs.DynamicImage.t()} | {:error, String.t()}
  def from_file(filename) do
    ImageRs.Nif.from_file(filename)
  end

  @doc """
  Decode image from buffer in memory

  - **data**. Image data in memory.

  ## Example
  ```elixir
  # image buffer from a file or perhaps download from the Internet
  {:ok, data} = File.read("/path/to/image")

  # decode the image from memory
  {:ok, image} = ImageRs.DynamicImage.from_binary(data)
  width = image.width
  height = image.height
  channels = image.channels
  shape = image.shape
  {^height, ^width, ^channels} = shape
  color_type = image.color_type
  type = image.type
  ```
  """
  @spec from_binary(binary()) :: {:ok, ImageRs.DynamicImage.t()} | {:error, String.t()}
  def from_binary(data) when is_binary(data) do
    ImageRs.Nif.from_binary(data)
  end

  @spec to_binary(ImageRs.DynamicImage.t()) :: {:ok, binary()} | {:error, String.t()}
  def to_binary(image) do
    ImageRs.Nif.to_binary(image)
  end

  @doc """
  Resize this image using the specified filter algorithm.

  Returns a new image. Does not preserve aspect ratio.

  `height` and `width` are the new image's dimensions.
  """
  @spec resize(
          ImageRs.DynamicImage.t(),
          non_neg_integer(),
          non_neg_integer(),
          :nearest | :triangle | :catmull_rom | :gaussian | :lanczos3
        ) :: {:ok, ImageRs.DynamicImage.t()} | {:error, String.t()}
  def resize(image, height, width, filter_type \\ :lanczos3) do
    ImageRs.Nif.resize(image, height, width, filter_type)
  end

  @doc """
  Resize this image using the specified filter algorithm.

  Returns a new image. The image's aspect ratio is preserved.

  The image is scaled to the maximum possible size that fits within the bounds specified by `width` and `height`.
  """
  @spec resize_preserve_ratio(
          ImageRs.DynamicImage.t(),
          non_neg_integer(),
          non_neg_integer(),
          :nearest | :triangle | :catmull_rom | :gaussian | :lanczos3
        ) :: {:ok, ImageRs.DynamicImage.t()} | {:error, String.t()}
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
          ImageRs.DynamicImage.t(),
          non_neg_integer(),
          non_neg_integer(),
          :nearest | :triangle | :catmull_rom | :gaussian | :lanczos3
        ) :: {:ok, ImageRs.DynamicImage.t()} | {:error, String.t()}
  def resize_to_fill(image, height, width, filter_type \\ :lanczos3) do
    ImageRs.Nif.resize_to_fill(image, height, width, filter_type)
  end

  @doc """
  Return a cut-out of this image delimited by the bounding rectangle.
  """
  @spec crop(
          ImageRs.DynamicImage.t(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer()
        ) :: {:ok, ImageRs.DynamicImage.t()} | {:error, String.t()}
  def crop(image, x, y, height, width) do
    ImageRs.Nif.crop(image, x, y, height, width)
  end

  @doc """
  Return a grayscale version of this image.

  Returns Luma images in most cases. However, for f32 images, this will return a grayscale Rgb/Rgba image instead.
  """
  @spec grayscale(ImageRs.DynamicImage.t()) ::
          {:ok, ImageRs.DynamicImage.t()} | {:error, String.t()}
  def grayscale(image) do
    ImageRs.Nif.grayscale(image)
  end

  @doc """
  Invert the colors of this image.
  """
  @spec invert(ImageRs.DynamicImage.t()) :: {:ok, ImageRs.DynamicImage.t()} | {:error, String.t()}
  def invert(image) do
    ImageRs.Nif.invert(image)
  end

  @doc """
  Performs a Gaussian blur on this image.

  `sigma` is a measure of how much to blur by.
  """
  @spec blur(ImageRs.DynamicImage.t(), float()) ::
          {:ok, ImageRs.DynamicImage.t()} | {:error, String.t()}
  def blur(image, sigma) do
    ImageRs.Nif.blur(image, sigma * 1.0)
  end

  @doc """
  Performs an unsharpen mask on this image.

  `sigma` is the amount to blur the image by.

  `threshold` is a control of how much to sharpen.
  """
  @spec unsharpen(ImageRs.DynamicImage.t(), float(), integer()) ::
          {:ok, ImageRs.DynamicImage.t()} | {:error, String.t()}
  def unsharpen(image, sigma, threshold) do
    ImageRs.Nif.unsharpen(image, sigma * 1.0, threshold)
  end

  @doc """
  Filters this image with the specified 3x3 kernel.
  """
  @spec filter3x3(
          ImageRs.DynamicImage.t(),
          [number()]
        ) ::
          {:ok, ImageRs.DynamicImage.t()} | {:error, String.t()}
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
  @spec adjust_contrast(ImageRs.DynamicImage.t(), float()) ::
          {:ok, ImageRs.DynamicImage.t()} | {:error, String.t()}
  def adjust_contrast(image, contrast) do
    ImageRs.Nif.adjust_contrast(image, contrast * 1.0)
  end

  @doc """
  Brighten the pixels of this image.

  `value` is the amount to brighten each pixel by.

  Negative values decrease the brightness and positive values increase it.
  """
  @spec brighten(ImageRs.DynamicImage.t(), integer()) ::
          {:ok, ImageRs.DynamicImage.t()} | {:error, String.t()}
  def brighten(image, value) do
    ImageRs.Nif.brighten(image, value)
  end

  @doc """
  Hue rotate the supplied image.

  `value` is the degrees to rotate each pixel by.

  0 and 360 do nothing, the rest rotates by the given degree value.

  just like the css webkit filter hue-rotate(180)
  """
  @spec huerotate(ImageRs.DynamicImage.t(), integer()) ::
          {:ok, ImageRs.DynamicImage.t()} | {:error, String.t()}
  def huerotate(image, value) do
    ImageRs.Nif.huerotate(image, value)
  end

  @doc """
  Flip this image vertically
  """
  @spec flipv(ImageRs.DynamicImage.t()) ::
          {:ok, ImageRs.DynamicImage.t()} | {:error, String.t()}
  def flipv(image) do
    ImageRs.Nif.flipv(image)
  end

  @doc """
  Flip this image horizontally
  """
  @spec fliph(ImageRs.DynamicImage.t()) ::
          {:ok, ImageRs.DynamicImage.t()} | {:error, String.t()}
  def fliph(image) do
    ImageRs.Nif.fliph(image)
  end

  @doc """
  Rotate this image 90 degrees clockwise.
  """
  @spec rotate90(ImageRs.DynamicImage.t()) ::
          {:ok, ImageRs.DynamicImage.t()} | {:error, String.t()}
  def rotate90(image) do
    ImageRs.Nif.rotate90(image)
  end

  @doc """
  Rotate this image 180 degrees clockwise.
  """
  @spec rotate180(ImageRs.DynamicImage.t()) ::
          {:ok, ImageRs.DynamicImage.t()} | {:error, String.t()}
  def rotate180(image) do
    ImageRs.Nif.rotate180(image)
  end

  @doc """
  Rotate this image 270 degrees clockwise.
  """
  @spec rotate270(ImageRs.DynamicImage.t()) ::
          {:ok, ImageRs.DynamicImage.t()} | {:error, String.t()}
  def rotate270(image) do
    ImageRs.Nif.rotate270(image)
  end

  @spec encode_as(any(), :jpeg | :pnm) :: {:error, binary()} | {:ok, any()}
  @doc """
  Encode this image as format.
  """
  @spec encode_as(ImageRs.DynamicImage.t(), output_format(), Keyword.t()) ::
          {:ok, ImageRs.DynamicImage.t()} | {:error, String.t()}
  def encode_as(image, format, options \\ []) do
    with {:ok, checked_options} <- validate_output_format_and_options(format, options) do
      ImageRs.Nif.encode_as(image, format, checked_options)
    end
  end

  @doc """
  Saves the buffer to a file at the path specified.
  """
  @spec save(ImageRs.DynamicImage.t(), Path.t()) ::
          {:ok, ImageRs.DynamicImage.t()} | {:error, String.t()}
  def save(image, path) do
    ImageRs.Nif.save(image, path)
  end

  @doc """
  Saves the buffer to a file at the path specified in the specified format.
  """
  @spec save_with_format(ImageRs.DynamicImage.t(), Path.t(), output_format()) ::
          {:ok, ImageRs.DynamicImage.t()} | {:error, String.t()}
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
        if (0 <= q and q <= 100) do
          {:ok, %{"quality" => "#{q}"}}
        else
          {:error, "`:quality` parameter for `:jpeg` output format must be an integer in [0, 100]"}
        end
      q when is_binary(q) ->
        case Integer.parse(q, 10) do
          {q, ""} ->
            if (0 <= q and q <= 100) do
              {:ok, %{"quality" => "#{q}"}}
            else
              {:error, "`:quality` parameter for `:jpeg` output format must be an integer in [0, 100]"}
            end
          :error ->
            {:error, "`:quality` parameter for `:jpeg` output format must be an integer in [0, 100]"}
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
end
