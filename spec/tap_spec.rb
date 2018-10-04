
require 'homebrew_automation/tap.rb'

describe "HomebrewAutomation::Tap" do

  let (:user) { 'easoncxz' }
  let (:repo) { 'homebrew-tap' }
  let (:token) { ENV['EASONCXZ_GITHUB_OAUTH_TOKEN'] }

  let (:tap) { HomebrewAutomation::Tap.new(user, repo, token) }

  it 'can run once, almost end to end' do
    expect(File.exists? repo).to eq(false)
    tap.with_git_clone do
      expect(File.basename Dir.pwd).to eq(repo)
      expect(Dir.exists? 'Formula').to eq(true)

      random_url = "https://google.com/?q=#{rand 1000..9999}"
      tap.on_formula 'hack-assembler' do |f|
        f.put_sdist random_url, "sha256abcd"
      end
      expect(File.read 'Formula/hack-assembler.rb').to include(random_url)
      expect(`git status --short`).not_to eq('')

      tap.git_commit_am 'just testing'
      expect(`git status --short`).to eq('')
    end
    expect(File.exists? repo).to eq(false)
  end

end
