#!/usr/bin/env ruby
require 'jewelled/music'
require 'trollop'
opts = Trollop::options do
	opt :music,
	    'Root directory of the music library',
	    :type => :string
	opt :target,
	    'Sync music to target directory',
	    :type => :string
	opt :organize,
	    'Organize the music directory',
	    :type => :string
end
Trollop::die :music, 'Music library must be specified' if opts[:music] == nil

music_lib = Jewelled::Music::Library.new(opts[:music], {:organize => opts[:organize]})
p music_lib