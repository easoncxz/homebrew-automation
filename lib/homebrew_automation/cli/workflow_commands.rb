
require 'thor'

require_relative '../../homebrew_automation.rb'

module HomebrewAutomation
  module CLI
  end
end

class HomebrewAutomation::CLI::WorkflowCommands < Thor
  class_option :source_user, :required => true
  class_option :source_repo, :required => true
  class_option :source_tag, :required => true
  class_option :tap_user, :required => true
  class_option :tap_repo, :required => true
  class_option :tap_token, :required => true
  class_option :formula_name
  class_option :bintray_user, :required => true
  class_option :bintray_token, :required => true
  class_option :bintray_repo
  class_option :bintray_package
  class_option :bintray_version

  desc 'build-and-upload', 'Build binary tarball from source tarball, then upload to Bintray'
  long_desc <<-HERE_HERE
    Since we're uploading to Bintray, we need a Bintray API KEY at `bintray_token`.
  HERE_HERE
  option :keep_tap_repo, :type => :boolean
  option :keep_brew_tmp, :type => :boolean
  def build_and_upload
    workflow.build_and_upload_bottle!(
      sdist,
      tap,
      git,
      formula_name,
      bintray_version,
      logger,
      keep_tap_repo: options[:keep_tap_repo],
      keep_homebrew_tmp: options[:keep_brew_tmp])
  end

  desc 'gather-and-publish', 'Make the Tap aware of new Bottles'
  long_desc <<-HERE_HERE
    See what bottles have been built and uploaded to Bintray, then publish them into the Tap.

    Since we're publishing updates to the Formula in our Tap, we need Git push access to the
    Tap repo on Github via a Github OAuth token via `tap_token`.
  HERE_HERE
  def gather_and_publish
    workflow.gather_and_publish_bottles!(
      sdist,
      tap,
      formula_name,
      bintray_version)
  end

  private

  def sdist
    HomebrewAutomation::SourceDist.new(
      options[:source_user],
      options[:source_repo],
      options[:source_tag])
  end

  def tap
    HomebrewAutomation::Tap.new(
      options[:tap_user],
      options[:tap_repo],
      options[:tap_token])
  end

  def git
    HomebrewAutomation::Git
  end

  # DOC: default values here
  def formula_name
    options[:formula_name] || sdist.repo
  end

  def bintray_client
    HomebrewAutomation::Bintray::Client.new(
      options[:bintray_user],
      options[:bintray_token])
  end

  # DOC: default values here
  def bintray_version
    HomebrewAutomation::Bintray::Version.new(
      bintray_client,
      options[:bintray_repo] || "homebrew-bottles",
      options[:bintray_package] || sdist.repo,
      options[:bintray_version] || sdist.tag.sub(/^v/, ''))
  end

  def workflow
    HomebrewAutomation::Workflow.new
  end

  def logger
    HomebrewAutomation::Logger.new
  end

end
