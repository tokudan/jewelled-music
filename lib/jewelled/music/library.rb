module Jewelled
	module Music
		class Library
			attr_reader :organize, :path

			def initialize(path, options = Hash.new)
				@path = File.absolute_path(path)
				options.each_pair do |key, value|
					case key
						when :organize then
							@organize = value
						else
							raise
					end
				end
			end
		end
	end
end