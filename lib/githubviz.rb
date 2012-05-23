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
  
  #script_language
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
