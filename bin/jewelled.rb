#!/usr/bin/env ruby
require 'jewelled/music'
require 'trollop'
opts = Trollop::options do
	banner <<-EOS
Jewelled music organizes your music library and creates a mirror that contains lower bitrate files.
	EOS
	opt :music,
	    'Root directory of the music library',
	    :type => :string
	opt :preview,
	    'Only show a preview of what would have been done, do not move files or convert them.'
	opt :target,
	    'Sync music to target directory',
	    :type => :string
	opt :organize,
	    'Organize the target directory',
	    :type => :string
	opt ('organize-source'.to_sym),
	    'Organize the music directory'
	banner <<-EOS
This option expects a string that will be used to build the target path for each file.
It should contain variables that will be replaced by the information read from the tags of each file.
Example: --organize "<album_artist>/<album>/<disc:02>-<track:03> <title>"
Common variables that can be found in music files:
album, album_artist, artist, date, disc, genre, title, track
Special formatting options (must appear in the order they are shown here):
<number>    Force that variable to a specific length. If the number starts with a zero, the variable will be considered
			padded with zeros in front, if necessary. If there is a space in front of the number, it will be padded with
			spaces instead.
=abc        Uses the value of the variable, but if that variable is not defined, use "abc"
Example: <track:03=1>
This will insert the variable track. If it is not set, the value 1 will be used. Additionally, the variable is padded
in the front with zeroes until it reaches a length of 3 characters.
	EOS
end
Trollop::die :music, 'Music library must be specified' if opts[:music] == nil

music_lib = Jewelled::Music::Library.new(opts[:music], {:organize => opts[:organize], :preview => opts[:preview]})
music_lib.organize_source
