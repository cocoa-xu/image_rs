use image::{imageops::FilterType, DynamicImage, ImageFormat};
use rustler::{NifStruct, NifTaggedEnum, ResourceArc};
use std::ops::Deref;

use crate::get_image_detail;

pub struct ImageRsDynamicImageRef(pub DynamicImage);

#[derive(NifTaggedEnum)]
pub enum ImageRsColorType {
    L,
    La,
    Rgb,
    Rgba,
    Unknown,
}

#[derive(NifTaggedEnum)]
pub enum ImageRsDataType {
    U8,
    U16,
    F32,
    Unknown,
}

#[derive(NifTaggedEnum)]
pub enum ImageRsFilterType {
    /// Nearest Neighbor
    Nearest,

    /// Linear Filter
    Triangle,

    /// Cubic Filter
    CatmullRom,

    /// Gaussian Filter
    Gaussian,

    /// Lanczos with window 3
    Lanczos3,
}

#[derive(NifTaggedEnum)]
pub enum ImageRsOutputFormat {
    Png,
    Jpeg,
    Pnm,
    Gif,
    Ico,
    Bmp,
    Farbfeld,
    Tga,
    Exr,
    Tiff,
    Avif,
    Qoi,
    Webp,
}

#[derive(NifStruct)]
#[module = "ImageRs"]
pub struct ImageRsDynamicImage {
    pub resource: ResourceArc<ImageRsDynamicImageRef>,
    pub width: u32,
    pub height: u32,
    pub color_type: ImageRsColorType,
    pub channels: u32,
    pub dtype: ImageRsDataType,
    pub shape: Vec<u32>,
}

impl ImageRsDynamicImageRef {
    pub fn new(image: DynamicImage) -> Self {
        Self(image)
    }
}

impl ImageRsDynamicImage {
    pub fn new(image: DynamicImage) -> Self {
        let ((height, width, channels), color_type, datatype) = get_image_detail(&image);
        Self {
            resource: ResourceArc::new(ImageRsDynamicImageRef::new(image)),
            width: width,
            height: height,
            color_type: color_type,
            channels: channels,
            dtype: datatype,
            shape: [height, width, channels].to_vec(),
        }
    }

    pub fn clone_inner(&self) -> DynamicImage {
        self.resource.0.clone()
    }
}

impl Deref for ImageRsDynamicImage {
    type Target = DynamicImage;

    fn deref(&self) -> &Self::Target {
        &self.resource.0
    }
}

impl Into<FilterType> for ImageRsFilterType {
    fn into(self) -> FilterType {
        match self {
            ImageRsFilterType::Nearest => FilterType::Nearest,
            ImageRsFilterType::Triangle => FilterType::Triangle,
            ImageRsFilterType::CatmullRom => FilterType::CatmullRom,
            ImageRsFilterType::Gaussian => FilterType::Gaussian,
            ImageRsFilterType::Lanczos3 => FilterType::Lanczos3,
        }
    }
}

impl Into<ImageFormat> for ImageRsOutputFormat {
    fn into(self) -> ImageFormat {
        match self {
            ImageRsOutputFormat::Png => ImageFormat::Png,
            ImageRsOutputFormat::Jpeg => ImageFormat::Jpeg,
            ImageRsOutputFormat::Pnm => ImageFormat::Pnm,
            ImageRsOutputFormat::Ico => ImageFormat::Ico,
            ImageRsOutputFormat::Bmp => ImageFormat::Bmp,
            ImageRsOutputFormat::Farbfeld => ImageFormat::Farbfeld,
            ImageRsOutputFormat::Tga => ImageFormat::Tga,
            ImageRsOutputFormat::Exr => ImageFormat::OpenExr,
            ImageRsOutputFormat::Tiff => ImageFormat::Tiff,
            ImageRsOutputFormat::Avif => ImageFormat::Avif,
            ImageRsOutputFormat::Qoi => ImageFormat::Qoi,
            ImageRsOutputFormat::Webp => ImageFormat::WebP,
            ImageRsOutputFormat::Gif => ImageFormat::Gif,
        }
    }
}
