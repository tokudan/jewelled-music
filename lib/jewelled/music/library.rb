require 'jewelled/music/track'
require 'fileutils'

module Jewelled
	module Music
		class Library
			attr_reader :path

			def initialize(path, options = Hash.new)
				# @path contains the absolute path to the root directory of the music library
				@path = File.absolute_path(path)
				# Remove trailing slashes
				@path = @path[0..-2] if @path[-1] == '/'
				# @library is a hash that will contain an entry for each track in the form of
				# "/absolute/path/to/file" => track
				# where track is the Jewelled::Music::Track object for that file
				@library = Hash.new
				options.each_pair do |key, value|
					case key
						when :organize then
							@organize = value
						when :preview then
							@preview = value
						else
							raise
					end
				end
				scan_files
			end

			def scan_files
				scan_directory(Dir.new(@path))
				organize_library if @organize
			end

			def organize_library
			@library.each_value { |track|
					track.organize({:base_dir => @path, :pattern => @organize, :preview => @preview})
				}
			end

			def scan_directory(directory)
				# scan_directory expects a Dir object or a string containing the full path
				directory = Dir.new(directory) if directory.class == String
				directory.each { |entry|
					next if entry == '.' or entry == '..'
					path = directory.path + '/' + entry
					case File.ftype(path)
						# Anything that's not a file or directory is ignored
						when 'file' then
							add_file(path)
						when 'directory' then
							scan_directory(Dir.new(path))
						else
							puts "Skipping #{path}"
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