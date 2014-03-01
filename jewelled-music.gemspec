# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jewelled/music/version'

Gem::Specification.new do |spec|
	spec.name = 'jewelled-music'
	spec.version = Jewelled::Music::VERSION
	spec.authors = ['Daniel Frank']
	spec.email = ['jewelled-music@danielfrank.net']
	spec.summary = %q{Organizes your music collection.}
	spec.description = %q{Organizes your music collection and is able to automatically manage a copy with lower bit rate.}
	spec.homepage = ''
	spec.license = 'CC-BY-SA'

	spec.files = `git ls-files -z`.split("\x0").reject { |file|
		# Skip all files that start with a .
		file.start_with?('.')
	}
	spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
	spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
	spec.require_paths = ['lib']

	spec.add_development_dependency 'bundler', '~> 1.5'
	#spec.add_development_dependency "rake"
end
