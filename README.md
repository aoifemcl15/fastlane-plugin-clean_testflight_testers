# clean_testflight_testers plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-clean_testflight_testers)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. Due to incompatiblity with the App Store Connect API specifically around beta tester metrics, this plugin has a dependency on a fork of a fork of the fastlane repo - [https://github.com/guardian/fastlane.git](https://github.com/guardian/fastlane.git). 

This is a fork of https://github.com/fastlane-community/fastlane-plugin-clean_testflight_testers and includes a couple of improvements: 
1. Ensures the plugin still runs if it encounters a tester with no available metrics
2. Uses the build version, instead of app version string for oldest build comparison
3. Uses new fields from the App Store Connect API to read beta teser metrics, eg. installed build - this is why the plugin requires https://github.com/Xjkstar/fastlane.git.
4. Ignores "The specified resource does not exist" errors from the API (presumambly related to users in an already Deleted state).

You can point to this version of the plugin by adding `gem 'fastlane-plugin-clean_testflight_testers', :git => 'https://github.com/aoifemcl15/fastlane-plugin-clean_testflight_testers'` to your PluginFile. 
Additionally, you will also need to add `gem "fastlane", :git => 'https://github.com/guardian/fastlane.git'` in your Gemfile. 

After making changes to this repo, ensure that you run `fastlane update_plugins` on any users of this plug-in.

## About clean_testflight_testers

![screenshot.png](screenshot.png)

> Automatically remove TestFlight testers that are not actually testing your app

Just add the following to your `fastlane/Fastfile`

```ruby
# Default setup
lane :clean do
  clean_testflight_testers
end

# This won't delete out inactive testers, but just print them
lane :clean do
  clean_testflight_testers(dry_run: true)
end

# Specify a custom number for what's "inactive"
lane :clean do
  clean_testflight_testers(days_of_inactivity: 120) # 120 days, so about 4 months
end

# Specify an oldest build number for what's "inactive"
lane :clean do
  clean_testflight_testers(oldest_build_number: 999) # users who are have got a build prior to 999 should be removed
end

# Provide custom app identifier / username
lane :clean do
  clean_testflight_testers(username: "apple@krausefx.com", app_identifier: "best.lane"")
end
```

The plugin will remove all testers that either:

- Received a TestFlight email, but didn't accept the invite within the last 30 days
- Installed the app within the last 30 days, but didn't launch it once

Unfortunately the iTunes Connect UI/API doesn't expose the timestamp of the last user session, so we can't really detect the last time someone used the app. The above rules will still help you, remove a big part of inactive testers. 

This plugin could also be smarter, and compare the time stamp of the last build, and compare it with the latest tester activity, feel free to submit a PR for this feature 👍

## Issues and Feedback

Make sure to update to the latest _fastlane_.

For any other issues and feedback about this plugin, please submit it to this repository.

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
