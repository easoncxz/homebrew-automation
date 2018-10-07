
require_relative './mac-os.rb'
require_relative './bottle_gatherer.rb'

module HomebrewAutomation

  # Imperative glue code
  #
  # Probably each method suits to become a CLI command.
  class Workflow

    # @param tap [HomebrewAutomation::Tap]
    # @param bintray [HomebrewAutomation::Bintray]
    def initialize(
        tap,
        bintray,
        bintray_bottle_repo: 'homebrew-bottles')
      @tap = tap
      @bintray = bintray
      @bintray_bottle_repo = bintray_bottle_repo
    end

    # Build a bottle from the given source tarball reference
    #
    # @param source_dist [HomebrewAutomation::SourceDist] Source tarball
    # @param formula_name [String] Formula name as appears in the Tap, which should be the same as the Bintray "Package" name
    # @param version_name [String] Bintray package "Version" name; defaults to stripping leading `v` from the Git tag.
    # @return [Bottle]
    def build_and_upload_bottle(source_dist, formula_name: nil, version_name: nil)
      formula_name ||= source_dist.repo
      version_name ||= source_dist.tag.sub(/^v/, '')
      os_name = MacOS.identify_version
      @tap.with_git_clone do
        @tap.on_formula(formula_name) do |formula|
          formula.put_sdist(source_dist.url, source_dist.sha256)
        end
        @tap.git_commit_am "Throwaway commit; just for building bottles"

        local_tap_url = File.realpath('.')
        bottle = Bottle.new(local_tap_url, formula_name, os_name)
        bottle.build

        @bintray.create_version(
          @bintray_bottle_repo,
          formula_name,
          version_name)
        @bintray.upload_file(
          @bintray_bottle_repo,
          formula_name,
          version_name,
          bottle.filename,
          bottle.content)

        bottle
      end
    end

    # Look around on Bintray to see what bottles we've previously built, then
    # push new commits into the Tap repository to register the new bottles.
    #
    # @param formula_name [String]
    # @param version_name [String] Bintray "Version" name, not a Git tag
    # @return [Formula]
    def gather_and_publish_bottles(formula_name, version_name)
      @tap.with_git_clone do
        resp = @bintray.get_all_files_in_version(
          @bintray_bottle_repo,
          formula_name,
          version_name)
        unless (200..207) === resp.code
          puts resp
          raise StandardError.new(resp)
        end

        json = JSON.parse(resp.body)
        gatherer = BottleGatherer.new(json)

        @tap.on_formula(formula_name) do |formula|
          gatherer.put_bottles_into(formula)
        end

        @tap.git_config
        @tap.git_commit_am "Add bottles for #{formula_name}@#{version_name}"
        @tap.git_push
      end
    end


  end

end
