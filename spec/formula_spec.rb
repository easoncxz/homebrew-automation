
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

  def s(type, *children)
    Parser::AST::Node.new(type, children)
  end

  xdescribe "when there is only one expression in the bottle clause" do

    INIT_FORMULA_SIMPLER = File.read "spec/data/sample-formula-without-cellar-nor-rebuild.rb"

    it "can wipe out all bottles just the same" do
      formula_before = parsing_api INIT_FORMULA_SIMPLER
      formula_after = formula_before.rm_all_bottles
      expect(formula_after).to eq formula_before
    end

    it "can put new bottles in" do
      formula_before = parsing_api INIT_FORMULA_SIMPLER
      formula_after = formula_before.put_bottle("yosemite", "1234")
      str_expected = <<-'HEREDOC'.chomp
class WeiboExport < Formula
  desc("Semi-automatic CLI tool to download mblogs from weibo.com")
  homepage("https://github.com/easoncxz/weibo-export")
  url("https://github.com/easoncxz/weibo-export/archive/v0.1.0.2.tar.gz")
  sha256("4b0938c442bfbde3d34037ace1024bf235f4bdf30f64319c1413d0b4cf681b07")
  depends_on("haskell-stack" => :build)
  bottle do
    root_url("https://dl.bintray.com/easoncxz/homebrew-bottles")
    sha256("1234" => :yosemite)
  end
  def install
    system("stack", "upgrade", "--force-download")
    system("stack", "setup", "--verbose")
    system("stack", "build")
    prefix = `#{"stack path --dist-dir"}`.chomp
    bin.install("#{prefix}#{"/build/weibo-export/weibo-export"}")
  end
  test do
    system("weibo-export", "--help")
  end
end
      HEREDOC
      str_after = formatting_api(formula_after)
      expect(str_after).to be_a String
      expect(str_expected).to be_a String
      expect(str_after).to eq str_expected
    end

  end

end
