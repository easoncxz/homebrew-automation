
require 'parser/current'
require 'unparser'

require 'homebrew_automation'


describe 'surface API of manipulate_formulae' do
  INIT_FORMULA = <<-HEREDOC
class HackAssembler < Formula
  desc("A toy assembler for the Hack machine language")
  homepage("https://github.com/easoncxz/hack-assembler")
  url("https://github.com/easoncxz/hack-assembler/archive/v0.1.1.4.tar.gz")
  sha256("46823a63bf32b26f09764a70babe59190461f84f8f04be796465d0756698e2a3")
  depends_on("haskell-stack" => :build)
  bottle do
    cellar(:any_skip_relocation)
    rebuild(1)
    root_url("https://dl.bintray.com/easoncxz/homebrew-bottles")
    sha256("4be7efbbfb251b46a860080b753bd280b36726e1d8b7815893e35354ae33f730" => :yosemite)
  end
  def install
    system("echo", "whatever")
  end
  test do
    system("echo", "just", "pass")
  end
end
  HEREDOC

  it 'can modify the (source tarball) URL and sha256 fields of a Formula' do
    formula_before = Parser::CurrentRuby.parse INIT_FORMULA
    formula_after = HomebrewAutomation.update_formula_field("url", "https://google.com", formula_before)
    formula_after = HomebrewAutomation.update_formula_field("sha256", "abcd", formula_after)
    expect(Unparser.unparse formula_after).to eq <<-HEREDOC
class HackAssembler < Formula
  desc("A toy assembler for the Hack machine language")
  homepage("https://github.com/easoncxz/hack-assembler")
  url("https://google.com")
  sha256("abcd")
  depends_on("haskell-stack" => :build)
  bottle do
    cellar(:any_skip_relocation)
    rebuild(1)
    root_url("https://dl.bintray.com/easoncxz/homebrew-bottles")
    sha256("4be7efbbfb251b46a860080b753bd280b36726e1d8b7815893e35354ae33f730" => :yosemite)
  end
  def install
    system("echo", "whatever")
  end
  test do
    system("echo", "just", "pass")
  end
end
      HEREDOC
      .chomp
  end

  it 'can put new bottles definitions into a formula' do
    formula_before = Parser::CurrentRuby.parse INIT_FORMULA
    formula_after = HomebrewAutomation.put_bottle("el_capitan", "abcd", formula_before)
    expect(Unparser.unparse(formula_after)).to eq <<-HEREDOC
class HackAssembler < Formula
  desc("A toy assembler for the Hack machine language")
  homepage("https://github.com/easoncxz/hack-assembler")
  url("https://github.com/easoncxz/hack-assembler/archive/v0.1.1.4.tar.gz")
  sha256("46823a63bf32b26f09764a70babe59190461f84f8f04be796465d0756698e2a3")
  depends_on("haskell-stack" => :build)
  bottle do
    cellar(:any_skip_relocation)
    rebuild(1)
    root_url("https://dl.bintray.com/easoncxz/homebrew-bottles")
    sha256("4be7efbbfb251b46a860080b753bd280b36726e1d8b7815893e35354ae33f730" => :yosemite)
    sha256("abcd" => :el_capitan)
  end
  def install
    system("echo", "whatever")
  end
  test do
    system("echo", "just", "pass")
  end
end
    HEREDOC
      .chomp
  end

  it 'can overwrite existing bottle definitions' do
    formula_before = Parser::CurrentRuby.parse INIT_FORMULA
    formula_after = HomebrewAutomation.put_bottle("yosemite", "abcd", formula_before)
    expect(Unparser.unparse(formula_after)).to eq <<-HEREDOC
class HackAssembler < Formula
  desc("A toy assembler for the Hack machine language")
  homepage("https://github.com/easoncxz/hack-assembler")
  url("https://github.com/easoncxz/hack-assembler/archive/v0.1.1.4.tar.gz")
  sha256("46823a63bf32b26f09764a70babe59190461f84f8f04be796465d0756698e2a3")
  depends_on("haskell-stack" => :build)
  bottle do
    cellar(:any_skip_relocation)
    rebuild(1)
    root_url("https://dl.bintray.com/easoncxz/homebrew-bottles")
    sha256("abcd" => :yosemite)
  end
  def install
    system("echo", "whatever")
  end
  test do
    system("echo", "just", "pass")
  end
end
    HEREDOC
      .chomp
  end

end
