# FFmpeg

## Why not in the minimal template?

Adding FFmpeg adds build time and take some significant place in the build image, so as we usually add videos through external providers like Vimeo, FFmpeg is not included by default in the minimal template.

## Setup

- Add an `Aptfile` in the root directory with `ffmpeg` inside.
- Add the [APT buildpack] in the `.buildpacks` file, after Jemalloc. For example:
  ```TEXT
  https://github.com/Scalingo/jemalloc-buildpack.git
  https://github.com/Scalingo/apt-buildpack.git
  https://github.com/Scalingo/nodejs-buildpack.git
  https://github.com/Scalingo/ruby-buildpack.git
  ```
- Add the `LD_LIBRARY_PATH` environment variable in Scalingo with the following value:
  ```
  $LD_LIBRARY_PATH:/app/.apt/usr/lib/x86_64-linux-gnu/pulseaudio:/app/.apt/usr/lib/x86_64-linux-gnu/blas:/app/.apt/usr/lib/x86_64-linux-gnu/lapack
  ```
  *NOTE: No need to add it in development environment*
