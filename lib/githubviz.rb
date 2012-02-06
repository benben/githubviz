#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'

class GithubViz < Sinatra::Base

require 'github-v3-api.rb'

set :public_directory, Proc.new { File.join(root, "public") }
set :public_folder, File.dirname(__FILE__) + '/public'

def get_data
  if @level < @MAX_LEVELS
    t = {}
    @data.each do |k,v|
      if v['level'] == @level
        @api.get("/users/#{k}/followers").each do |f|
          unless @data.has_key? f['login']
            t[f['login']] = f
            t[f['login']]['level'] = @level+1
            t[f['login']]['follower_count'] = 0
            t[f['login']]['followers'] = @api.get("/users/#{f['login']}/followers")
          end
        end
      end
    end
    @data.merge! t
    @level += 1
    get_data
  end
end

def process_data
  @result['nodes'] = @data.keys
  @result['links'] = []

  @data.each do |k,v|
    v['followers'].each do |f|
      @result['links'] << {
        "source" => @result['nodes'].index(k),
        "target" => @result['nodes'].index(f['login']),
        "value" => 1
      } if @result['nodes'].index(f['login'])
    end
  end

  @result['nodes'].map!{|n| {"name" => n, "group" => 1, "img" => @data[n]['avatar_url'], "follower_count" => @data[n]['follower_count']}}
end

get '/' do
  erb :index
end

get '/follower_viz' do

  @level = 0	

  @data = {}

  @result = {"1" => "1"}

  @MAX_LEVELS = params[:level].to_i

  @user = params[:user]
  
  if @user

    @api = GitHubV3API.new('c1616feca6aa3e63655dd92766a475c2227ed6a0')

    @data[@user] = @api.get("/users/#{@user}")
    @data[@user]['level'] = 0
    @data[@user]['follower_count'] = @data[@user]['followers']
    @data[@user]['followers'] = @api.get("/users/#{@user}/followers")
    get_data
    process_data
    end
  erb :follower
end

get '/repo_viz' do
  @user = params[:user]
  @api = GitHubV3API.new('c1616feca6aa3e63655dd92766a475c2227ed6a0')
  user_data = @api.users.get(@user)
  my_repos = @api.repos.list
  page = 1
  count = 30
  user_repos = Array.new 
      
  while user_data.public_repos > count do
  page = page +1
  count = count + 30
  end
  
  while page >= 1 do
  user_repos[page-1] = @api.repos.list_repos(@user, page)
  page = page - 1
  end
    
  a = 0 
  b = 0 
  c = 0
  repo_name = Array.new
  pr = Array.new
  pr_closed = Array.new
  pulldata = Array.new  
  closed_pulldata = Array.new 
  merge = ""
  
  user_repos.each do |page|
    page.each do |repo|
    if repo.fork == true then
       a = a + 1  
       repo_name[a-1] = [repo.name, repo.source["owner"]["login"]]
       pr[a-1] = {"pr_repodata" => @api.pulls.list(repo.source["owner"]["login"], repo.name), "repoowner" => repo.source["owner"]["login"], "reponame" => repo.name}
       pr_closed[a-1] = {"closed_pr_repodata" => @api.pulls.list_closed(repo.source["owner"]["login"], repo.name), "repoowner" => repo.source["owner"]["login"], "reponame" => repo.name}
    else
       a = a
    end
    end
  end
  
  pr.each do |pull|
    pull["pr_repodata"].each do |pullrequest|
       if pullrequest["user"]["login"] == @user then
           b = b + 1
           pulldata[b-1] = {"url" => pullrequest.url, "state" => pullrequest.state, "reponame" => pull["reponame"], "repoowner" => pull["repoowner"], "sum_pulls" => pull["pr_repodata"].length} 
       else
           b = b    
       end
    end
  end
  
  pr_closed.each do |closed_pull|
    closed_pull["closed_pr_repodata"].each do |closed_pullrequest|
       if closed_pullrequest["user"]["login"] == @user then
           c = c + 1
           #if closed_pullrequest.merged_at.nil? then 
            # merge = "" 
           #else 
            # merge = closed_pullrequest.merged_at 
           #end
           closed_pulldata[c-1] = {"title" => closed_pullrequest.title, "state" => closed_pullrequest.state, "created_at" => closed_pullrequest.created_at, "updated_at" => closed_pullrequest.updated_at, "closed_at" => closed_pullrequest.closed_at, "reponame" => closed_pull["reponame"], "repoowner" => closed_pull["repoowner"], "sum_pulls" => closed_pull["closed_pr_repodata"].length} 
       else
           c = c    
       end
    end
  end
  
  @pr_open = pr
  @number_of_forks = a
  @number_of_pulls = b
  @number_of_closed_pulls = c
  @number_of_all_pulls = b + c
  @pulldata = pulldata
  @closed_pulldata = closed_pulldata
  @reponame = repo_name
  @repos = user_repos
  
  @j = {}
  
  @j["repos"] = []
  @repos.each do |page|
    page.each do |repo|
    @j["repos"] << {"name" => repo.name, "size" => repo.size}
  end
  end

  erb :repo
end

get '/commit_viz' do
  @user = params[:user]
  erb :commit
end

get '/circle_viz' do
  @api = GitHubV3API.new('c1616feca6aa3e63655dd92766a475c2227ed6a0')
  @user = params[:user]
  user_data = @api.users.get(@user)
  #@data[@user] = @api.get("/users/#{@user}")
  #@data[@user]['follower_count'] = @data[@user]['followers']
  #@data[@user]['followers'] = @api.get("/users/#{@user}/followers")
  erb :circle
end

end
