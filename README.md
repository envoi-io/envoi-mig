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


### Manual

#### Clone the Repo

```shell
git clone https://github.com/envoi-io/envoi-mig.git
```

##### Create the link to the executable

```shell
ln -s `realpath exe/envoi-mig` /usr/local/bin/envoi-mig
```

## Usage

```shell
Usage: envoi-mig [options] media_file_path
        --exiftool-cmd-path PATH     Set Exiftool command file path
        --ffprobe-cmd-path PATH      Set FFProbe command file path
        --mediainfo-cmd-path PATH    Set MediaInfo command file path
    -e, --enable-modules x,y,z       Enable modules (exiftool, ffprobe, filemagic, mediainfo)
                                     default: exiftool, filemagic, ffprobe, mediainfo
    -l, --log-level LEVEL            Set log level (debug, info, warn, error, fatal)
                                     default: warn
        --[no-]log-to-console [stdout|stderr]
                                     Console device to output log entries to
                                     default: stderr
    -L, --log-to-file DEST           File path to output log entries to
    -o, --output-file PATH           Output the media information JSON file path
        --[no-]output-to-console     Output the media information JSON to the console
                                     default: true
    -h, --help                       Prints this help

```

```shell
envoi-mig <path_to_media_file>
```





