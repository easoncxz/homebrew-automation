
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
        mac_os: MacOS,
        bottle: Bottle,
        keep_tap_repo: false,
        keep_homebrew_tmp: false)
      os_name = mac_os.identify_version!
      git.with_clone!(tap.url, tap.repo, keep_dir: keep_tap_repo) do |cloned_dir|
        tap.on_formula! formula_name do |formula|
          formula.put_sdist(sdist.url, sdist.sha256)
        end
        git.commit_am! "Throwaway commit; just for building bottles"
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
          begin
            bversion.upload_file!(filename, contents)
          rescue Bintray::Version::FileAlreadyExists
            puts "A file with the same name as the one you're uploading already exits on Bintray"
          end
        end
        bot
      end
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
    # @return [NilClass]
    def gather_and_publish_bottles!(sdist, tap, formula_name, bversion)
      git.with_clone!(tap.url, tap.repo) do
        tap.on_formula! formula_name do |formula|
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
        git.push!
      end
      nil
    end

  end

end
