
require 'parser/current'
require 'unparser'

require 'homebrew_automation'


describe 'The Formula class' do
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

  def parsing_api str
    HomebrewAutomation::Formula.parse_string str
  end

  def formatting_api formula
    formula.to_s
  end

  it 'has one own public class methods' do
    expect(HomebrewAutomation::Formula.methods(false).sort).
      to eq([:parse_string])
  end

  it 'only has these own public instance methods' do
    expect(HomebrewAutomation::Formula.public_instance_methods(false).sort).
      to eq([
        :==,
        :hash,
        :eql?,
        :to_s,
        :put_sdist,
        :update_field,
        :put_bottle,
        :rm_all_bottles,
      ].sort)
  end

  it 'can modify the (source tarball) URL and sha256 fields of a Formula' do
    formula_before = parsing_api INIT_FORMULA
    formula_after = formula_before.put_sdist("https://google.com", "abcd")
    expect(formatting_api(formula_after)).to eq <<-HEREDOC.chomp
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
  end

  it 'can put new bottles definitions into a formula' do
    formula_before = parsing_api INIT_FORMULA
    formula_after = formula_before.put_bottle("el_capitan", "abcd")
    expect(formatting_api formula_after).to eq <<-HEREDOC.chomp
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
  end

  it 'can wipe out all pre-existing bottle references' do
    formula_before = parsing_api INIT_FORMULA
    formula_after = formula_before.rm_all_bottles
    expect(formatting_api formula_after).to eq <<-HEREDOC.chomp
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
  end
  def install
    system("echo", "whatever")
  end
  test do
    system("echo", "just", "pass")
  end
end
    HEREDOC
  end

  it 'can overwrite existing bottle definitions' do
    formula_before = parsing_api INIT_FORMULA
    formula_after = formula_before.put_bottle("yosemite", "abcd")
    expect(formatting_api(formula_after)).to eq <<-HEREDOC.chomp
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
  end

  it "defines #== equality by equivalence of source trees" do
    formula_before = parsing_api INIT_FORMULA
    formula_before_2 = parsing_api INIT_FORMULA
    expect(formula_before).not_to be formula_before_2
    expect(formula_before).to eq formula_before_2
  end

  it "doesn't mutate instances by use of its methods" do
    before = parsing_api INIT_FORMULA
    before_2 = parsing_api INIT_FORMULA
    after = before.update_field "sha256", "1234"
    expect(after).not_to be before
    expect(after).not_to eq before
    expect(after).not_to eq before_2
  end

end
