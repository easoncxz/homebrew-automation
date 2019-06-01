
require_relative './mac-os.rb'
require_relative './bintray.rb'

module HomebrewAutomation

  # Imperative glue code.
  #
  # Each method in this class probably makes sense to be exposed as a CLI command.
  class Workflow

    # Assign params to attributes.
    #
    # See {#tap} and {#bclient}.
    #
    # @param tap [Tap]
    # @param bclient [Bintray::Client]
    # @param brepo [String] Bintray Repository name
    def initialize(tap, bclient, brepo: 'homebrew-bottles')
      @tap = tap
      @bclient = bclient
      @brepo = brepo
    end

    # The Tap holding the Formulae for which we might want to build or publish bottles.
    #
    # @return [Tap]
    attr_reader :tap

    # An API client
    #
    # @return [Bintray::Client]
    attr_reader :bclient

    # Build and upload a bottle.
    #
    # The Formula source comes from +source_dist+, and the Bottle tarball that
    # is built goes to Bintray.
    #
    # +source_dist+ not only specifies the source tarball, but it also implies:
    # - the formula name, as appears in the {#tap}, via {SourceDist#repo};
    # - the Bintray package version, as to be uploaded, via {SourceDist#tag}, with any leading +v+ stripped off.
    #
    # The optional params overwrite the above implication.
    #
    # @param source_dist [HomebrewAutomation::SourceDist] Source tarball
    # @param formula_name [String] Formula name as appears in the Tap, which should be the same as the Bintray "Package" name
    # @param version_name [String] Bintray package "Version" name; defaults to stripping leading `v` from the Git tag.
    # @return [Bottle]
    def build_and_upload_bottle(source_dist, formula_name, version_name)
      bversion = Bintray::Version.new(@bclient, @brepo, formula_name, version_name)
      os_name = MacOS.identify_version
      @tap.with_git_clone do
        @tap.on_formula(formula_name) do |formula|
          formula.put_sdist(source_dist.url, source_dist.sha256)
        end
        @tap.git_commit_am "Throwaway commit; just for building bottles"

        local_tap_url = File.realpath('.')
        bottle = Bottle.new(local_tap_url, formula_name, os_name)
        bottle.build

        @bversion.create!
        @bversion.upload_file!(bottle.filename, bottle.content)

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
    # @param formula_name [String] Both the Formula name in the Tap repo, and the Package name in the Bintray repo.
    # @param version_name [String] Bintray "Version" name; not a Git tag.
    # @return [Formula]
    def gather_and_publish_bottles(formula_name, version_name)
      bversion = Bintray::Version.new(@bclient, @brepo, formula_name, version_name)
      @tap.with_git_clone do
        @tap.on_formula(formula_name) do |formula|
          bottles = bversion.gather_bottles
          bottles.reduce(formula) do |f, (os, checksum)|
            f.put_bottle(os, checksum)
          end
        end
        @tap.git_config
        @tap.git_commit_am "Add bottles for #{formula_name}@#{version_name}"
        @tap.git_push
      end
    end

  end

end
