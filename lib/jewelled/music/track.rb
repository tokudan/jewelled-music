require 'open3'

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
				# TODO: Maybe use a library for this.
				out = String.new
				Open3.popen3(%w(avconv avconv), '-i', @path) { |i, _, e, _|
					i.close
					out += e.read unless e.eof?
				}
				return unless out.include?('Metadata:')
				return unless out.include?('Duration:')
				# Now slice away everything but the metadata
				metadata_start = out.index('Metadata:')
				metadata_end = out.index('  Duration:')
				metadata = out[(metadata_start+10)..(metadata_end)]
				# And finally parse the metadata
				metadata.each_line { |line|
					begin
						line.chomp!
						field_end = line.index(':')
						field = line[1..(field_end-1)].strip
						continue unless field
						value = line[(field_end+2)..-1].strip
						continue unless value
						field.downcase!
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
				new_path += pattern.gsub(/<[^>]+>/) do | match |
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
