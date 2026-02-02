use crate::{
    ImageRsColorType, ImageRsDataType, ImageRsDynamicImage, ImageRsFilterType, ImageRsOutputFormat,
};
use image::{ColorType, DynamicImage, ImageBuffer, ImageError};
use rustler::{Atom, Binary, Env, Error, NewBinary};
use std::collections::HashMap;
use std::io::ErrorKind as IoErrorKind;
use std::io::{BufWriter, Cursor, Seek, Write};
use std::vec::Vec;
mod atoms {
    rustler::atoms! {
        io,
        enoent,
        eacces,
        epipe,
        eexist,
        unknown,
        decoding_error,
        encoding_error,
        parameter_error,
        limit_error,
        dimension_mismatch,
        failed_already,
        no_more_data,
        invalid_image_data,
        dimension_error,
        insufficient_memory,
        unsupported_image_data,
        unsupported_color_type,
        unsupported_format,
        bad_argument,
    }
}

fn io_error_to_term(err: &ImageError) -> Atom {
    match err {
        ImageError::IoError(io_error) => match io_error.kind() {
            IoErrorKind::NotFound => atoms::enoent(),
            IoErrorKind::PermissionDenied => atoms::eacces(),
            IoErrorKind::BrokenPipe => atoms::epipe(),
            IoErrorKind::AlreadyExists => atoms::eexist(),
            _ => atoms::io(),
        },
        ImageError::Decoding(_) => atoms::decoding_error(),
        ImageError::Encoding(_) => atoms::encoding_error(),
        ImageError::Parameter(parameter_error) => match parameter_error.kind() {
            image::error::ParameterErrorKind::DimensionMismatch => atoms::dimension_mismatch(),
            image::error::ParameterErrorKind::FailedAlready => atoms::failed_already(),
            image::error::ParameterErrorKind::NoMoreData => atoms::no_more_data(),
            _ => atoms::parameter_error(),
        },
        ImageError::Limits(limit_error) => match limit_error.kind() {
            image::error::LimitErrorKind::DimensionError => atoms::dimension_error(),
            image::error::LimitErrorKind::InsufficientMemory => atoms::insufficient_memory(),
            _ => atoms::limit_error(),
        },
        ImageError::Unsupported(unsupported_error) => match unsupported_error.kind() {
            image::error::UnsupportedErrorKind::Color(_) => atoms::unsupported_color_type(),
            image::error::UnsupportedErrorKind::Format(_) => atoms::unsupported_format(),
            _ => atoms::unsupported_image_data(),
        },
    }
}

#[rustler::nif(schedule = "DirtyIo")]
pub fn from_file(filename: &str) -> Result<ImageRsDynamicImage, Error> {
    match image::open(filename) {
        Ok(image) => Ok(ImageRsDynamicImage::new(image)),
        Err(ref e) => Err(Error::Term(Box::new(io_error_to_term(e)))),
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn from_binary(buffer: Binary) -> Result<ImageRsDynamicImage, Error> {
    match image::load_from_memory(buffer.as_slice()) {
        Ok(image) => Ok(ImageRsDynamicImage::new(image)),
        Err(ref e) => Err(Error::Term(Box::new(io_error_to_term(e)))),
    }
}

fn as_u16_vec(image_bytes: &[u8], width: u32, height: u32, channels: u32) -> Option<Vec<u16>> {
    if width as usize * height as usize * channels as usize * 2 != image_bytes.len() {
        return None;
    }

    let image_data: Vec<u16> = vec![0; width as usize * height as usize * channels as usize];
    unsafe {
        std::ptr::copy_nonoverlapping(
            image_bytes.as_ptr(),
            image_data.as_ptr() as *mut u8,
            image_bytes.len(),
        );
    };
    Some(image_data)
}

fn as_f32_vec(image_bytes: &[u8], width: u32, height: u32, channels: u32) -> Option<Vec<f32>> {
    if width as usize * height as usize * channels as usize * 4 != image_bytes.len() {
        return None;
    }

    let image_data: Vec<f32> = vec![0f32; width as usize * height as usize * channels as usize];
    unsafe {
        std::ptr::copy_nonoverlapping(
            image_bytes.as_ptr(),
            image_data.as_ptr() as *mut u8,
            image_bytes.len(),
        );
    };
    Some(image_data)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn new<'a>(
    height: u32,
    width: u32,
    color_type: ImageRsColorType,
    data_type: ImageRsDataType,
    data: Binary<'a>,
) -> Result<ImageRsDynamicImage, Error> {
    let image_bytes = data.as_slice();
    let image = match color_type {
        ImageRsColorType::L => match data_type {
            ImageRsDataType::U8 => ImageBuffer::from_raw(width, height, image_bytes.to_vec())
                .map(|buf| DynamicImage::ImageLuma8(buf))
                .ok_or_else(|| Error::Term(Box::new(atoms::invalid_image_data()))),
            ImageRsDataType::U16 => {
                if let Some(image_data) = as_u16_vec(image_bytes, width, height, 1) {
                    ImageBuffer::from_raw(width, height, image_data)
                        .map(|buf| DynamicImage::ImageLuma16(buf))
                        .ok_or_else(|| Error::Term(Box::new(atoms::invalid_image_data())))
                } else {
                    return Err(Error::Term(Box::new(atoms::invalid_image_data())));
                }
            }
            _ => return Err(Error::Term(Box::new(atoms::unsupported_image_data()))),
        },
        ImageRsColorType::La => match data_type {
            ImageRsDataType::U8 => ImageBuffer::from_raw(width, height, image_bytes.to_vec())
                .map(|buf| DynamicImage::ImageLumaA8(buf))
                .ok_or_else(|| Error::Term(Box::new(atoms::invalid_image_data()))),
            ImageRsDataType::U16 => {
                if let Some(image_data) = as_u16_vec(image_bytes, width, height, 2) {
                    ImageBuffer::from_raw(width, height, image_data)
                        .map(|buf| DynamicImage::ImageLumaA16(buf))
                        .ok_or_else(|| Error::Term(Box::new(atoms::invalid_image_data())))
                } else {
                    return Err(Error::Term(Box::new(atoms::invalid_image_data())));
                }
            }
            _ => return Err(Error::Term(Box::new(atoms::unsupported_image_data()))),
        },
        ImageRsColorType::Rgb => match data_type {
            ImageRsDataType::U8 => ImageBuffer::from_raw(width, height, image_bytes.to_vec())
                .map(|buf| DynamicImage::ImageRgb8(buf))
                .ok_or_else(|| Error::Term(Box::new(atoms::invalid_image_data()))),
            ImageRsDataType::U16 => {
                if let Some(image_data) = as_u16_vec(image_bytes, width, height, 3) {
                    ImageBuffer::from_raw(width, height, image_data)
                        .map(|buf| DynamicImage::ImageRgb16(buf))
                        .ok_or_else(|| Error::Term(Box::new(atoms::invalid_image_data())))
                } else {
                    return Err(Error::Term(Box::new(atoms::invalid_image_data())));
                }
            }
            ImageRsDataType::F32 => {
                if let Some(image_data) = as_f32_vec(image_bytes, width, height, 3) {
                    ImageBuffer::from_raw(width, height, image_data)
                        .map(|buf| DynamicImage::ImageRgb32F(buf))
                        .ok_or_else(|| Error::Term(Box::new(atoms::invalid_image_data())))
                } else {
                    return Err(Error::Term(Box::new(atoms::invalid_image_data())));
                }
            }
            _ => return Err(Error::Term(Box::new(atoms::unsupported_image_data()))),
        },
        ImageRsColorType::Rgba => match data_type {
            ImageRsDataType::U8 => ImageBuffer::from_raw(width, height, image_bytes.to_vec())
                .map(|buf| DynamicImage::ImageRgba8(buf))
                .ok_or_else(|| Error::Term(Box::new(atoms::invalid_image_data()))),
            ImageRsDataType::U16 => {
                if let Some(image_data) = as_u16_vec(image_bytes, width, height, 4) {
                    ImageBuffer::from_raw(width, height, image_data)
                        .map(|buf| DynamicImage::ImageRgba16(buf))
                        .ok_or_else(|| Error::Term(Box::new(atoms::invalid_image_data())))
                } else {
                    return Err(Error::Term(Box::new(atoms::invalid_image_data())));
                }
            }
            ImageRsDataType::F32 => {
                if let Some(image_data) = as_f32_vec(image_bytes, width, height, 4) {
                    ImageBuffer::from_raw(width, height, image_data)
                        .map(|buf| DynamicImage::ImageRgba32F(buf))
                        .ok_or_else(|| Error::Term(Box::new(atoms::invalid_image_data())))
                } else {
                    return Err(Error::Term(Box::new(atoms::invalid_image_data())));
                }
            }
            _ => return Err(Error::Term(Box::new(atoms::unsupported_image_data()))),
        },
        _ => return Err(Error::Term(Box::new(atoms::unsupported_color_type()))),
    };

    match image {
        Ok(image) => Ok(ImageRsDynamicImage::new(image)),
        Err(e) => Err(e),
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn to_binary<'a>(env: Env<'a>, image: ImageRsDynamicImage) -> Result<Binary<'a>, Error> {
    let slice = image.as_bytes();
    let mut binary = NewBinary::new(env, slice.len());
    match binary.as_mut_slice().write_all(slice) {
        Ok(_) => Ok(Binary::from(binary)),
        Err(_) => Err(Error::Term(Box::new(atoms::io()))),
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn resize(
    image: ImageRsDynamicImage,
    height: u32,
    width: u32,
    filter: ImageRsFilterType,
) -> Result<ImageRsDynamicImage, Error> {
    Ok(ImageRsDynamicImage::new(image.resize_exact(
        width,
        height,
        filter.into(),
    )))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn resize_preserve_ratio(
    image: ImageRsDynamicImage,
    height: u32,
    width: u32,
    filter: ImageRsFilterType,
) -> Result<ImageRsDynamicImage, Error> {
    Ok(ImageRsDynamicImage::new(image.resize(
        width,
        height,
        filter.into(),
    )))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn resize_to_fill(
    image: ImageRsDynamicImage,
    height: u32,
    width: u32,
    filter: ImageRsFilterType,
) -> Result<ImageRsDynamicImage, Error> {
    Ok(ImageRsDynamicImage::new(image.resize_to_fill(
        width,
        height,
        filter.into(),
    )))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn crop(
    image: ImageRsDynamicImage,
    x: u32,
    y: u32,
    height: u32,
    width: u32,
) -> Result<ImageRsDynamicImage, Error> {
    Ok(ImageRsDynamicImage::new(
        image.crop_imm(x, y, width, height),
    ))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn grayscale(image: ImageRsDynamicImage) -> Result<ImageRsDynamicImage, Error> {
    Ok(ImageRsDynamicImage::new(image.grayscale()))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn invert(image: ImageRsDynamicImage) -> Result<ImageRsDynamicImage, Error> {
    let mut new_image = image.clone();
    new_image.invert();
    Ok(ImageRsDynamicImage::new(new_image))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn blur(image: ImageRsDynamicImage, sigma: f32) -> Result<ImageRsDynamicImage, Error> {
    Ok(ImageRsDynamicImage::new(image.blur(sigma)))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn unsharpen(
    image: ImageRsDynamicImage,
    sigma: f32,
    threshold: i32,
) -> Result<ImageRsDynamicImage, Error> {
    Ok(ImageRsDynamicImage::new(image.unsharpen(sigma, threshold)))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn filter3x3(image: ImageRsDynamicImage, kernel: Vec<f32>) -> Result<ImageRsDynamicImage, Error> {
    Ok(ImageRsDynamicImage::new(image.filter3x3(&kernel)))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn adjust_contrast(image: ImageRsDynamicImage, c: f32) -> Result<ImageRsDynamicImage, Error> {
    Ok(ImageRsDynamicImage::new(image.adjust_contrast(c)))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn brighten(image: ImageRsDynamicImage, value: i32) -> Result<ImageRsDynamicImage, Error> {
    Ok(ImageRsDynamicImage::new(image.brighten(value)))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn huerotate(image: ImageRsDynamicImage, value: i32) -> Result<ImageRsDynamicImage, Error> {
    Ok(ImageRsDynamicImage::new(image.huerotate(value)))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn flipv(image: ImageRsDynamicImage) -> Result<ImageRsDynamicImage, Error> {
    Ok(ImageRsDynamicImage::new(image.flipv()))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn fliph(image: ImageRsDynamicImage) -> Result<ImageRsDynamicImage, Error> {
    Ok(ImageRsDynamicImage::new(image.fliph()))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn rotate90(image: ImageRsDynamicImage) -> Result<ImageRsDynamicImage, Error> {
    Ok(ImageRsDynamicImage::new(image.rotate90()))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn rotate180(image: ImageRsDynamicImage) -> Result<ImageRsDynamicImage, Error> {
    Ok(ImageRsDynamicImage::new(image.rotate180()))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn rotate270(image: ImageRsDynamicImage) -> Result<ImageRsDynamicImage, Error> {
    Ok(ImageRsDynamicImage::new(image.rotate270()))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn encode_as<'a>(
    env: Env<'a>,
    image: ImageRsDynamicImage,
    format: ImageRsOutputFormat,
    options: HashMap<String, String>,
) -> Result<Binary<'a>, Error> {
    let c = Cursor::new(Vec::new());
    let mut buffer = BufWriter::new(c);
    into_output_format(&mut buffer, &image, format, &options)?;

    match buffer.seek(std::io::SeekFrom::Start(0)) {
        Ok(_) => {
            let cursor = buffer.get_ref();
            let bytes = cursor.get_ref();

            let mut binary = NewBinary::new(env, bytes.len());
            match binary.as_mut_slice().write_all(bytes) {
                Ok(_) => Ok(Binary::from(binary)),
                Err(_) => Err(Error::Term(Box::new(atoms::io()))),
            }
        }
        Err(_) => Err(Error::Term(Box::new(atoms::io()))),
    }
}

#[rustler::nif(schedule = "DirtyIo")]
fn save(image: ImageRsDynamicImage, path: String) -> Result<(), Error> {
    match image.save(path) {
        Ok(_) => Ok(()),
        Err(_) => Err(Error::Term(Box::new(atoms::io()))),
    }
}

#[rustler::nif(schedule = "DirtyIo")]
fn save_with_format(
    image: ImageRsDynamicImage,
    path: String,
    format: ImageRsOutputFormat,
) -> Result<(), Error> {
    match image.save_with_format(path, format.into()) {
        Ok(_) => Ok(()),
        Err(_) => Err(Error::Term(Box::new(atoms::io()))),
    }
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

use image::codecs::*;
use image::ImageEncoder;

fn into_output_format<W: std::io::Write + Seek>(
    buffered_write: &mut W,
    image: &ImageRsDynamicImage,
    format: ImageRsOutputFormat,
    options: &HashMap<String, String>,
) -> Result<(), Error> {
    let ((height, width, _channels), _color, _dtype) = get_image_detail(&image);
    let buf = image.as_bytes();
    let color = image.color();
    match format {
        #[cfg(feature = "png")]
        ImageRsOutputFormat::Png => {
            match png::PngEncoder::new(buffered_write).write_image(buf, width, height, color.into()) {
                Ok(_) => Ok(()),
                Err(_) => Err(Error::Term(Box::new(atoms::io()))),
            }
        }
        #[cfg(feature = "jpeg")]
        ImageRsOutputFormat::Jpeg => {
            if let Some(quality_string) = options.get("quality") {
                if let Ok(q) = quality_string.parse::<u8>() {
                    match jpeg::JpegEncoder::new_with_quality(buffered_write, q)
                        .write_image(buf, width, height, color.into())
                    {
                        Ok(_) => Ok(()),
                        Err(_) => Err(Error::Term(Box::new(atoms::io()))),
                    }
                } else {
                    Err(Error::Term(Box::new(atoms::bad_argument())))
                }
            } else {
                Err(Error::Term(Box::new(atoms::bad_argument())))
            }
        }
        #[cfg(feature = "pnm")]
        ImageRsOutputFormat::Pnm => {
            let subtype_result: Result<pnm::PnmSubtype, Error> = if let Some(subtype) = options.get("subtype") {
                if ["bitmap", "graymap", "pixmap", "arbitrarymap"].contains(&&subtype[..]) {
                    if subtype == "arbitrarymap" {
                        Ok(pnm::PnmSubtype::ArbitraryMap)
                    } else {
                        if let Some(encoding) = options.get("encoding") {
                            if ["binary", "ascii"].contains(&&encoding[..]) {
                                let encoding = if encoding == "binary" {
                                    pnm::SampleEncoding::Binary
                                } else {
                                    pnm::SampleEncoding::Ascii
                                };
                                if subtype == "bitmap" {
                                    Ok(pnm::PnmSubtype::Bitmap(encoding))
                                } else if subtype == "graymap" {
                                    Ok(pnm::PnmSubtype::Graymap(encoding))
                                } else {
                                    Ok(pnm::PnmSubtype::Pixmap(encoding))
                                }
                            } else {
                                Err(Error::Term(Box::new(atoms::bad_argument())))
                            }
                        } else {
                            Err(Error::Term(Box::new(atoms::bad_argument())))
                        }
                    }
                } else {
                    Err(Error::Term(Box::new(atoms::bad_argument())))
                }
            } else {
                Err(Error::Term(Box::new(atoms::bad_argument())))
            };
            if let Ok(subtype) = subtype_result {
                match pnm::PnmEncoder::new(buffered_write)
                    .with_subtype(subtype)
                    .write_image(buf, width, height, color.into())
                {
                    Ok(_) => Ok(()),
                    Err(_) => Err(Error::Term(Box::new(atoms::io()))),
                }
            } else {
                Err(Error::Term(Box::new(atoms::bad_argument())))
            }
        }
        #[cfg(feature = "gif")]
        ImageRsOutputFormat::Gif => {
            match gif::GifEncoder::new(buffered_write).encode(buf, width, height, color.into()) {
                Ok(_) => Ok(()),
                Err(_) => Err(Error::Term(Box::new(atoms::io()))),
            }
        }
        #[cfg(feature = "ico")]
        ImageRsOutputFormat::Ico => {
            match ico::IcoEncoder::new(buffered_write).write_image(buf, width, height, color.into()) {
                Ok(_) => Ok(()),
                Err(_) => Err(Error::Term(Box::new(atoms::io()))),
            }
        }
        #[cfg(feature = "bmp")]
        ImageRsOutputFormat::Bmp => {
            match bmp::BmpEncoder::new(buffered_write).write_image(buf, width, height, color.into()) {
                Ok(_) => Ok(()),
                Err(_) => Err(Error::Term(Box::new(atoms::io()))),
            }
        }
        #[cfg(feature = "tga")]
        ImageRsOutputFormat::Tga => {
            match tga::TgaEncoder::new(buffered_write).write_image(buf, width, height, color.into()) {
                Ok(_) => Ok(()),
                Err(_) => Err(Error::Term(Box::new(atoms::io()))),
            }
        }
        #[cfg(feature = "tiff")]
        ImageRsOutputFormat::Tiff => {
            match tiff::TiffEncoder::new(buffered_write).write_image(buf, width, height, color.into()) {
                Ok(_) => Ok(()),
                Err(_) => Err(Error::Term(Box::new(atoms::io()))),
            }
        }
        #[cfg(feature = "avif")]
        ImageRsOutputFormat::Avif => {
            match avif::AvifEncoder::new(buffered_write).write_image(buf, width, height, color.into()) {
                Ok(_) => Ok(()),
                Err(_) => Err(Error::Term(Box::new(atoms::io()))),
            }
        }
        #[cfg(feature = "qoi")]
        ImageRsOutputFormat::Qoi => {
            match qoi::QoiEncoder::new(buffered_write).write_image(buf, width, height, color.into()) {
                Ok(_) => Ok(()),
                Err(_) => Err(Error::Term(Box::new(atoms::io()))),
            }
        }
        #[cfg(feature = "webp")]
        ImageRsOutputFormat::Webp => {
            match webp::WebPEncoder::new_lossless(buffered_write)
                .write_image(buf, width, height, color.into())
            {
                Ok(_) => Ok(()),
                Err(_) => Err(Error::Term(Box::new(atoms::io()))),
            }?;
            Ok(())
        }
        _ => Err(Error::Term(Box::new(atoms::unsupported_format()))),
    }
}
