source 'https://rubygems.org'

gemspec

gem 'fastlane', :path => '/Users/dana_dramowicz/code/fastlane-fork' 

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
