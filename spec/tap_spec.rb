
require 'fileutils'
require 'tmpdir'

require 'homebrew_automation/tap.rb'

describe "HomebrewAutomation::Tap" do

  let (:user) { 'easoncxz' }
  let (:repo) { 'homebrew-tap' }
  let (:token) { 'very-secret' }

  let (:tap) { HomebrewAutomation::Tap.new(user, repo, token) }

  def on_tmp_tap(&block)
    rb_project_root = File.realpath '.'
    expect(rb_project_root).to start_with '/'
    Dir.chdir rb_project_root do
      expect(File.exist? 'homebrew_automation.gemspec').to be true
    end
    Dir.mktmpdir do |tmp|
      Dir.chdir tmp do |d|
        expect(d).to eq tmp
        FileUtils.copy_entry(
          File.join(rb_project_root, 'spec/data/sample-tap'),
          File.join(d, 'sample-tap'))
        expect(Dir.exists? 'sample-tap').to be true
        expect(Dir.exists? 'sample-tap/Formula').to be true
        Dir.chdir 'sample-tap', &block
      end
    end
  end

  it 'can copy stuff to a temp dir' do
    on_tmp_tap do
      expect(Dir.exists? 'Formula').to be true
      expect(File.basename(File.realpath('.'))).to eq 'sample-tap'
    end
  end

  it 'can edit a Formula file on disk' do
    on_tmp_tap do
      expect(Dir.exists? 'Formula').to be true
      random_url = "https://google.com/?q=#{rand 1000..9999}"
      expect(File.read 'Formula/hack-assembler.rb').not_to include(random_url)
      tap.on_formula! 'hack-assembler' do |f|
        f.put_sdist random_url, "sha256abcd"
      end
      expect(File.read 'Formula/hack-assembler.rb').to include(random_url)
    end
  end

end
