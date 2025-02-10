use rustler::{Env, Term};

mod datatypes;
mod image_rs;

pub use datatypes::{
    ImageRsColorType, ImageRsDataType, ImageRsDynamicImage, ImageRsDynamicImageRef,
    ImageRsFilterType, ImageRsOutputFormat,
};
pub use image_rs::*;

fn on_load(env: Env, _info: Term) -> bool {
    let _ = rustler::resource!(ImageRsDynamicImageRef, env);
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

rustler::init!("Elixir.ImageRs.Nif", load = on_load);
