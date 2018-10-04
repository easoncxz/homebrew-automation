
module HomebrewAutomation

  # Imperative glue code
  class Workflow

    # @param source_dist [HomebrewAutomation::SourceDist]
    # @param tap [HomebrewAutomation::Tap]
    # @param bintray [HomebrewAutomation::Bintray]
    def initialize(
        source_dist,
        tap,
        bintray,
        bintray_bottle_repo: 'homebrew-bottles')
      @source_dist = source_dist
      @tap = tap
      @bintray = bintray
      @bintray_bottle_repo = bintray_bottle_repo
    end

    # @param formula_name [String]
    # @param version_name [String]
    # @param os_name [String] As recognised by Homebrew Formula/Bottle DSL
    def build_and_upload_bottle(formula_name, version_name, os_name)
      @tap.with_git_clone do
        @tap.on_formula(formula_name) do |formula|
          formula.put_sdist(@source_dist.url, @source_dist.sha256)
        end
        @tap.git_commit_am "Throwaway commit; just for building bottles"

        local_tap_url = File.realpath('.')
        bottle = Bottle.new(local_tap_url, formula_name, os_name)
        bottle.build

        bottle.load_from_disk
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
