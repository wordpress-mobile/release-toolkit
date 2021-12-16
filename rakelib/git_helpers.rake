module GitHelper
  def self.current_branch
    `git --no-pager branch --show-current`.chomp
  end

  def self.check_or_create_branch(new_version)
    release_branch = "release/#{new_version}"
    branch_exists = !`git --no-pager branch -a --list --no-color #{release_branch}`.chomp.empty?
    if current_branch == release_branch
      puts 'Already on release branch'
    elsif branch_exists
      Rake.sh('git', 'checkout', release_branch)
    else # create it
      abort('Aborted, as not run from trunk nor release branch') unless current_branch == 'trunk' || Console.confirm("You are not on 'trunk', nor already on '#{release_branch}'. Do you really want to cut the release branch from #{current_branch}?")

      Rake.sh('git', 'checkout', '-b', release_branch)
    end
  end

  def self.prepare_github_pr(head, base, title, body)
    require 'open-uri'
    qtitle = title.gsub(' ', '%20')
    qbody = body.gsub(' ', '%20')
    uri = "https://github.com/wordpress-mobile/release-toolkit/compare/#{base}...#{head}?expand=1&title=#{qtitle}&body=#{qbody}"
    Rake.sh('open', uri)
  end

  def self.commit_files(message, files, push: true)
    Rake.sh('git', 'add', *files)
    Rake.sh('git', 'commit', '-m', message)
    Rake.sh('git', 'push', '-q', 'origin', current_branch) if push
  end
end
