source 'https://rubygems.org'

gemspec

gem 'fastlane', :git => 'https://github.com/guardian/fastlane.git'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
