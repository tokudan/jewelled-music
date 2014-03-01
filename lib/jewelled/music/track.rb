require 'open3'

module Jewelled
	module Music
		class Track
			attr_reader :info

			def initialize(file)
				@path = File.absolute_path(file)
				@info = nil
				read_metadata
			end

			def read_metadata
				# TODO: Maybe use a library for this.
				out = String.new
				Open3.popen3(%w(avconv avconv), '-i', @path) { |i, _, e, _|
					i.close
					out += e.read unless e.eof?
				}
				# Now slice away everything but the metadata
				metadata_start = out.index('Metadata:')
				metadata_end = out.index('  Duration:')
				metadata = out[(metadata_start+10)..(metadata_end)]
				# And finally parse the metadata
				info = Hash.new
				metadata.each_line { |line|
					begin
						line.chomp!
						field_end = line.index(':')
						field = line[1..(field_end-1)].strip
						continue unless field
						value = line[(field_end+2)..-1].strip
						continue unless value
						field.downcase!
						info[field] = value
					rescue
						nil
					end
				}
				@info = info
			end
		end
	end
end
