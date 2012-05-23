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
  
  script_language
end

def script_language
  origin = 0
  counter = 0
  @color = ["#FF0000", "#FF8000", "#FFFF00", "#80FF00", "#00FF80", "#00FFFF", "#0080FF", "#0000FF", "#8000FF", "#FF00FF", "#FF0080", "#000000", "#A9A9A9", "#800000", "#804000", "#808000", "#008040", "#008080", "#004080", "#800060" ]
  
  @result['nodes'].each do |user|
    user_data = @api.users.get(user['name'])
    page = 1
    count = 30
    user_repos = Array.new 
      
    while user_data.public_repos > count do
      page = page +1
      count = count + 30
    end
  
    while page >= 1 do
      user_repos[page-1] = @api.repos.list_repos(user['name'], page)
      page = page - 1
    end

    @repos = user_repos
    #get repo languages of a git user
    @j = {}
    start = 0
    @j["repos"] = [] 
    @j["repo_data"] = []
    @j["language"] = []
    @j["sort"] = {}
    @j["max_lang"]=[]
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
    unless @sort.empty?
      @sort.each do |scriptlanguage|
        if scriptlanguage[1] == @sort[0][1] then
          @j["max_lang"] << scriptlanguage[0]
        end
      end
    else
      @j["max_lang"] << "nothing"
    end  
    user['scriptlanguage'] = @j["max_lang"]
  end
  @scriptlanguage_legend = []
  @result['nodes'].each do |user|
    @scriptlanguage_legend << {"lang" => user['scriptlanguage'], "count" => 0, "color" => ""}
  end
  @legend = @scriptlanguage_legend.uniq
  
  if @legend.count <= @color.count then
   @color = @color
  else
   color_adder = @legend.count - @color.count
   while color_adder > 0
     @color[@color.count - 1 + color_adder] = @color[origin]
     color_adder -= 1
     origin += 1
   end 
  end
  
  @legend.each do |lang|
    @scriptlanguage_legend.each do |lang2|
      if lang["lang"] == lang2["lang"] then
        lang["count"] += 1
        lang["color"] = @color[counter]
        lang2["color"] = @color[counter]
      end
    end
    counter += 1
  end
  
  @legend = @legend.sort_by {|k| -k['count'] }
  
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
  
  @page = 1
  @count = 30
  @user_repos = Array.new 
  
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
