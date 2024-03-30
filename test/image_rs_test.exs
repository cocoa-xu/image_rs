defmodule ImageRs.Test do
  use ExUnit.Case
  doctest ImageRs

  describe "decode image" do
    test "from png file" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.png"))
      assert 3 == image.width
      assert 2 == image.height
      assert 4 == image.channels
      assert :rgba == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 4] == image.shape

      assert {:ok,
              <<241, 145, 126, 255, 136, 190, 78, 255, 68, 122, 183, 255, 244, 196, 187, 255, 190,
                205, 145, 255, 144, 184, 200, 255>>} == ImageRs.to_binary(image)
    end

    test "from jpg file" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape
      # {:ok, data} = ImageRs.to_binary(image)

      # assert <<180, 128, 70, 148, 128, 78, 89, 134, 101, 222, 170, 112, 182, 162, 112, 112, 157,
      #          124>> == data
    end

    test "from png data" do
      {:ok, data} = File.read(Path.join(__DIR__, "test.png"))
      {:ok, %ImageRs{} = image} = ImageRs.from_binary(data)
      assert 3 == image.width
      assert 2 == image.height
      assert 4 == image.channels
      assert :rgba == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 4] == image.shape
      {:ok, data} = ImageRs.to_binary(image)

      assert <<241, 145, 126, 255, 136, 190, 78, 255, 68, 122, 183, 255, 244, 196, 187, 255, 190,
               205, 145, 255, 144, 184, 200, 255>> == data
    end

    test "from jpg data" do
      {:ok, data} = File.read(Path.join(__DIR__, "test.jpg"))
      {:ok, %ImageRs{} = image} = ImageRs.from_binary(data)
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape
      {:ok, _data} = ImageRs.to_binary(image)

      # assert <<180, 128, 70, 148, 128, 78, 89, 134, 101, 222, 170, 112, 182, 162, 112, 112, 157,
      #          124>> == data
    end

    test "to_binary with png" do
      {:ok, data} = File.read(Path.join(__DIR__, "test.png"))
      {:ok, %ImageRs{} = image} = ImageRs.from_binary(data)
      {:ok, data} = ImageRs.to_binary(image)

      assert <<241, 145, 126, 255, 136, 190, 78, 255, 68, 122, 183, 255, 244, 196, 187, 255, 190,
               205, 145, 255, 144, 184, 200, 255>> == data
    end

    test "to_binary with jpg" do
      {:ok, data} = File.read(Path.join(__DIR__, "test.jpg"))
      {:ok, %ImageRs{} = image} = ImageRs.from_binary(data)
      {:ok, _data} = ImageRs.to_binary(image)

      # assert <<180, 128, 70, 148, 128, 78, 89, 134, 101, 222, 170, 112, 182, 162, 112, 112, 157,
      #          124>> == data
    end
  end

  describe "interact with nx" do
    test "to_nx" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.png"))
      tensor = ImageRs.to_nx(image)

      assert {2, 3, 4} == tensor.shape
      assert {:u, 8} == tensor.type

      assert <<241, 145, 126, 255, 136, 190, 78, 255, 68, 122, 183, 255, 244, 196, 187, 255, 190,
               205, 145, 255, 144, 184, 200, 255>> == Nx.to_binary(tensor)
    end

    test "new image from nx" do
      data =
        <<241, 145, 126, 255, 136, 190, 78, 255, 68, 122, 183, 255, 244, 196, 187, 255, 190, 205,
          145, 255, 144, 184, 200, 255>>

      image_tensor =
        data
        |> Nx.from_binary(:u8)
        |> Nx.reshape({3, 2, 4})

      {:ok, %ImageRs{} = image} = ImageRs.from_nx(image_tensor)
      {:ok, image_data} = ImageRs.to_binary(image)
      assert data == image_data
    end

    test "new image from nx u16" do
      data =
        <<241, 145, 126, 255, 136, 190, 78, 255, 68, 122, 183, 255, 244, 196, 187, 255, 190, 205,
          145, 255, 144, 184, 200, 255>>

      image_tensor =
        data
        |> Nx.from_binary(:u8)
        |> Nx.reshape({3, 2, 4})
        |> Nx.as_type(:u16)

      {:ok, %ImageRs{} = image} = ImageRs.from_nx(image_tensor)
      {:ok, image_data} = ImageRs.to_binary(image)
      u16_data = Nx.to_binary(image_tensor)
      assert u16_data == image_data
    end

    test "new image from nx f32" do
      data =
        <<241, 145, 126, 255, 136, 190, 78, 255, 68, 122, 183, 255, 244, 196, 187, 255, 190, 205,
          145, 255, 144, 184, 200, 255>>

      image_tensor =
        data
        |> Nx.from_binary(:u8)
        |> Nx.reshape({3, 2, 4})
        |> Nx.as_type(:f32)

      {:ok, %ImageRs{} = image} = ImageRs.from_nx(image_tensor)
      {:ok, image_data} = ImageRs.to_binary(image)
      f32_data = Nx.to_binary(image_tensor)
      assert f32_data == image_data
    end

    invalid_dtypes = [{:f, 64}, {:u, 64}, {:s, 8}, {:s, 16}, {:s, 32}, {:s, 64}]

    for dtype <- invalid_dtypes do
      @dtype dtype
      test "new image from nx (invalid dtype - #{inspect(dtype)})" do
        data =
          <<241, 145, 126, 255, 136, 190, 78, 255, 68, 122, 183, 255, 244, 196, 187, 255, 190,
            205, 145, 255, 144, 184, 200, 255>>

        image_tensor =
          data
          |> Nx.from_binary(:u8)
          |> Nx.reshape({3, 2, 4})
          |> Nx.as_type(@dtype)

        assert_raise ArgumentError,
                     "unsupported tensor type: #{inspect(@dtype)} (expected u8/u16/f32)",
                     fn ->
                       ImageRs.from_nx(image_tensor)
                     end
      end
    end
  end

  describe "image resize ops" do
    test "preserve aspect ratio, nearest" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape

      new_height = 20
      new_width = 20

      {:ok, new_image} =
        ImageRs.resize_preserve_ratio(image, new_height, new_width, :nearest)

      assert 20 == new_image.width
      assert 13 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [13, 20, 3] == new_image.shape
    end

    test "preserve aspect ratio, triangle" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape

      new_height = 20
      new_width = 20

      {:ok, new_image} =
        ImageRs.resize_preserve_ratio(image, new_height, new_width, :triangle)

      assert 20 == new_image.width
      assert 13 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [13, 20, 3] == new_image.shape
    end

    test "preserve aspect ratio, catmull_rom" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape

      new_height = 20
      new_width = 20

      {:ok, new_image} =
        ImageRs.resize_preserve_ratio(image, new_height, new_width, :catmull_rom)

      assert 20 == new_image.width
      assert 13 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [13, 20, 3] == new_image.shape
    end

    test "preserve aspect ratio, gaussian" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape

      new_height = 20
      new_width = 20

      {:ok, new_image} =
        ImageRs.resize_preserve_ratio(image, new_height, new_width, :gaussian)

      assert 20 == new_image.width
      assert 13 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [13, 20, 3] == new_image.shape
    end

    test "preserve aspect ratio, lanczos3" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape

      new_height = 20
      new_width = 20

      {:ok, new_image} =
        ImageRs.resize_preserve_ratio(image, new_height, new_width, :lanczos3)

      assert 20 == new_image.width
      assert 13 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [13, 20, 3] == new_image.shape
    end

    test "not preserve aspect ratio, nearest" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape

      new_height = 20
      new_width = 20

      {:ok, new_image} = ImageRs.resize(image, new_height, new_width, :nearest)

      assert 20 == new_image.width
      assert 20 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [20, 20, 3] == new_image.shape
    end

    test "not preserve aspect ratio, triangle" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape

      new_height = 20
      new_width = 20

      {:ok, new_image} = ImageRs.resize(image, new_height, new_width, :triangle)

      assert 20 == new_image.width
      assert 20 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [20, 20, 3] == new_image.shape
    end

    test "not preserve aspect ratio, catmull_rom" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape

      new_height = 20
      new_width = 20

      {:ok, new_image} = ImageRs.resize(image, new_height, new_width, :catmull_rom)

      assert 20 == new_image.width
      assert 20 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [20, 20, 3] == new_image.shape
    end

    test "not preserve aspect ratio, gaussian" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape

      new_height = 20
      new_width = 20

      {:ok, new_image} = ImageRs.resize(image, new_height, new_width, :gaussian)

      assert 20 == new_image.width
      assert 20 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [20, 20, 3] == new_image.shape
    end

    test "not preserve aspect ratio, lanczos3" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape

      new_height = 20
      new_width = 20

      {:ok, new_image} = ImageRs.resize(image, new_height, new_width, :lanczos3)

      assert 20 == new_image.width
      assert 20 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [20, 20, 3] == new_image.shape
    end

    test "to fill, nearest" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape

      new_height = 20
      new_width = 20

      {:ok, new_image} =
        ImageRs.resize_to_fill(image, new_height, new_width, :nearest)

      assert 20 == new_image.width
      assert 20 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [20, 20, 3] == new_image.shape
    end

    test "to fill, triangle" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape

      new_height = 20
      new_width = 20

      {:ok, new_image} =
        ImageRs.resize_to_fill(image, new_height, new_width, :triangle)

      assert 20 == new_image.width
      assert 20 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [20, 20, 3] == new_image.shape
    end

    test "to fill, catmull_rom" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape

      new_height = 20
      new_width = 20

      {:ok, new_image} =
        ImageRs.resize_to_fill(image, new_height, new_width, :catmull_rom)

      assert 20 == new_image.width
      assert 20 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [20, 20, 3] == new_image.shape
    end

    test "to fill, gaussian" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape

      new_height = 20
      new_width = 20

      {:ok, new_image} =
        ImageRs.resize_to_fill(image, new_height, new_width, :gaussian)

      assert 20 == new_image.width
      assert 20 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [20, 20, 3] == new_image.shape
    end

    test "to fill, lanczos3" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape

      new_height = 20
      new_width = 20

      {:ok, new_image} =
        ImageRs.resize_to_fill(image, new_height, new_width, :lanczos3)

      assert 20 == new_image.width
      assert 20 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [20, 20, 3] == new_image.shape
    end
  end

  describe "image crop ops" do
    test "crop an image" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape

      x = 0
      y = 0
      height = 1
      width = 2
      {:ok, new_image} = ImageRs.crop(image, x, y, height, width)

      assert 2 == new_image.width
      assert 1 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [1, 2, 3] == new_image.shape
    end

    test "crop an image out of bounds" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape

      x = 0
      y = 0
      height = 4
      width = 4
      {:ok, new_image} = ImageRs.crop(image, x, y, height, width)

      assert 3 == new_image.width
      assert 2 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [2, 3, 3] == new_image.shape
    end
  end

  describe "other image ops" do
    test "grayscale" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape
      # {:ok, data} = ImageRs.to_binary(image)

      # assert <<180, 128, 70, 148, 128, 78, 89, 134, 101, 222, 170, 112, 182, 162, 112, 112, 157,
      #          124>> == data

      {:ok, new_image} = ImageRs.grayscale(image)
      assert 3 == new_image.width
      assert 2 == new_image.height
      assert 1 == new_image.channels
      assert :l == new_image.color_type
      assert :u8 == new_image.dtype
      assert [2, 3, 1] == new_image.shape
      # {:ok, data} = ImageRs.to_binary(new_image)
      # assert <<134, 128, 122, 176, 162, 145>> == data
    end

    test "invert" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape
      # {:ok, data} = ImageRs.to_binary(image)

      # assert <<180, 128, 70, 148, 128, 78, 89, 134, 101, 222, 170, 112, 182, 162, 112, 112, 157,
      #          124>> == data

      {:ok, new_image} = ImageRs.invert(image)
      assert 3 == new_image.width
      assert 2 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [2, 3, 3] == new_image.shape
      # {:ok, data} = ImageRs.to_binary(new_image)

      # assert <<75, 127, 185, 107, 127, 177, 166, 121, 154, 33, 85, 143, 73, 93, 143, 143, 98,
      #          131>> == data
    end

    test "blur" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape
      # {:ok, data} = ImageRs.to_binary(image)

      # assert <<180, 128, 70, 148, 128, 78, 89, 134, 101, 222, 170, 112, 182, 162, 112, 112, 157,
      #          124>> == data

      {:ok, new_image} = ImageRs.blur(image, 2.0)
      assert 3 == new_image.width
      assert 2 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [2, 3, 3] == new_image.shape
      # {:ok, data} = ImageRs.to_binary(new_image)

      # assert <<163, 146, 97, 155, 145, 98, 147, 145, 100, 165, 148, 99, 157, 147, 100, 149, 147,
      #          102>> == data
    end

    test "unsharpen" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape
      # {:ok, data} = ImageRs.to_binary(image)

      # assert <<180, 128, 70, 148, 128, 78, 89, 134, 101, 222, 170, 112, 182, 162, 112, 112, 157,
      #          124>> == data

      {:ok, new_image} = ImageRs.unsharpen(image, 2.0, 3)
      assert 3 == new_image.width
      assert 2 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [2, 3, 3] == new_image.shape
      # {:ok, data} = ImageRs.to_binary(new_image)

      # assert <<197, 110, 43, 141, 111, 58, 31, 123, 101, 255, 192, 125, 207, 177, 124, 75, 167,
      #          146>> == data
    end

    test "filter3x3" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape
      # {:ok, data} = ImageRs.to_binary(image)

      # assert <<180, 128, 70, 148, 128, 78, 89, 134, 101, 222, 170, 112, 182, 162, 112, 112, 157,
      #          124>> == data

      {:ok, new_image} = ImageRs.filter3x3(image, [[1, 2, 1], [1, 0, 1], [-1, 0, 1]])
      assert 3 == new_image.width
      assert 2 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [2, 3, 3] == new_image.shape
      # {:ok, data} = ImageRs.to_binary(new_image)

      # assert <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>> == data
    end

    test "adjust_contrast" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape
      # {:ok, data} = ImageRs.to_binary(image)

      # assert <<180, 128, 70, 148, 128, 78, 89, 134, 101, 222, 170, 112, 182, 162, 112, 112, 157,
      #          124>> == data

      {:ok, new_image} = ImageRs.adjust_contrast(image, 1)
      assert 3 == new_image.width
      assert 2 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [2, 3, 3] == new_image.shape
      # {:ok, data} = ImageRs.to_binary(new_image)

      # assert <<181, 128, 68, 148, 128, 77, 88, 134, 100, 223, 170, 111, 183, 162, 111, 111, 157,
      #          123>> == data
    end

    test "brighten" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape
      # {:ok, data} = ImageRs.to_binary(image)

      # assert <<180, 128, 70, 148, 128, 78, 89, 134, 101, 222, 170, 112, 182, 162, 112, 112, 157,
      #          124>> == data

      {:ok, new_image} = ImageRs.brighten(image, 10)
      assert 3 == new_image.width
      assert 2 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [2, 3, 3] == new_image.shape
      # {:ok, data} = ImageRs.to_binary(new_image)

      # assert <<190, 138, 80, 158, 138, 88, 99, 144, 111, 232, 180, 122, 192, 172, 122, 122, 167,
      #          134>> == data
    end

    test "huerotate" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape
      {:ok, _data} = ImageRs.to_binary(image)

      # assert <<180, 128, 70, 148, 128, 78, 89, 134, 101, 222, 170, 112, 182, 162, 112, 112, 157,
      #          124>> == data

      {:ok, new_image} = ImageRs.huerotate(image, 42)
      assert 3 == new_image.width
      assert 2 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [2, 3, 3] == new_image.shape
      # {:ok, data} = ImageRs.to_binary(new_image)

      # assert <<124, 145, 56, 109, 139, 78, 83, 132, 128, 166, 187, 98, 143, 173, 112, 106, 155,
      #          151>> == data
    end

    test "flipv" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape
      # {:ok, data} = ImageRs.to_binary(image)

      # assert <<180, 128, 70, 148, 128, 78, 89, 134, 101, 222, 170, 112, 182, 162, 112, 112, 157,
      #          124>> == data

      {:ok, new_image} = ImageRs.flipv(image)
      assert 3 == new_image.width
      assert 2 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [2, 3, 3] == new_image.shape
      # {:ok, data} = ImageRs.to_binary(new_image)

      # assert <<222, 170, 112, 182, 162, 112, 112, 157, 124, 180, 128, 70, 148, 128, 78, 89, 134,
      #          101>> == data
    end

    test "fliph" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape
      {:ok, _data} = ImageRs.to_binary(image)

      # assert <<180, 128, 70, 148, 128, 78, 89, 134, 101, 222, 170, 112, 182, 162, 112, 112, 157,
      #          124>> == data

      {:ok, new_image} = ImageRs.fliph(image)
      assert 3 == new_image.width
      assert 2 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [2, 3, 3] == new_image.shape
      # {:ok, data} = ImageRs.to_binary(new_image)

      # assert <<89, 134, 101, 148, 128, 78, 180, 128, 70, 112, 157, 124, 182, 162, 112, 222, 170,
      #          112>> == data
    end

    test "rotate90" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape
      # {:ok, data} = ImageRs.to_binary(image)

      # assert <<180, 128, 70, 148, 128, 78, 89, 134, 101, 222, 170, 112, 182, 162, 112, 112, 157,
      #          124>> == data

      {:ok, new_image} = ImageRs.rotate90(image)
      assert 2 == new_image.width
      assert 3 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [3, 2, 3] == new_image.shape
      # {:ok, data} = ImageRs.to_binary(new_image)

      # assert <<222, 170, 112, 180, 128, 70, 182, 162, 112, 148, 128, 78, 112, 157, 124, 89, 134,
      #          101>> == data
    end

    test "rotate180" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape
      # {:ok, data} = ImageRs.to_binary(image)

      # assert <<180, 128, 70, 148, 128, 78, 89, 134, 101, 222, 170, 112, 182, 162, 112, 112, 157,
      #          124>> == data

      {:ok, new_image} = ImageRs.rotate180(image)
      assert 3 == new_image.width
      assert 2 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [2, 3, 3] == new_image.shape
      # {:ok, data} = ImageRs.to_binary(new_image)

      # assert <<112, 157, 124, 182, 162, 112, 222, 170, 112, 89, 134, 101, 148, 128, 78, 180, 128,
      #          70>> == data
    end

    test "rotate270" do
      {:ok, %ImageRs{} = image} = ImageRs.from_file(Path.join(__DIR__, "test.jpg"))
      assert 3 == image.width
      assert 2 == image.height
      assert 3 == image.channels
      assert :rgb == image.color_type
      assert :u8 == image.dtype
      assert [2, 3, 3] == image.shape
      # {:ok, data} = ImageRs.to_binary(image)

      # assert <<180, 128, 70, 148, 128, 78, 89, 134, 101, 222, 170, 112, 182, 162, 112, 112, 157,
      #          124>> == data

      {:ok, new_image} = ImageRs.rotate270(image)
      assert 2 == new_image.width
      assert 3 == new_image.height
      assert 3 == new_image.channels
      assert :rgb == new_image.color_type
      assert :u8 == new_image.dtype
      assert [3, 2, 3] == new_image.shape
      # {:ok, data} = ImageRs.to_binary(new_image)

      # assert <<89, 134, 101, 112, 157, 124, 148, 128, 78, 182, 162, 112, 180, 128, 70, 222, 170,
      #          112>> == data
    end
  end
end
