require 'jewelled/music/track'

module Jewelled
	module Music
		class Library
			attr_reader :path

			def initialize(path, options = Hash.new)
				# @path contains the absolute path to the root directory of the music library
				@path = File.absolute_path(path)
				# @library is a hash that will contain an entry for each track in the form of
				# "/absolute/path/to/file" => track
				# where track is the Jewelled::Music::Track object for that file
				@library = Hash.new
				options.each_pair do |key, value|
					case key
						when :organize then
							@organize = value
						else
							raise
					end
				end
				scan_files
			end

			def scan_files
				scan_directory(Dir.new(@path))
				organize if @organize
			end

			def organize
				@library.each_pair { |path, track|
					# path contains a full path to a track. It should start with @path.
					# Sanity check
					raise unless path.start_with?(@path)

					# /<[^>]+>/
				}
			end

			def scan_directory(directory)
				# scan_directory expects a Dir object or a string containing the full path
				directory = Dir.new(directory) if directory.class == String
				directory.each { |entry|
					next if entry == '.' or entry == '..'
					p path = directory.path + '/' + entry
					case File.ftype(path)
						# Anything that's not a file or directory is ignored
						when 'file' then
							add_file(path)
						when 'directory' then
							scan_directory(Dir.new(path))
						else
							nil
					end
				}
				directory.close
			end

			def add_file(path)
				track = Jewelled::Music::Track.new(path)
				@library[path] = track if track.valid
			end
		end
	end
end