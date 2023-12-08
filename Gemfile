source 'https://rubygems.org'

gemspec

gem 'fastlane', :git => 'https://github.com/Xjkstar/fastlane/tree/master'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
