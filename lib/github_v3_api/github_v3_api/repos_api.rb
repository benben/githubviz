# See GitHubV3API documentation in lib/github_v3_api.rb
class GitHubV3API
  # Provides access to the GitHub Repos API (http://developer.github.com/v3/repos/)
  #
  # example:
  #
  #   api = GitHubV3API.new(ACCESS_TOKEN)
  #
  #   # get list of all of the user's public and private repos
  #   repos = api.repos.list
  #   #=> returns an array of GitHubV3API::Repo instances
  #
  #   repo = api.repos.get('octocat', 'hello-world')
  #   #=> returns an instance of GitHubV3API::Repo
  #
  #   repo.name
  #   #=> 'hello-world'
  #
  class ReposAPI
    # Typically not used directly. Use GitHubV3API#repos instead.
    #
    # +connection+:: an instance of GitHubV3API
    def initialize(connection)
      @connection = connection
    end

    # Returns an array of GitHubV3API::Repo instances representing the
    # user's public and private repos
    def list
      @connection.get('/user/repos').map do |repo_data|
        GitHubV3API::Repo.new(self, repo_data)
      end
    end

    # Returns an array of GitHubV3API::User instances for the collaborators of the
    # specified +user+ and +repo_name+.
    #
    # +user+:: the string ID of the user, e.g. "octocat"
    # +repo_name+:: the string ID of the repository, e.g. "hello-world"

    def list_collaborators(user, repo_name)
      @connection.get("/repos/#{user}/#{repo_name}/collaborators").map do |user_data|
      GitHubV3API::User.new(self, user_data)
      end
    end

    def list_watchers(user, repo_name)
      @connection.get("/repos/#{user}/#{repo_name}/watchers").map do |user_data|
        GitHubV3API::User.new(self, user_data)
      end
    end

     # Returns an array of GitHubV3API::Repo instances containing the repositories
    # which were forked from the repository specified by +user+ and +repo_name+.
    #
    # +user+:: the string ID of the user, e.g. "octocat"
    # +repo_name+:: the string ID of the repository, e.g. "hello-world"
    def list_forks(user, repo_name)
      @connection.get("/repos/#{user}/#{repo_name}/forks").map do |repo_data|
        GitHubV3API::Repo.new(self, repo_data)
      end
    end
    # Returns an array of GitHubV3API::Repo instance containing the repositories 
    # for the specified +user+ and +page+.
    #
    # +user+:: the string ID of the user, e.g. "octocat"
    # +page+:: the int for the page of the repo list, e.g. "1" for repo 1 - 30 (each page includes max 30 repos)
    def list_repos(user, page)
      @connection.get("/users/#{user}/repos?page=#{page}").map do |repo_data|
      GitHubV3API::Repo.new(self, repo_data)
      end
    end
    # Returns a GitHubV3API::Repo instance for the specified +user+ and
    # +repo_name+.
    #
    # +user+:: the string ID of the user, e.g. "octocat"
    # +repo_name+:: the string ID of the repository, e.g. "hello-world"
    def get(user, repo_name)
      org_data = @connection.get("/repos/#{user}/#{repo_name}")
      GitHubV3API::Repo.new_with_all_data(self, org_data)
    rescue RestClient::ResourceNotFound
      raise NotFound, "The repository #{user}/#{repo_name} does not exist or is not visible to the user."
    end
    
    #def get_pr(user, repo_name)
     # org_data = @connection.get("/repos/#{user}/#{repo_name}/pulls")
      #GitHubV3API::Pull.new_with_all_data(self, org_data)
   # rescue RestClient::ResourceNotFound
    #  raise NotFound, "The repository #{user}/#{repo_name} does not exist or is not visible to the user."
    #end
    
  end 
  
end
