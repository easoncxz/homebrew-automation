Build Bottles and update Formulae
=================================

[![Build Status](https://travis-ci.org/easoncxz/homebrew-automation.svg?branch=master)](https://travis-ci.org/easoncxz/homebrew-automation)
[![Gem Version](https://badge.fury.io/rb/homebrew_automation.svg)](https://badge.fury.io/rb/homebrew_automation)

This is a Ruby library, with a small CLI, for working with Mac Homebrew. It helps with:

- Editing Formula files programmatically;
- Building Bottles for an existing Formula;
- Uploading Bottle tarballs to Bintray;
- Searching for and gathering Bottle tarballs from Bintray; and
- Updating Formula files to refer to new Bottles, by making git commits to
  the Tap Git repo.

## Background

Earlier, in a different project, I wanted to publish my app as a Homebrew
package in a custom Homebrew Tap that I own. In the process of trying to
automatically build Bottles (pre-built binary packages) and update Formula
files with new versions of my app, I found myself wanting some scripts, so that
I don't need to run many manual commands, and also to make configuring CI/CD
simpler. This Gem is the result of trying to put these scripts in one reusable
place outside of my app itself.

If any of the capitalised terms (e.g. Formula, Tap, Bottle) don't make sense
for you, you might want to read the [Homebrew docs][brew] first.

## Scope

This Gem isn't trying to automate away the whole process of publishing a
Homebrew package, but rather only the incremental steps, i.e. the stuff you
have to do each time you want to publish a new version. Setup steps for the
initial publication is not covered by this Gem. This means before you can
benefit from this Gem, you'll first have to manually:

- [Create the Tap repository][tap] if you don't have one.
- Create a Formula file in that Tap.
- Setup Bintray stuff: i.e. an account, then a "Repository" and a "Package".
  (Creating a "Version" on Bintray is covered by this Gem, so you can skip that.)
- Generate a [Github OAuth token][github-token] for pushing to your Tap repo.
- Generate a [Bintray API key][bintray-key] for uploading Bottle tarballs.

## Usage

To use either the Gem as a library or as a CLI, install it via Gem:

    gem install homebrew_automation

RubyGems page: <https://rubygems.org/gems/homebrew_automation>

Note: Since I don't plan to put in any effort to keep the API nor CLI stable,
please take note of which version of this Gem you are depending on, and stick
to it. `gem install homebrew_automation -v some-version`.

About the Gem:

- `require 'homebrew_automation'` to use the library.
- All library code sits within the Ruby module `HomebrewAutomation`.
- A CLI executable is provided, named `homebrew_automation.rb`.

For more details, read the API docs. I've written a lot of them! Docs are available via:

- Inside this repo, run `rake docs` and visit <http://localhost:8808/>.
- The "Documentation" link on the RubyGems page, e.g. <http://www.rubydoc.info/gems/homebrew_automation> .

A one-off run to deploy pre-built binaries of a new version of your app
(e.g. `easoncxz/hack-assembler`) to users of your Tap:

    # Suppose I've just pushed the Git tag `v0.1.1.17` to my app repo,
    # `hack-assembler`. The Tap repo may not have been updated with the new
    # version of the app yet.

    homebrew_automation.rb bottle build-and-upload \
        --source-repo       hack-assembler \
        --source-tag        v0.1.1.17 \
        --source-user       easoncxz \
          \
        --formula-name      hack-assembler \
        --formula-version   0.1.1.17 \
          \
        --tap-user          easoncxz \
        --tap-repo          homebrew-tap \
        --tap-token         $EASONCXZ_GITHUB_OAUTH_TOKEN \
          \
        --bintray-user      easoncxz \
        --bintray-token     $EASONCXZ_BINTRAY_API_KEY

    # After the above, there should now be a new tarball sitting on Bintray, holding
    # the binary we've just built, but our users don't known this yet.  Let's now
    # update the Tap to tell our users that a new version of our app is available,
    # and at the same time, provide access to the pre-built binaries we built in the
    # previous step.  (We may have built multiple binaries for multiple OS's or OS
    # versions; hence the wording of "gathering" them.)

    homebrew_automation.rb bottle gather-and-publish \
        --source-repo       hack-assembler \
        --source-tag        v0.1.1.17 \
        --source-user       easoncxz \
          \
        --formula-name      hack-assembler \
        --formula-version   0.1.1.17 \
          \
        --tap-user          easoncxz \
        --tap-repo          homebrew-tap \
        --tap-token         $EASONCXZ_GITHUB_OAUTH_TOKEN \
          \
        --bintray-user      easoncxz \
        --bintray-token     $EASONCXZ_BINTRAY_API_KEY

    # Now the Formula for our particular app in the our Tap refers to the
    # source tarball of the new version of the app, and also holds references to
    # the Bottles we've built, uploaded to Bintray, and gathered. If our user now
    # tries to use Homebrew to install `hack-assembler`, they will get the new version
    # (in this case `v0.1.1.17`). Hopefully, the user will be running an OS for which
    # we've built a Bottle, otherwise they might have to run a lengthy compilation process.

[brew]: https://docs.brew.sh
[tap]: https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap<Paste>
[github-token]: https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/
[bintray-key]: https://www.jfrog.com/confluence/display/BT/Bintray+REST+API
