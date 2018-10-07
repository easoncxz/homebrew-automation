#!/usr/bin/env ruby

require 'thor'

require_relative '../lib/homebrew_automation.rb'

class FormulaCommands < Thor

  desc 'put-sdist', 'Update the URL and sha256 checksum of the source tarball'
  option :url, :required => true
  option :sha256, :required => true
  def put_sdist
    before = HomebrewAutomation::Formula.parse_string($stdin.read)
    after = before.put_sdist options[:url], options[:sha256]
    $stdout.write after
  end

  desc 'put-bottle', 'Insert or update a bottle reference for a given OS'
  option :os, :required => true
  option :sha256, :required => true
  def put_bottle
    before = HomebrewAutomation::Formula.parse_string($stdin.read)
    after = before.put_bottle(options[:os], options[:sha256])
    $stdout.write after
  end

end

class WorkflowCommands < Thor
  class_option :tap_user, :required => true
  class_option :tap_repo, :required => true
  class_option :tap_token, :required => true
  class_option :bintray_user, :required => true
  class_option :bintray_token, :required => true

  desc 'build-and-upload', 'Build binary tarball from source tarball, then upload to Bintray'
  long_desc <<-HERE_HERE
    Since we're uploading to Bintray, we need a Bintray API KEY at `bintray_token`.

    `formula_name` defaults to the same as `source_repo`.
    `formula_version` defaults to `source_tag` with a leading `v` stripped off.
  HERE_HERE
  option :source_user, :required => true
  option :source_repo, :required => true
  option :source_tag, :required => true
  option :formula_name
  option :formula_version
  def build_and_upload
    workflow.build_and_upload_bottle(
      HomebrewAutomation::SourceDist.new(
        options[:source_user],
        options[:source_repo],
        options[:source_tag]),
      formula_name: options[:formula_name],
      version_name: options[:formula_version])
  end

  desc 'gather-and-publish', 'Make the Tap aware of new Bottles'
  long_desc <<-HERE_HERE
    See what bottles have been built and uploaded to Bintray, then publish them into the Tap.

    Since we're publishing updates to the Formula in our Tap, we need Git push access to the
    Tap repo on Github via a Github OAuth token via `tap_token`.

    `formula-name` should be both the formula name as appears in the Tap and also the Bintray package name.
    `formula-version` should be the Bintray "Version" name.
  HERE_HERE
  option :formula_name, :required => true
  option :formula_version, :required => true
  def gather_and_publish
    workflow.gather_and_publish_bottles(
      options[:formula_name],
      options[:formula_version])
  end

  private

  def workflow
    HomebrewAutomation::Workflow.new(
      HomebrewAutomation::Tap.new(options[:tap_user], options[:tap_repo], options[:tap_token]),
      HomebrewAutomation::Bintray.new(options[:bintray_user], options[:bintray_token]))
  end

end

class MyCliApp < Thor

  desc 'formula (...)', 'Modify Formula DSL source (read stdin, write stdout)'
  subcommand "formula", FormulaCommands

  desc 'bottle (...)', 'Workflows for dealing with binary artifacts'
  subcommand "bottle", WorkflowCommands

end


MyCliApp.start(ARGV)


