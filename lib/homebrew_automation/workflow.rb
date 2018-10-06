
require_relative './mac-os.rb'

module HomebrewAutomation

  # Imperative glue code
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

    # @param source_dist [HomebrewAutomation::SourceDist]
    # @param version_name [String] Bintray package "Version" name; defaults to stripping leading `v` from the Git tag.
    def build_and_upload_bottle(source_dist, version_name: nil)
      formula_name = source_dist.repo
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
      end
    end

  end

end
