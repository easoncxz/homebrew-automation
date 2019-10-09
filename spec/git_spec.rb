
require 'fileutils'

require 'homebrew_automation/git.rb'

describe HomebrewAutomation::Git do

  let(:git) { HomebrewAutomation::Git }
  let(:random_tapname) { "sample-repo-#{rand 1000..9999}" }
  let(:rb_project_root) { File.realpath('.') }

  it 'can clone a filepath as URL' do
    expect(Dir.exists? random_tapname).to be false
    expect(rb_project_root).to include 'homebrew-automation'
    expect(File.basename rb_project_root).to eq 'homebrew-automation'
    git.with_clone! rb_project_root, random_tapname do
      expect(File.basename Dir.pwd).to eq random_tapname
      expect(File.exists? 'Rakefile').to be true
      expect(Dir.exists? '.git').to be true
      expect(Dir.exists? '../.git').to be true
    end
    expect(Dir.exists? random_tapname).to be false
  end

  it 'keeps the tap repo dir if keep_dir is passed' do
    begin
      git.with_clone! rb_project_root, random_tapname, keep_dir: true do end
      expect(Dir.exists? random_tapname).to be true
    ensure
      FileUtils.remove_entry random_tapname
      expect(File.exists? random_tapname).to be false
    end
  end

  it "doesn't fail in case of no block passed" do
    begin
      git.with_clone! rb_project_root, random_tapname
      expect(Dir.exist? random_tapname).to be false
    ensure
      begin
        FileUtils.remove_entry random_tapname
      rescue Errno::ENOENT
        nil
      end
    end
  end

  it "can keep_dir in case of no block passed" do
    begin
      git.with_clone! rb_project_root, random_tapname, keep_dir: true
      expect(Dir.exists? random_tapname).to be true
    ensure
      FileUtils.remove_entry random_tapname
      expect(File.exists? random_tapname).to be false
    end
  end

end
