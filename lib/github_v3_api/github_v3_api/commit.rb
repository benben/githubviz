# See GitHubV3API documentation in lib/github_v3_api.rb
class GitHubV3API
  # Represents a single GitHub Pull Request and provides access to its data attributes.
  class Commit < Entity
    attr_reader :url, :author, :committer, :message
    
  end
  
end
