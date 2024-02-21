use crate::{
    ImageRsColorType, ImageRsDataType, ImageRsDynamicImage, ImageRsError, ImageRsFilterType,
    ImageRsOutputFormat,
};
use image::{ColorType, DynamicImage, ImageOutputFormat};
use rustler::{Binary, Env, NewBinary};
use std::collections::HashMap;
use std::io::{BufWriter, Cursor, Write};
use std::result::Result;
use std::result::Result::Ok;
use std::vec::Vec;

#[rustler::nif]
pub fn from_file(filename: &str) -> Result<ImageRsDynamicImage, ImageRsError> {
    Ok(ImageRsDynamicImage::new(image::open(filename)?))
}

#[rustler::nif]
fn from_binary(buffer: Binary) -> Result<ImageRsDynamicImage, ImageRsError> {
    Ok(ImageRsDynamicImage::new(image::load_from_memory(
        buffer.as_slice(),
    )?))
}

#[rustler::nif]
fn to_binary<'a>(env: Env<'a>, image: ImageRsDynamicImage) -> Result<Binary<'a>, ImageRsError> {
    let slice = image.as_bytes();
    let mut binary = NewBinary::new(env, slice.len());
    binary.as_mut_slice().write_all(slice)?;
    Ok(Binary::from(binary))
}

#[rustler::nif]
fn resize(
    image: ImageRsDynamicImage,
    height: u32,
    width: u32,
    filter: ImageRsFilterType,
) -> Result<ImageRsDynamicImage, ImageRsError> {
    Ok(ImageRsDynamicImage::new(image.resize_exact(
        width,
        height,
        filter.into(),
    )))
}

#[rustler::nif]
fn resize_preserve_ratio(
    image: ImageRsDynamicImage,
    height: u32,
    width: u32,
    filter: ImageRsFilterType,
) -> Result<ImageRsDynamicImage, ImageRsError> {
    Ok(ImageRsDynamicImage::new(image.resize(
        width,
        height,
        filter.into(),
    )))
}

#[rustler::nif]
fn resize_to_fill(
    image: ImageRsDynamicImage,
    height: u32,
    width: u32,
    filter: ImageRsFilterType,
) -> Result<ImageRsDynamicImage, ImageRsError> {
    Ok(ImageRsDynamicImage::new(image.resize_to_fill(
        width,
        height,
        filter.into(),
    )))
}

#[rustler::nif]
fn crop(
    image: ImageRsDynamicImage,
    x: u32,
    y: u32,
    height: u32,
    width: u32,
) -> Result<ImageRsDynamicImage, ImageRsError> {
    Ok(ImageRsDynamicImage::new(
        image.crop_imm(x, y, width, height),
    ))
}

#[rustler::nif]
fn grayscale(image: ImageRsDynamicImage) -> Result<ImageRsDynamicImage, ImageRsError> {
    Ok(ImageRsDynamicImage::new(image.grayscale()))
}

#[rustler::nif]
fn invert(image: ImageRsDynamicImage) -> Result<ImageRsDynamicImage, ImageRsError> {
    let mut new_image = image.clone();
    new_image.invert();
    Ok(ImageRsDynamicImage::new(new_image))
}

#[rustler::nif]
fn blur(image: ImageRsDynamicImage, sigma: f32) -> Result<ImageRsDynamicImage, ImageRsError> {
    Ok(ImageRsDynamicImage::new(image.blur(sigma)))
}

#[rustler::nif]
fn unsharpen(
    image: ImageRsDynamicImage,
    sigma: f32,
    threshold: i32,
) -> Result<ImageRsDynamicImage, ImageRsError> {
    Ok(ImageRsDynamicImage::new(image.unsharpen(sigma, threshold)))
}

#[rustler::nif]
fn filter3x3(
    image: ImageRsDynamicImage,
    kernel: Vec<f32>,
) -> Result<ImageRsDynamicImage, ImageRsError> {
    Ok(ImageRsDynamicImage::new(image.filter3x3(&kernel)))
}

#[rustler::nif]
fn adjust_contrast(
    image: ImageRsDynamicImage,
    c: f32,
) -> Result<ImageRsDynamicImage, ImageRsError> {
    Ok(ImageRsDynamicImage::new(image.adjust_contrast(c)))
}

#[rustler::nif]
fn brighten(image: ImageRsDynamicImage, value: i32) -> Result<ImageRsDynamicImage, ImageRsError> {
    Ok(ImageRsDynamicImage::new(image.brighten(value)))
}

#[rustler::nif]
fn huerotate(image: ImageRsDynamicImage, value: i32) -> Result<ImageRsDynamicImage, ImageRsError> {
    Ok(ImageRsDynamicImage::new(image.huerotate(value)))
}

#[rustler::nif]
fn flipv(image: ImageRsDynamicImage) -> Result<ImageRsDynamicImage, ImageRsError> {
    Ok(ImageRsDynamicImage::new(image.flipv()))
}

#[rustler::nif]
fn fliph(image: ImageRsDynamicImage) -> Result<ImageRsDynamicImage, ImageRsError> {
    Ok(ImageRsDynamicImage::new(image.fliph()))
}

#[rustler::nif]
fn rotate90(image: ImageRsDynamicImage) -> Result<ImageRsDynamicImage, ImageRsError> {
    Ok(ImageRsDynamicImage::new(image.rotate90()))
}

#[rustler::nif]
fn rotate180(image: ImageRsDynamicImage) -> Result<ImageRsDynamicImage, ImageRsError> {
    Ok(ImageRsDynamicImage::new(image.rotate180()))
}

#[rustler::nif]
fn rotate270(image: ImageRsDynamicImage) -> Result<ImageRsDynamicImage, ImageRsError> {
    Ok(ImageRsDynamicImage::new(image.rotate270()))
}

#[rustler::nif]
fn encode_as<'a>(
    env: Env<'a>,
    image: ImageRsDynamicImage,
    format: ImageRsOutputFormat,
    options: HashMap<String, String>,
) -> Result<Binary<'a>, ImageRsError> {
    let c = Cursor::new(Vec::new());
    let mut buffer = BufWriter::new(c);
    let output_format = into_output_format(format, &options)?;
    image.write_to(&mut buffer, output_format)?;

    let buf = buffer.buffer();
    let mut binary = NewBinary::new(env, buf.len());
    binary.as_mut_slice().write_all(buf)?;
    Ok(Binary::from(binary))
}

#[rustler::nif]
fn save(image: ImageRsDynamicImage, path: String) -> Result<(), ImageRsError> {
    Ok(image.save(path)?)
}

#[rustler::nif]
fn save_with_format(
    image: ImageRsDynamicImage,
    path: String,
    format: ImageRsOutputFormat,
) -> Result<(), ImageRsError> {
    Ok(image.save_with_format(path, format.into())?)
}

pub fn get_image_detail(
    image: &DynamicImage,
) -> ((u32, u32, u32), ImageRsColorType, ImageRsDataType) {
    let (channels, color, datatype) = match image.color() {
        ColorType::L8 => (1u32, ImageRsColorType::L, ImageRsDataType::U8),
        ColorType::La8 => (2u32, ImageRsColorType::La, ImageRsDataType::U8),
        ColorType::Rgb8 => (3u32, ImageRsColorType::Rgb, ImageRsDataType::U8),
        ColorType::Rgba8 => (4u32, ImageRsColorType::Rgba, ImageRsDataType::U8),
        ColorType::L16 => (1u32, ImageRsColorType::L, ImageRsDataType::U16),
        ColorType::La16 => (2u32, ImageRsColorType::La, ImageRsDataType::U16),
        ColorType::Rgb16 => (3u32, ImageRsColorType::Rgb, ImageRsDataType::U16),
        ColorType::Rgba16 => (4u32, ImageRsColorType::Rgba, ImageRsDataType::U16),
        ColorType::Rgb32F => (3u32, ImageRsColorType::Rgb, ImageRsDataType::F32),
        ColorType::Rgba32F => (4u32, ImageRsColorType::Rgba, ImageRsDataType::F32),
        _ => (0, ImageRsColorType::Unknown, ImageRsDataType::Unknown),
    };
    let width = image.width();
    let height = image.height();
    ((height, width, channels), color, datatype)
}

fn into_output_format(
    format: ImageRsOutputFormat,
    options: &HashMap<String, String>,
) -> Result<ImageOutputFormat, ImageRsError> {
    match format {
        #[cfg(feature = "png")]
        ImageRsOutputFormat::Png => Ok(ImageOutputFormat::Png),
        #[cfg(feature = "jpeg")]
        ImageRsOutputFormat::Jpeg => {
            if let Some(quality_string) = options.get("quality") {
                if let Ok(q) = quality_string.parse::<u8>() {
                    Ok(ImageOutputFormat::Jpeg(q))
                } else {
                    Err(ImageRsError::Other("bad argument".to_string()))
                }
            } else {
                Err(ImageRsError::Other("bad argument".to_string()))
            }
        }
        #[cfg(feature = "pnm")]
        ImageRsOutputFormat::Pnm => {
            if let Some(subtype) = options.get("subtype") {
                if ["bitmap", "graymap", "pixmap", "arbitrarymap"].contains(&&subtype[..]) {
                    if subtype == "arbitrarymap" {
                        Ok(ImageOutputFormat::Pnm(
                            image::codecs::pnm::PnmSubtype::ArbitraryMap,
                        ))
                    } else {
                        if let Some(encoding) = options.get("encoding") {
                            if ["binary", "ascii"].contains(&&encoding[..]) {
                                let encoding = if encoding == "binary" {
                                    image::codecs::pnm::SampleEncoding::Binary
                                } else {
                                    image::codecs::pnm::SampleEncoding::Ascii
                                };
                                if subtype == "bitmap" {
                                    Ok(ImageOutputFormat::Pnm(
                                        image::codecs::pnm::PnmSubtype::Bitmap(encoding),
                                    ))
                                } else if subtype == "graymap" {
                                    Ok(ImageOutputFormat::Pnm(
                                        image::codecs::pnm::PnmSubtype::Graymap(encoding),
                                    ))
                                } else {
                                    Ok(ImageOutputFormat::Pnm(
                                        image::codecs::pnm::PnmSubtype::Pixmap(encoding),
                                    ))
                                }
                            } else {
                                Err(ImageRsError::Other("bad argument".to_string()))
                            }
                        } else {
                            Err(ImageRsError::Other("bad argument".to_string()))
                        }
                    }
                } else {
                    Err(ImageRsError::Other("bad argument".to_string()))
                }
            } else {
                Err(ImageRsError::Other("bad argument".to_string()))
            }
        }
        #[cfg(feature = "gif")]
        ImageRsOutputFormat::Gif => Ok(ImageOutputFormat::Gif),
        #[cfg(feature = "ico")]
        ImageRsOutputFormat::Ico => Ok(ImageOutputFormat::Ico),
        #[cfg(feature = "bmp")]
        ImageRsOutputFormat::Bmp => Ok(ImageOutputFormat::Bmp),
        #[cfg(feature = "farbfeld")]
        ImageRsOutputFormat::Farbfeld => Ok(ImageOutputFormat::Farbfeld),
        #[cfg(feature = "tga")]
        ImageRsOutputFormat::Tga => Ok(ImageOutputFormat::Tga),
        #[cfg(feature = "exr")]
        ImageRsOutputFormat::Exr => Ok(ImageOutputFormat::OpenExr),
        #[cfg(feature = "tiff")]
        ImageRsOutputFormat::Tiff => Ok(ImageOutputFormat::Tiff),
        #[cfg(feature = "avif")]
        ImageRsOutputFormat::Avif => Ok(ImageOutputFormat::Avif),
        #[cfg(feature = "qoi")]
        ImageRsOutputFormat::Qoi => Ok(ImageOutputFormat::Qoi),
        #[cfg(feature = "webp")]
        ImageRsOutputFormat::Webp => Ok(ImageOutputFormat::WebP),
        _ => Err(ImageRsError::Other("Unsupported format".to_string())),
    }
}
