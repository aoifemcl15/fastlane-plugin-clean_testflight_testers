module Fastlane
  module Actions
    class CleanTestflightTestersAction < Action
      def self.run(params)
        require 'spaceship'

        app_identifier = params[:app_identifier]
        username = params[:username]
        oldestBuildNumber = params[:oldest_build_allowed].to_i
        days_of_inactivity = params[:days_of_inactivity]

        UI.message("Login to ASC API (#{username})")
        Spaceship::ConnectAPI.login(username)
        Spaceship::ConnectAPI.select_team
        UI.message("Login successful")

        UI.message("Fetching all TestFlight testers, this might take a few minutes, depending on the number of testers")

        # Convert from bundle identifier to app ID
        spaceship_app ||= Spaceship::ConnectAPI::App.find(app_identifier)
        UI.user_error!("Couldn't find app '#{app_identifier}' on the account of '#{username}' on iTunes Connect") unless spaceship_app

        all_testers = spaceship_app.get_beta_testers(limit: 200)
        counter = 0
        all_testers.each do |current_tester|

          # See https://docs.google.com/drawings/d/1IS1ce1RgnplzzGFjhwFWDhrIt52rAjie7gZPhLN8piE/edit?usp=sharing for a flow chart of the following logic

          installed_bundle_version = current_tester.installedCfBundleVersion

          # 1. Skip testers who already have a recent build
          if installed_bundle_version.to_i >= oldestBuildNumber
            next # tester is active, skip further checks
          end

          # 2. Remove testers with an old build installed
          if installed_bundle_version.to_i > 0 && installed_bundle_version.to_i < oldestBuildNumber
            remove_tester(current_tester, spaceship_app, params[:dry_run], "have an old build installed")
            counter += 1
            next
          end

          # 3. Remove testers based on inactivity
          if current_tester.last_modified_date
            time = Time.parse(current_tester.last_modified_date)
            days_since_status_change = (Time.now - time) / 60.0 / 60.0 / 24.0

            if days_since_status_change > days_of_inactivity
              # Distinguish between testers who never installed a build and general inactivity
              reason = current_tester.beta_tester_state == "INVITED" ? "never installed a build" : "have been inactive in the last #{days_of_inactivity} days"
              remove_tester(current_tester, spaceship_app, params[:dry_run], reason)
              counter += 1
              next
            end
          end
        end

      if params[:dry_run]
        UI.success("Didn't delete any testers, but instead only printed them out (#{counter}) disable `dry_run` to actually delete them 🦋")
      else
        UI.success("Successfully removed #{counter} testers 🦋")
      end
    end

      def self.remove_tester(tester, app, dry_run, reason)
        if dry_run
          UI.message("TestFlight tester #{tester.email} for app ID #{app.id} should be removed because they #{reason}")
        else
          UI.message("Removing tester #{tester.email} for app ID #{app.id} because they #{reason}")
          begin
            tester.delete_from_apps(apps: [app])
          rescue Spaceship::UnexpectedResponse => e
            if e.message.include?("The specified resource does not exist")
              UI.message("Ignoring 404 error: #{e.message}")
              # Some testers (presumambly those who are already in a Deleted state) will return a 404. This skips these users.
            else
              raise # Reraise if it's not a 404-related error
            end
          end
        end
      end

      def self.description
        "Automatically remove TestFlight testers that are not actually testing your app"
      end

      def self.authors
        ["KrauseFx"]
      end

      def self.details
        "Automatically remove TestFlight testers that are not actually testing your app"
      end

      def self.available_options
        user = CredentialsManager::AppfileConfig.try_fetch_value(:itunes_connect_id)
        user ||= CredentialsManager::AppfileConfig.try_fetch_value(:apple_id)

        [
          FastlaneCore::ConfigItem.new(key: :username,
                                     short_option: "-u",
                                     env_name: "CLEAN_TESTFLIGHT_TESTERS_USERNAME",
                                     description: "Your Apple ID Username",
                                     default_value: user),
          FastlaneCore::ConfigItem.new(key: :app_identifier,
                                       short_option: "-a",
                                       env_name: "CLEAN_TESTFLIGHT_TESTERS_APP_IDENTIFIER",
                                       description: "The bundle identifier of the app to upload or manage testers (optional)",
                                       optional: true,
                                       default_value: ENV["TESTFLIGHT_APP_IDENTITIFER"] || CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier)),
          FastlaneCore::ConfigItem.new(key: :team_id,
                                       short_option: "-q",
                                       env_name: "CLEAN_TESTFLIGHT_TESTERS_TEAM_ID",
                                       description: "The ID of your iTunes Connect team if you're in multiple teams",
                                       optional: true,
                                       is_string: false, # as we also allow integers, which we convert to strings anyway
                                       default_value: CredentialsManager::AppfileConfig.try_fetch_value(:itc_team_id),
                                       verify_block: proc do |value|
                                         ENV["FASTLANE_ITC_TEAM_ID"] = value.to_s
                                       end),
          FastlaneCore::ConfigItem.new(key: :team_name,
                                       short_option: "-r",
                                       env_name: "CLEAN_TESTFLIGHT_TESTERS_TEAM_NAME",
                                       description: "The name of your iTunes Connect team if you're in multiple teams",
                                       optional: true,
                                       default_value: CredentialsManager::AppfileConfig.try_fetch_value(:itc_team_name),
                                       verify_block: proc do |value|
                                         ENV["FASTLANE_ITC_TEAM_NAME"] = value.to_s
                                       end),
          FastlaneCore::ConfigItem.new(key: :days_of_inactivity,
                                     short_option: "-k",
                                     env_name: "CLEAN_TESTFLIGHT_TESTERS_WAIT_PROCESSING_INTERVAL",
                                     description: "Numbers of days a tester has to be inactive for (no build uses) for them to be removed",
                                     default_value: 30,
                                     type: Integer,
                                     verify_block: proc do |value|
                                       UI.user_error!("Please enter a valid positive number of days") unless value.to_i > 0
                                     end),
          FastlaneCore::ConfigItem.new(key: :oldest_build_allowed,
                                     short_option: "-b",
                                     env_name: "CLEAN_TESTFLIGHT_TESTERS_OLDEST_BUILD_ALLOWED",
                                     description: "Oldest build number allowed. All testers with older builds will be removed",
                                     optional: true,
                                     default_value: 0,
                                     type: Integer,
                                     verify_block: proc do |value|
                                       UI.user_error!("Please enter a valid build number") unless value.to_i >= 0
                                     end),
          FastlaneCore::ConfigItem.new(key: :dry_run,
                                     short_option: "-d",
                                     env_name: "CLEAN_TESTFLIGHT_TESTERS_DRY_RUN",
                                     description: "Only print inactive users, don't delete them",
                                     default_value: false,
                                     is_string: false)
        ]
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
