
Related reading:

- Build bottles on Travis-CI and deploy to Bintray <https://github.com/davidchall/homebrew-hep/pull/114>

- How to automate the build of bottles on your Homebrew tap <https://gist.github.com/maelvalais/068af21911c7debc4655cdaa41bbf092>

- Use `--` for bottles. <https://github.com/Homebrew/brew/pull/4612>

- Push back to Github from Travis <https://gist.github.com/willprice/e07efd73fb7f13f917ea>

- Preview what the Gem `description` field would look like on rubygems.org:

    ```ruby
    require 'rdoc'

    # https://ruby.github.io/rdoc/RDoc/Markup.html#class-RDoc::Markup-label-Synopsis
    #
    # rdoc (6.0.1)

    description = '== Some title' + <<-HEREDOC

    A paragraph

    - One
    - Two

    More text

      HEREDOC

    h = RDoc::Markup::ToHtml.new(RDoc::Options.new)
    puts h.convert description
    ```

- Insane problems with the interplay of RVM, macOS, and Homebrew, on Travis CI:
  - `shell_session_update` error: <https://github.com/travis-ci/travis-ci/issues/6307>
  - `Gemset '' does not exist` error: <https://github.com/travis-ci/travis-ci/issues/9404>
  - `Homebrew must be run under Ruby 2.3!`:
    - <https://github.com/Chatie/wechaty/issues/936>
    - <https://github.com/travis-ci/travis-ci/issues/8552>
  - `rvm is not a function`: <https://stackoverflow.com/questions/23963018/rvm-is-not-a-function-selecting-rubies-with-rvm-use-will-not-work>
  - Ruby versions available on macOS environments on Travis CI: <http://rubies.travis-ci.org/>
