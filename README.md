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
    -h, --help                       Prints this help
```

```shell
envoi-mig <path_to_media_file>
```


