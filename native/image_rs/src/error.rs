use image::ImageError;
use rustler::{Encoder, Env, Term};
use thiserror::Error;

rustler::atoms! {
    io,
    image,
    other,
}

#[derive(Error, Debug)]
pub enum ImageRsError {
    #[error("Io Error: {0}")]
    Io(#[from] std::io::Error),
    #[error("Image Error: {0}")]
    Image(#[from] ImageError),
    #[error("Generic Error: {0}")]
    Other(String),
    #[error(transparent)]
    Unknown(#[from] anyhow::Error),
}

impl Encoder for ImageRsError {
    fn encode<'b>(&self, env: Env<'b>) -> Term<'b> {
        format!("{self}").encode(env)
    }
}
