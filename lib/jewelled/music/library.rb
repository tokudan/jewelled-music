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
				organize_source if @organize
			end

			def organize_source
				@library.each_value { |track|
					Track.organize({:base_dir => @path, :pattern => @organize})
				}

				# Disable all following code as it will be moved to the Track class
				return nil

				# The regular expression used to parse a variable
				variable_reg_ex = /^<(?<variable>[^:]+)(:(?<spacer> |0)?(?<width>[0-9]+)?(=(?<default>.*))?)?>$/
				@library.each_pair { |path, track|
					# path contains a full path to a track. It should start with @path.
					# Sanity check
					raise unless path.start_with?(@path)
					raise unless track.class == Track
					# Cut off the library path
					path = path[(@path.length)..-1]
					path = path[1..-1] if path.start_with?('/')
					extension = File.extname(path)
					new_path = @organize.gsub(/<[^>]+>/) { |match|
						# Parse the variable and the options
						match_data = variable_reg_ex.match(match)
						raise "Error in pattern #{match}" unless match_data
						variable = match_data[:variable]
						default = "#{variable} unknown"
						default = match_data[:default] if match_data[:default]
						spacer = match_data[:spacer]
						# nil can be converted to integer without any problems
						width = match_data[:width].to_i
						# Make sure the spacer is a string instead of nil
						spacer = '' unless spacer
						value = track.info[variable]
						# If there is no information about the variable, return Unknown
						value = default if value == nil
						# Adjust the length...
						if width
							# first cut away
							value = value[0..(width-1)]
							# then prepend the spacer if not nil
							value = spacer + value while spacer.length > 0 and value.length < width
						end
						value
					}
					new_path += '' + extension
					if path != new_path
						full_path = "#{@path}/#{path}"
						new_full_path = "#{@path}/#{new_path}"
						$stderr.puts("Move: #{path} => #{new_path}")
						# If the preview option is not set...
						unless @preview
							# And the target file does not exist yet...
							unless File.exists?(new_full_path)
								# Make sure the target directory exists...
								target_dir = File.dirname(new_full_path)
								FileUtils.mkdir_p(target_dir)
								# Move the file
								FileUtils.move(full_path, new_full_path)
								# If the source directory is empty, remove it
								source_dir = File.dirname(full_path)
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