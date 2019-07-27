
require_relative './mac_os.rb'
require_relative './bintray.rb'
require_relative './source_dist.rb'

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
    # @return [Bottle]
    def build_and_upload_bottle(sdist, tap, formula_name, bversion)
      os_name = MacOS.identify_version
      tap.with_git_clone do
        tap.on_formula(formula_name) do |formula|
          formula.put_sdist(sdist.url, sdist.sha256)
        end
        tap.git_commit_am "Throwaway commit; just for building bottles"

        local_tap_url = File.realpath('.')
        bottle = Bottle.new(local_tap_url, formula_name, os_name)
        bottle.build

        bversion.create!
        bversion.upload_file!(bottle.filename, bottle.content)

        bottle
      end
    end

    # Gather and publish bottles.
    #
    # Look around on Bintray to see what Bottles we've already built and
    # uploaded (as such "gathering" the bottles), then push new commits into
    # the {#tap} repository to make an existing Formula aware of the Bottles
    # we're gathered (as such "publishing" the bottles).
    #
    # @param tap [Tap]
    # @param formula_name [String] the name of the formula in the Tap
    # @param bversion [Bintray::Version]
    # @return [Formula]
    def gather_and_publish_bottles(tap, formula_name, bversion)
      tap.with_git_clone do
        tap.on_formula(formula_name) do |formula|
          bottles = bversion.gather_bottles
          bottles.reduce(formula) do |f, (os, checksum)|
            f.put_bottle(os, checksum)
          end
        end
        tap.git_config
        tap.git_commit_am "Add bottles for #{formula_name}@#{bversion.version_name}"
        tap.git_push
      end
    end

  end

end
