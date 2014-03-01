#require "bundler/gem_tasks"

task :default => [:cleanup, :build, :install]

task :cleanup do
	Dir.glob('*.gem') do |f|
		File.unlink(f) if File.file?(f)
	end
end

task :build do
	Dir.glob('*.gemspec') do |gem|
		system('gem', 'build', gem)
	end
end

task :install do
	Dir.glob('*.gem') do |gem|
		system('gem', 'install', gem, '--user-install')
	end
end
