# Audiobook divider

## Why

I like listening in my car to audiobooks or podcasts. But navigating on huge and long audio file is frustrating.
Especialy on mobile device when audiobook is 10 hours long...

This script will solve your problem.
It allows you to split and convert you media into list of mp3 files.

In other words, let say that you have some video file (Super-Cool.mp4)
This scirpt will divide this file into mp3 files (001_Super-Cool, 002_Super-Cool, ...)
Default duration of part is 120s. But you can change it using `-d` option (check Usage section).

## Requirements

You have to have
* ffmpeg on your machine
* bash (Mac OS or Linux)

## Features

* you can specify path to ffmpeg directory
* you can add image to all mp3 files
* you can specify duration (default 120s)
* you can specify genre (default: audiobok)
* you can specify author

## Usage
```
Usage: audiobook-divider.sh [-f path-to-ffmpeg-directory]
    [-i <image-location>] [-d <duration-in-seconds>]
    [-g <genre-default-audiobook>] [-a <author>]"
    your-media-file

    eg. $0 -f /bin -i screenshot.png -d 30 my-movie.webm
```

## Testing

Tested on
* Mac OS (Sierra)
* ffmpeg
```
fmpeg version 3.2.3 Copyright (c) 2000-2017 the FFmpeg developers
built with llvm-gcc 4.2.1 (LLVM build 2336.11.00)
```
* bash
```
GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin16)
Copyright (C) 2007 Free Software Foundation, Inc
```

## Licence

```
/*
 * ------------------------------------------------------------
 * "THE BEERWARE LICENSE" (Revision 42):
 * <author> wrote this code. As long as you retain this
 * notice, you can do whatever you want with this stuff. If we
 * meet someday, and you think this stuff is worth it, you can
 * buy me a beer in return.
 * ------------------------------------------------------------
 */
 ```
