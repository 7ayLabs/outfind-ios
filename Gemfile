# Outfind iOS Gemfile
# Manages Ruby dependencies for Fastlane

source "https://rubygems.org"

# Fastlane for iOS automation
gem "fastlane", "~> 2.219"

# Plugins
plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
