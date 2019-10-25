
require_relative './mac_os.rb'
require_relative './bottle.rb'

module HomebrewAutomation

  # Imperative glue code.
  #
  # Each method in this class probably makes sense to be exposed as a CLI command.
  class Workflow

    # Build and upload a bottle.
    #
    # The built Bottle tarball gets uploaded to Bintray.
    #
    # @param sdist [SourceDist]
    # @param tap [Tap]
    # @param formula_name [String] the name of the formula in the Tap
    # @param bversion [Bintray::Version]
    # @param logger [HomebrewAutomation::Logger]
    #
    # @param mac_os [Class] the MacOS class
    # @param bottle [Class] the Bottle class
    # @param keep_homebrew_tmp [Boolean] keep the HOMEBREW_TEMP directory
    #
    # @return [Bottle]
    def build_and_upload_bottle!(
        sdist,
        tap,
        git,
        formula_name,
        bversion,
        logger,
        mac_os: MacOS,
        bottle: Bottle,
        keep_tap_repo: false,
        keep_homebrew_tmp: false)
      logger.info!(
        "Hello, this is HomebrewAutomation! I will now build your Formula and upload the " \
        "bottles to Bintray.")
      os_name = mac_os.identify_version!
      logger.info!("First let's clone your Tap repo to see the Formula.")
      git.with_clone!(tap.url, tap.repo, keep_dir: keep_tap_repo) do |cloned_dir|
        tap.on_formula! formula_name do |formula|
          formula.put_sdist(sdist.url, sdist.sha256)
        end
        git.commit_am! "Throwaway commit; just for building bottles"
        logger.info!(
          "I've updated the Formula file in our local Tap clone, and we're ready "\
          "to start building the Bottle. This could take a long time if your Formula "\
          "is slow to compile.")
        bot = bottle.new(
          'homebrew-automation/tmp-tap',
          cloned_dir,
          formula_name,
          os_name,
          keep_tmp: keep_homebrew_tmp)
        bot.build! do |filename, contents|
          # Bintray auto-creates Versions on file-upload.
          # Re-creating an existing Version results in a 409.
          #bversion.create!
          logger.info!("Bottle built! Let me now upload the Bottle tarball to Bintray.")
          begin
            bversion.upload_file!(filename, contents)
          rescue Bintray::Version::FileAlreadyExists
            logger.info!("A file with the same name as the one we're uploading already exits on Bintray.")
          end
        end
        bot
      end
      logger.info!("All done!")
    rescue HomebrewAutomation::Bottle::Error => e
      logger.error!([
        "Something went wrong in a Bottle: " + e.message,
        "Original JSON:",
        e.original,
        "Backtrace:",
        e.backtrace.join("\n")
      ].join("\n"))
    rescue HomebrewAutomation::Bottle::OlderVersionAlreadyInstalled => e
      logger.error!([
        "An older version of the Formula is already installed on your system. " \
        "Please either manually uninstall or upgrade it, then try again.",
        e.to_s,
        "Caused by: #{e.cause}",
        (e.cause ? e.cause.backtrace.join("\n") : '')
      ].join("\n"))
    rescue HomebrewAutomation::Brew::Error => e
      logger.error!(
        "Something went wrong in this Homebrew command: " +
        e.message + "\n" + e.backtrace.join("\n"))
    rescue HomebrewAutomation::Git::Error => e
      logger.error!(
        "Something went wrong in this Git command: " +
        e.message + "\n" + e.backtrace.join("\n"))
    end

    # Gather and publish bottles.
    #
    # Look around on Bintray to see what Bottles we've already built and
    # uploaded (as such "gathering" the bottles), then push new commits into
    # the {#tap} repository to make an existing Formula aware of the Bottles
    # we're gathered (as such "publishing" the bottles).
    #
    # @param sdist [SourceDist]
    # @param tap [Tap]
    # @param formula_name [String] the name of the formula in the Tap
    # @param bversion [Bintray::Version]
    # @param logger [HomebrewAutomation::Logger]
    # @return [NilClass]
    def gather_and_publish_bottles!(sdist, tap, formula_name, bversion, logger)
      logger.info!(
        "Hello, this is HomebrewAutomation! I will browse through your Bintray to " \
        "see if there may be Bottles built earlier for your Formula, and update your " \
        "Tap to refer to them.")
      logger.info!(
        "I will also update the source tarball of your Formula in your Tap, " \
        "effectively releasing a new version of your Formula.")
      git.with_clone!(tap.url, tap.repo) do
        tap.on_formula! formula_name do |formula|
          logger.info!("Let's see if any files on your Bintray look like Bottles.")
          bottles = bversion.gather_bottles
          bottles.reduce(
            formula.
            put_sdist(sdist.url, sdist.sha256).
            rm_all_bottles
          ) do |f, (os, checksum)|
            f.put_bottle(os, checksum)
          end
        end
        git.config!
        git.commit_am! "Add bottles for #{formula_name}@#{bversion.version_name}"
        logger.info!("I've refered to the Bottles I found in this new commit. Let's push to your Tap!")
        git.push!
      end
      logger.info!("All done!")
    end

  end

end
