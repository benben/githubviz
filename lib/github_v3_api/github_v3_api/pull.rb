# See GitHubV3API documentation in lib/github_v3_api.rb
class GitHubV3API
  # Represents a single GitHub Pull Request and provides access to its data attributes.
  class Pull < Entity
    attr_reader :url, :title, :number, :state, :created_at, :updated_at, :closed_at, :merged_at, :user
  end
  
end
