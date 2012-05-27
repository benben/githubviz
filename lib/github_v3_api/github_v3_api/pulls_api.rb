# See GitHubV3API documentation in lib/github_v3_api.rb
class GitHubV3API
  # Provides access to the GitHub Repos API (http://developer.github.com/v3/repos/)
  #
  
  class PullsAPI
    # Typically not used directly. Use GitHubV3API#repos instead.
    #
    # +connection+:: an instance of GitHubV3API
    def initialize(connection)
      @connection = connection
    end

    def list(user, repo_name)
      @connection.get("/repos/#{user}/#{repo_name}/pulls").map do |pull_data|
      GitHubV3API::Pull.new(self, pull_data)
      end
    end
    
     def list_closed(user, repo_name)
      @connection.get("/repos/#{user}/#{repo_name}/pulls?state=closed").map do |pull_data|
      GitHubV3API::Pull.new(self, pull_data)
      end
    end
    
    #def get(user, repo_name)
     # org_data = @connection.get("/repos/#{user}/#{repo_name}/pulls")
      #GitHubV3API::Pull.new_with_all_data(self, org_data)
    #rescue RestClient::ResourceNotFound
     # raise NotFound, "The repository #{user}/#{repo_name} does not exist or is not visible to the user."
    #end
    
    #def get_pr(user, repo_name)
     # org_data = @connection.get("/repos/#{user}/#{repo_name}/pulls")
      #GitHubV3API::Pull.new_with_all_data(self, org_data)
   # rescue RestClient::ResourceNotFound
    #  raise NotFound, "The repository #{user}/#{repo_name} does not exist or is not visible to the user."
    #end
    
  end 
  
end
