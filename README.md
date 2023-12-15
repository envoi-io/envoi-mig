# Envoi Media Information Gatherer

## Installation

### Prerequisites

#### MacOS

Install File Magic Dependencies 
```
brew install libmagic
```

Exiftool
```
brew install exiftool
```

FFMpeg
```
brew install ffmpeg
```

MediaInfo
```
brew install media-info
```

#### Other Operating Systems

Make sure that Ruby is installed and that the os-specific equivalent of the above packages are available 

## Install the Application

```
# Clone the Repo

# Install the Gem
```


## Usage

```shell
Usage: envoi-mig [options] media_file_path
    -l, --log-level LEVEL            Set log level (debug, info, warn, error, fatal)
                                     default: warn
        --exif-cmd-path PATH         Set Exif command file path
    -f, --ffprobe-cmd-path PATH      Set FFProbe command file path
    -m, --mediainfo-cmd-path PATH    Set MediaInfo command file path
    -e, --enable-modules x,y,z       Enable modules (exiftool, ffprobe, filemagic, mediainfo)
                                     default: exiftool, filemagic, ffprobe, mediainfo
        --[no-]log-to-console [stdout|stderr]
                                     Log to console
                                     default: stderr
    -L, --log-to-file DEST           File path to output log entries to.
    -o, --output-file PATH           Set output json file path
        --[no-]output-to-console     Output to console
                                     default: true
    -h, --help                       Prints this help
```

```shell
envoi-mig <path_to_media_file>
```


