Build Bottles and update Formulae
=================================

[![Build Status](https://travis-ci.org/easoncxz/homebrew-automation.svg?branch=master)](https://travis-ci.org/easoncxz/homebrew-automation)

This is a Ruby library, with a small CLI, for:

- Editing Formula files programmatically;
- Building Bottles for an existing Formula;
- Uploading Bottles tarballs to Bintray;
- Searching for and gathering Bottle tarballs from Bintray; and
- Updating Formula files to refer to new Bottles, by committing to
  the Tap Git repo.

## Background

Earlier, in a different project, I wanted to publish my app as a Homebrew
package in a custom Homebrew Tap that I own. In the process of trying to
automatically build Bottles (pre-built binary packages) and update Formula
files with new versions of my app, I found myself wanting some scripts, so that
I don't need to run many manual commands, and also to make configuring CI/CD
simpler. This Gem is the result of trying to put these scripts in one reusable
place outside of my app itself.

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

## Example

To use either the Gem as a library or as a CLI, install it via Gem:

    gem install homebrew_automation

Note: Since I don't plan to put in any effort to keep the API nor CLI stable,
please take note of which version of this Gem you are depending on, and stick
to it. `gem install homebrew_automation -v some-version`.

A one-off run to deploy pre-built binaries of a new version of your app
(e.g. `easoncxz/app`) to users of your Tap:

    # Suppose I've just pushed the Git tag `v0.1.1.17` to my app repo,
    # `hack-assembler`.

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

    # Now there are one new tarball sitting on Bintray.

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

    # Now the Formula in the Tap refers to the new tarball we've just uploaded
    # onto Bintray.

## More documentation

I've written lots of code API docs (in YARD format). You can read them served up
as HTML either by running `rake docs` and visiting <http://localhost:8808/>, or 
by clicking the "Documentation" link on the RubyGems website, e.g.  
<http://www.rubydoc.info/gems/homebrew_automation/0.1.0> .

[tap]: https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap<Paste>
[github-token]: https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/
