# See GitHubV3API documentation in lib/github_v3_api.rb
class GitHubV3API
  # Provides access to the GitHub Repos API (http://developer.github.com/v3/repos/)
  #
  
  class CommitsAPI
   
    def initialize(connection)
      @connection = connection
    end

    def list(user, repo_name)
      @connection.get("/repos/#{user}/#{repo_name}/commits").map do |commit_data|
      GitHubV3API::Commit.new(self, commit_data)
      end
    end
    
  end 
  
end
