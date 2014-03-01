# Jewelled::Music

TODO: Write a gem description

A ruby gem that manages your music library.

Functions:
- Automatically moves files according to their tags
- Mirrors your library to a second directory, optionally reencoding your files with lower bit rate in a different format


## Installation

Install it as:

    $ gem install jewelled-music

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it ( http://github.com/<my-github-username>/jewelled-music/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Development

### Model

- One object per music track ("Track)
- One libav object that provides a queue for metadata scanning and converting
