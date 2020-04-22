Build Bottles and update Formulae
=================================

[![Build Status](https://travis-ci.org/easoncxz/homebrew-automation.svg?branch=master)](https://travis-ci.org/easoncxz/homebrew-automation)
[![Gem Version](https://badge.fury.io/rb/homebrew_automation.svg)](https://badge.fury.io/rb/homebrew_automation)

This is a Ruby library, with a small CLI, to help you publish new versions of 
your software through [Mac Homebrew][brew].

# Motivation

Earlier, I was working on a project, [hack-assembler][hack], which was an 
assignment as part of a MOOC. It was a fun piece of code, so after I finished 
the assignment, I wanted to show it to my friends in a convenient way. I aimed 
for publishing it using Mac Homebrew, mostly due to familiarity; I also want to
provide pre-built binaries so my friends won't have to compile my Haskell code 
on their system.

It turns out that was't super straightforward! I had to juggle between this 
repo, a second Github repo as the Tap repo, Bintray, brew commands, Travis CI, 
and API calls here and there. In particular, **Travis CI was the real pain 
point**. I started with some shell scripts for my automation, but tiny mistakes 
often cost me hour-long Travis builds to debug (because Travis is slow, and 
compiling my Haskell code is even slower). The long debug cycles were crushing.
Yes, I'm aware of Travis [debug builds][travis-debug], but for some reason they 
weren't working at the time. The build servers at Travis were also pretty buggy, 
and I was in frequent contact with their lovely support staff.

At some point I thought, enough with the shell scripts, let me package these 
scripts as their own tool, decoupled from my Haskell project. I've had enough of 
the shell scripts and the errors on Travis, and besides, it would actually be a 
useful tool on its own for publishing other software on Homebrew, especially in 
CI/CD setups. That was the beginning of this Gem.

If you're not yet familiar with any of the beer-themed Homebrew terms (e.g.
Formula, Tap, Bottle), you should read the [Homebrew docs][brew] first.

# Scope of functionality

This Gem isn't trying to automate away the entire process of publishing a
Homebrew Formula, but rather only the incremental steps. That is, this Gem helps 
you with what you have to do each time you want to publish a new version, but 
not the initial setup when you create a new Formula. This means before you can 
benefit from this Gem, you'll first have to manually:

- [Create a Tap repository][tap] if you don't have one already.
- Create a Formula file in that Tap.
- Setup Bintray stuff: an account, a "Repository", and a "Package".
- Generate a [Github OAuth token][github-token], for pushing to your Tap repo.
- Generate a [Bintray API key][bintray-key], for uploading Bottle tarballs.

Functionality that this Gem provides include:

- Editing Formula files programmatically;
- Building Bottles for an existing Formula;
- Uploading Bottle tarballs to Bintray;
- Searching for and gathering Bottle tarballs from Bintray; and
- Publishing a new version of a Formula to a Tap, optionally including Bottles
  from Bintray.

# Installation

To use the Gem either as a library or as a CLI, install it via Gem:

    $ gem install homebrew_automation
    ... ( RubyGems busy at work ) ...

    $ homebrew_automation.rb version 2> /dev/null
    0.1.18

    $ homebrew_automation.rb version
    warning: parser/current is loading parser/ruby26, which recognizes
    warning: 2.6.6-compliant syntax, but you are running 2.6.5.
    warning: please see https://github.com/whitequark/parser#compatibility-with-ruby-mri.
    0.1.18

Don't worry about the errors on stderr; I just can't find a way to silence them.
They don't cause issues because Formula files only use very simple Ruby language 
features.

> Note: Since I don't plan to put in any effort to keep the API nor CLI stable,
please take note of which version of this Gem you are depending on, and stick
to it. `gem install homebrew_automation -v some-version`.

About the Ruby API:
- `require 'homebrew_automation'`
- Top-level Ruby module: `HomebrewAutomation`; see [rubydoc][rubydoc].
- API docs are available via `rake docs`.

# Example

Suppose I've made some changes to my app, `hello-homebrew-packaging`, and pushed 
the commits to Github under the tag `v0.0.3`. At this point, the [Tap][tap] repo 
would not have been updated with the new version (v0.0.3) of the app yet. Let's 
say we want to publish v0.0.3 of our app to the world, and include pre-built 
binaries. We can run `homebrew_automation.rb` from our local development machine 
to do so.

First, let's build the Bottles and upload them to Bintray, so we can use them 
in the next step:

    $ gem install homebrew_automation
    ... ( RubyGems doing its thing ) ...

    $ homebrew_automation.rb bottle build-and-upload \
        --source-repo       hello-homebrew-packaging \
        --source-tag        v0.0.3 \
        --source-user       easoncxz \
          \
        --formula-name      hello-homebrew-packaging \
        --formula-version   0.0.3 \
          \
        --tap-user          easoncxz \
        --tap-repo          homebrew-tap \
        --tap-token         $EASONCXZ_GITHUB_OAUTH_TOKEN \
          \
        --bintray-user      easoncxz \
        --bintray-token     $EASONCXZ_BINTRAY_API_KEY \

    homebrew_automation.rb [info] (2020-04-23T04:37:03+12:00): Hello, this is HomebrewAutomation! I will now build your Formula and upload the bottles to Bintray.
    homebrew_automation.rb [info] (2020-04-23T04:37:03+12:00): First let's clone your Tap repo to see the Formula.
    Cloning into 'homebrew-tap'...
    ...
    ... ( some git stuff ) ...
    ...
    homebrew_automation.rb [info] (2020-04-23T04:37:07+12:00): I've updated the Formula file in our local Tap clone, and we're ready to start building the Bottle. This could take a long time if your Formula is slow to compile.
    Updating Homebrew...
    ...
    ... ( Homebrew gets really busy ) ...
    ...
    ==> Summary
    🍺  /usr/local/Cellar/hello-homebrew-packaging/0.0.3: 5 files, 13.2KB, built in 5 seconds
    ...
    ... ( more stuff ) ...
    ...
    homebrew_automation.rb [info] (2020-04-23T04:37:37+12:00): Bottle built! Let me now upload the Bottle tarball to Bintray.
    ...
    homebrew_automation.rb [info] (2020-04-23T04:37:41+12:00): All done!

There should now be a new tarball sitting on Bintray, holding the Bottle we've 
just built, which should look like this:
[`hello-homebrew-packaging-0.0.3.high_sierra.bottle.tar.gz`](https://bintray.com/easoncxz/homebrew-bottles/hello-homebrew-packaging/0.0.3#files).
However, our users don't notice this yet. Let's now update the Tap to tell our 
users that a new version of our app is available, complete with the Bottles we 
built in the previous step.  We may have built and uploaded Bottles for multiple 
macOS versions; all Bottles will be "gathered" from Bintray and "published" 
in the Tap.

    $ homebrew_automation.rb bottle gather-and-publish \
        --source-repo       hello-homebrew-packaging \
        --source-tag        v0.0.3 \
        --source-user       easoncxz \
          \
        --formula-name      hello-homebrew-packaging \
        --formula-version   0.0.3 \
          \
        --tap-user          easoncxz \
        --tap-repo          homebrew-tap \
        --tap-token         $EASONCXZ_GITHUB_OAUTH_TOKEN \
          \
        --bintray-user      easoncxz \
        --bintray-token     $EASONCXZ_BINTRAY_API_KEY \

    homebrew_automation.rb [info] (2020-04-23T04:50:00+12:00): Hello, this is HomebrewAutomation! I will browse through your Bintray to see if there may be Bottles built earlier for your Formula, and update your Tap to refer to them.
    homebrew_automation.rb [info] (2020-04-23T04:50:00+12:00): I will also update the source tarball of your Formula in your Tap, effectively releasing a new version of your Formula.
    Cloning into 'homebrew-tap'...
    ...
    ... ( git stuff ) ...
    ...
    homebrew_automation.rb [info] (2020-04-23T04:50:03+12:00): Let's see if any files on your Bintray look like Bottles.
    homebrew_automation.rb [info] (2020-04-23T04:50:04+12:00): All files in Bintray Version: [{"name"=>"hello-homebrew-packaging-0.0.3.mojave.bottle.tar.gz", ... }]
    homebrew_automation.rb [info] (2020-04-23T04:50:04+12:00): Found bottles: {"mojave"=>"e92cc9ac8db371e20e21c99b1b14c8f463f739d5f6bb5a7893766840bddec90a", "high_sierra"=>"257aa2e4317addf83260b970e13eef4426f2792acfab945c52ccb7658eec3b2d", "catalina"=>"040d71d9874b038d6bedfd9c490b32dbc93f41013cc505a270a6e22f735e1e91"}
    ...
    homebrew_automation.rb [info] (2020-04-23T04:50:05+12:00): I've refered to the Bottles I found in this new commit. Let's push to your Tap!
    Enumerating objects: 1, done.
    Counting objects: 100% (1/1), done.
    Writing objects: 100% (1/1), 212 bytes | 212.00 KiB/s, done.
    Total 1 (delta 0), reused 0 (delta 0), pack-reused 0
    To https://github.com/easoncxz/homebrew-tap.git
       552fa9a..cba653d  master -> master
    homebrew_automation.rb [info] (2020-04-23T04:50:10+12:00): All done!

Now our Tap knows about the new version of the app, including the Bottles. If 
our user now ran `brew install easoncxz/tap/hello-homebrew-packaging`, they 
would be installing the new version, in this case `v0.0.3`. Hopefully, the user 
will be running a macOS version for which we've built a Bottle, otherwise 
Homebrew will build the `hello-homebrew-packaging` Formula from source on our 
user's system, installing the necessary build-time dependencies automatically. 
This can be a lengthy process.

# Further details

- [`easoncxz/homebrew-tap`][tap-repo] actually is my personal Homebrew Tap
  repo,
- I actually do host my Bottles at
  [bintray.com/easoncxz/homebrew-bottles][bintray-repo], and
- the [`hello-homebrew-packaging`][hello] project also actually exists as a
  Formula.

You can use [`hello-homebrew-packaging`][hello] as an end-to-end example, and 
examine for yourself how everything fits together. In the [Github Wiki of 
hello-homebrew-packaging][wiki], I also share my journey of figuring out how to 
put all these pieces together when I was developing this Gem. Go read it if 
you're interested; it's quite a lengthy couple of articles!

[travis-debug]: https://docs.travis-ci.com/user/running-build-in-debug-mode/
[rubydoc]: http://www.rubydoc.info/gems/homebrew_automation
[brew]: https://docs.brew.sh
[tap]: https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap<Paste>
[github-token]: https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/
[bintray-key]: https://www.jfrog.com/confluence/display/BT/Bintray+REST+API
[hack]: https://github.com/easoncxz/hack-assembler
[hello]: https://github.com/easoncxz/hello-homebrew-packaging
[tap-repo]: https://github.com/easoncxz/homebrew-tap
[bintray-repo]: https://bintray.com/easoncxz/homebrew-bottles
[wiki]: https://github.com/easoncxz/hello-homebrew-packaging/wiki
