#!/usr/bin/env ruby
require 'fileutils'
require 'open3'
require 'trollop'

module Jewelled
	module Music
		class Track
			# TODO: Write a decent interface for @info
			attr_reader :info, :valid

			def initialize(file)
				@path = File.absolute_path(file)
				@info = nil
				read_metadata
				# Valid confirms that this track actually is valid in the sense that it contains
				# music, metadata is readable, etc.
				# TODO: implement some sanity checks
				@valid = true
			end

			def read_metadata
				@info = Hash.new
				# TODO: Maybe use a library instead of spawning a process for each file.
				metadata = String.new
				Open3.popen3(%w(avconv avconv), '-i', @path, '-f', 'ffmetadata', '-') { |i, o, _, _|
					i.close
					metadata += o.read unless o.eof?
				}
				return unless metadata.start_with?(';FFMETADATA1')
				# And finally parse the metadata
				metadata.each_line { |line|
					begin
						line.chomp!
						a_line = line.split('=')
						field = a_line[0].to_s.strip
						field.downcase!
						continue unless field
						value = a_line[1].to_s.strip
						continue unless value
						@info[field] = value
					rescue
						nil
					end
				}
			end

			def organize(options)
				base_dir = options[:base_dir]
				pattern = options[:pattern]
				preview = options[:preview]

				# The regular expression used to parse a variable
				variable_reg_ex = /^<(?<variable>[^:]+)(:(?<spacer> |0)?(?<width>[0-9]+)?(=(?<default>.*))?)?>$/

				# @path contains the full path to the track. It should start with base_dir.
				# Sanity check
				raise unless @path.start_with?(base_dir)

				# Get the file extension
				extension = File.extname(@path)

				# Calculate the new path
				new_path = base_dir + '/'
				new_path += pattern.gsub(/<[^>]+>/) do |match|
					# Parse the variable and the options
					match_data = variable_reg_ex.match(match)
					# Raise an error if the variable seems to be malformed
					raise "Error in pattern #{match}" unless match_data
					variable = match_data[:variable]
					default = "#{variable} unknown"
					default = match_data[:default] if match_data[:default]
					spacer = match_data[:spacer]
					# nil can be converted to integer without any problems
					width = match_data[:width].to_i
					# Make sure the spacer is a string instead of nil
					spacer = '' unless spacer
					value = @info[variable]
					# If there is no information about the variable, return default value
					value = default if value == nil
					# Adjust the length...
					if width
						# first cut away
						value = value[0..(width-1)]
						# then prepend the spacer if not nil
						value = spacer + value while spacer.length > 0 and value.length < width
					end
					value
				end

				# Append the file extension
				new_path += '' + extension

				# Check if the track needs to be moved
				if @path != new_path
					$stderr.puts("Move: #{@path} => #{new_path}")
					old_path = @path
					# If the preview option is not set...
					unless preview
						# And the target file does not exist yet...
						unless File.exists?(new_path)
							# Make sure the target directory exists...
							target_dir = File.dirname(new_path)
							FileUtils.mkdir_p(target_dir)
							# Move the file
							FileUtils.move(old_path, new_path)
							# Update the current path of the track
							@path = new_path
							# If the source directory is empty, remove it
							source_dir = File.dirname(old_path)
							begin
								while true
									# Dir.unlink will only remove empty directories and raises an exception
									# when used on a non-empty directory, which is perfect for
									# breaking out of the endless loop.
									Dir.unlink(source_dir)
									source_dir = File.dirname(source_dir)
								end
							rescue
								# No action necessary, reaching this rescue is expected.
							end
						end
					end
				end
			end
		end
	end
end

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
Example: --organize "<album_artist>/<album=Unknown>/<disc:02>-<track:03> <title>"
Common variables that can be found in music files:
album, album_artist, artist, date, disc, genre, title, track
Special formatting options (must appear in the order they are shown here):
:<number>
Force that variable to a specific length. If the number starts with a zero, the variable will be considered padded with zeros in front, if necessary. If there is a space in front of the number, it will be padded with spaces instead. If the number starts neither with a zero or space, the variable will not be padded if it is too short.
=abc
Uses the value of the variable, but if that variable is not defined, use "abc".
Example: <track:03=1>
This will insert the variable track. If it is not set, the value 1 will be used. Additionally, the variable is padded
in the front with zeroes until it reaches a length of 3 characters.
	EOS
end
Trollop::die :music, 'Music library must be specified' if opts[:music] == nil

Jewelled::Music::Library.new(opts[:music], {:organize => opts[:organize], :preview => opts[:preview]})
