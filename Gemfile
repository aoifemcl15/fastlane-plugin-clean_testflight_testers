source 'https://rubygems.org'

gemspec

gem 'fastlane', :git => 'https://github.com/Xjkstar/fastlane.git', ref: 'c2fbed42dbc8c4949d7080393662d59221e30491' 

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
