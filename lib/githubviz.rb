#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'


class GithubViz < Sinatra::Base

require 'github-v3-api.rb'

set :app_file, __FILE__
#set :views, File.dirname(__FILE__) + '/views'
#set :public_directory, Proc.new { File.join(root, "public") }
#set :public_folder, File.dirname(__FILE__) + '/public'

def process_circle_data
   @test = {}
   @test['data'] = {}
   @circle_result = @data.keys
   @data.each do |k,v|
    @test['data'][@circle_result.index(k)]= []
    v['followers'].each do |f|
      @test['data'][@circle_result.index(k)]<<  f['login']
    end
   end
   @circle_result.map! {|n|{"name" => n, "imports" => @test['data'][@circle_result.index(n)]}} 
end

def aquire_data
   @api = GitHubV3API.new(ENV['GITHUB_API_KEY'])
   @data[@user] = @api.get("/users/#{@user}")
end

def filter_data
  @data[@user]['level'] = 0
  @data[@user]['follower_count'] = @data[@user]['followers']
  @data[@user]['followers'] = @api.get("/users/#{@user}/followers")
  @data[@user]['user'] = @api.get("/users/#{@user}")
end

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
            t[f['login']]['user'] = @api.get("/users/#{f['login']}")
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

  @result['nodes'].map!{|n| {"name" => n, "group" => 1, "img" => @data[n]['avatar_url'], "profilseite" => @data[n]['user']['html_url'], "follower_count" => @data[n]['follower_count']}}
end

def represent
  erb :follower
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
    aquire_data
    filter_data
    get_data
    process_data
    represent
  end
end

get '/repo_viz' do
  @user = params[:user]

  @api = GitHubV3API.new(ENV['GITHUB_API_KEY'])
 

  user_data = @api.users.get(@user)
  #my_repos = @api.repos.list
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
    
  #a = 0 
  #b = 0 
  #c = 0
  #repo_name = Array.new
  #pr = Array.new
  #pr_closed = Array.new
  #pulldata = Array.new  
  #closed_pulldata = Array.new 
  #merge = ""
  
  # user_repos.each do |page|
    # page.each do |repo|
    # if repo.fork == true then
       # a = a + 1  
       # repo_name[a-1] = [repo.name, repo.source["owner"]["login"]]
       # pr[a-1] = {"pr_repodata" => @api.pulls.list(repo.source["owner"]["login"], repo.name), "repoowner" => repo.source["owner"]["login"], "reponame" => repo.name}
       # pr_closed[a-1] = {"closed_pr_repodata" => @api.pulls.list_closed(repo.source["owner"]["login"], repo.name), "repoowner" => repo.source["owner"]["login"], "reponame" => repo.name}
    # else
       # a = a
    # end
    # end
  # end
#   
 # pr.each do |pull|
      # pull["pr_repodata"].each do |pullrequest|
        # if pullrequest["user"]["login"] == @user then
          # b = b + 1
          # pulldata[b-1] = {"url" => pullrequest.url, "state" => pullrequest.state, "reponame" => pull["reponame"], "repoowner" => pull["repoowner"], "sum_pulls" => pull["pr_repodata"].length}
        # else
        # b = b
        # end
      # end
    # end
# 
    # pr_closed.each do |closed_pull|
      # closed_pull["closed_pr_repodata"].each do |closed_pullrequest|
        # if closed_pullrequest["user"]["login"] == @user then
          # c = c + 1
          # #if closed_pullrequest.merged_at.nil? then
          # # merge = ""
          # #else
          # # merge = closed_pullrequest.merged_at
          # #end
          # closed_pulldata[c-1] = {"title" => closed_pullrequest.title, "state" => closed_pullrequest.state, "created_at" => closed_pullrequest.created_at, "updated_at" => closed_pullrequest.updated_at, "closed_at" => closed_pullrequest.closed_at, "reponame" => closed_pull["reponame"], "repoowner" => closed_pull["repoowner"], "sum_pulls" => closed_pull["closed_pr_repodata"].length}
        # else
        # c = c
        # end
      # end
    # end
# 
    # @pr_open = pr
    # @number_of_forks = a
    # @number_of_pulls = b
    # @number_of_closed_pulls = c
    # @number_of_all_pulls = b + c
    # @pulldata = pulldata
    # @closed_pulldata = closed_pulldata
    # @reponame = repo_name
  
  
  @repos = user_repos
  
  #get repo languages of a git user
  @j = {}
  start = 0
  @j["repos"] = [] 
  @j["repo_data"] = []
  @j["language"] = []
  @j["sort"] = {}
  @repos.each do |page|
    page.each do |repo|
     @j["repos"] << {"language"=>repo.language,"count" => 0}
    end
  end
  
  #remove doubles for comparing languages and count them
  @j["repo_data"] = @j["repos"].uniq
 
  #comparing languages of all repos and count them
  @j["repo_data"].each do |language1|
    @j["repos"].each do |language2|
      if language1["language"] == language2["language"] then
        language1["count"] += 1
       
      end
    end
    @j["sort"].store(language1["language"], language1["count"])
  end
  
  @sort = @j["sort"].sort_by {|key, value| -value}
  #@j["repo_data"].sort_by { |a| [ a.count] }
  #building treshold for languages
  
  # treshold = 0.5
  # base = @j["repos"].length 
  # base.to_f
  # @j["repo_data"].each do |language|
#     
    # if (language["count"].to_f / base) >= treshold then
      # @j["language"] <<  language["language"]
    # end
  # end
  
  erb :repo
end

get '/commit_viz' do
  @user = params[:user]
  erb :commit
end

get '/circle_viz' do
  @level = 0 
  @circle_result = {}
  @data = {}
  @user = params[:user]
  @MAX_LEVELS = 1 
if @user
    @api = GitHubV3API.new(ENV['GITHUB_API_KEY'])
    @data[@user] = @api.get("/users/#{@user}")
    @data[@user]['level'] = 0
    @data[@user]['follower_count'] = @data[@user]['followers']
    @data[@user]['followers'] = @api.get("/users/#{@user}/followers")
    @data[@user]['user'] = @api.get("/users/#{@user}")
    get_data
    process_circle_data
    end  
  erb :circle
end

end
