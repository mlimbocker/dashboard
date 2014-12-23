require 'github_api'

#let's set up the github client
github = Github.new basic_auth: 'mlimbocker:p4nda_17'

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '1m', :first_in => 0 do |job|

	commits = github.repos(user: 'brushfiretech', repo: 'brushfire').commits.list

	if commits
		commits = commits.map do |c|
			{ 
        name: c.commit.committer.name, 
        avatar: c.committer.avatar_url, 
        body: c.commit.message 
      }
		end
  		send_event('github_commits', { comments: commits })
  	end

  	contributors = github.repos(user: 'brushfiretech', repo: 'brushfire').stats.contributors

  	if contributors
  		contributors = contributors.map do |c|
  			{ 
  				name: c.author.login, 
  				body: c.total,
          avatar: c.author.avatar_url
  			}
  		end
  		send_event('github_contributors', { comments: contributors })
  	end
end