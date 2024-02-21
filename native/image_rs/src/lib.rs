use rustler::{Env, Term};

mod datatypes;
mod error;
mod image_rs;

pub use datatypes::{
    ImageRsColorType, ImageRsDataType, ImageRsDynamicImage, ImageRsDynamicImageRef,
    ImageRsFilterType, ImageRsOutputFormat,
};
pub use error::ImageRsError;
pub use image_rs::*;

fn on_load(env: Env, _info: Term) -> bool {
    rustler::resource!(ImageRsDynamicImageRef, env);
    true
}

mod atoms {
    rustler::atoms! {
        l8,
        la8,
        rgb,
        rgba,
        u8,
        u16,
        f32,
        unknown,
    }
}

rustler::init!(
    "Elixir.ImageRs.Nif",
    [
        from_file,
        from_binary,
        to_binary,
        resize,
        resize_preserve_ratio,
        resize_to_fill,
        crop,
        grayscale,
        invert,
        blur,
        unsharpen,
        filter3x3,
        adjust_contrast,
        brighten,
        huerotate,
        flipv,
        fliph,
        rotate90,
        rotate180,
        rotate270,
        encode_as,
        save,
        save_with_format
    ],
    load = on_load
);
