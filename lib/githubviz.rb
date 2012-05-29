#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'active_record'

class Request < ActiveRecord::Base
end

class ApiConnection

  require 'github_v3_api/github_v3_api.rb'

  def initialize api_key
    puts "#{Time.now}: Initializing ApiConnection..."
    @connection = GitHubV3API.new(api_key)
  end

  def get url, paging=false
    if paging
      result = []
      (paging / 30.0).ceil.times do |page|
        result += @connection.get "#{url}?page=#{page+1}"
      end
    else
      @connection.get url
    end
  end

  NoApiKeyError = Class.new(StandardError)
end

class GithubViz < Sinatra::Base

set :app_file, __FILE__

require 'config'

begin
  @@api = ApiConnection.new ENV['GITHUB_API_KEY']
rescue ArgumentError
  raise ApiConnection::NoApiKeyError, "Please set the ENV['GITHUB_API_KEY'] var"
end

ActiveRecord::Base.establish_connection(@@config)
ActiveRecord::Base.connection

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
   @data[@user] = @@api.get("/users/#{@user}")
end

def filter_data
  @data[@user]['level'] = 0
  @data[@user]['follower_count'] = @data[@user]['followers']
  @data[@user]['followers'] = @@api.get("/users/#{@user}/followers")
  @data[@user]['user'] = @@api.get("/users/#{@user}")
end

def get_data
  if @level < @MAX_LEVELS
    t = {}
    @data.each do |k,v|
      if v['level'] == @level
        @@api.get("/users/#{k}/followers").each do |f|
          unless @data.has_key? f['login']
            t[f['login']] = f
            t[f['login']]['level'] = @level+1
            t[f['login']]['follower_count'] = 0
            t[f['login']]['followers'] = @@api.get("/users/#{f['login']}/followers")
            t[f['login']]['user'] = @@api.get("/users/#{f['login']}")
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

  @result['nodes'].map!{|n| {
    "name" => n,
    "group" => 1,
    "img" => @data[n]['avatar_url'],
    "profilseite" => @data[n]['user']['html_url'],
    "follower_count" => @data[n]['follower_count'],
    "color" => "",
    "public_repos" => @data[n]['user']['public_repos']
  }}

  script_language

end

def script_language
  origin = 0
  counter = 0
  @color = ["#FF0000", "#FF8000", "#FFFF00", "#80FF00", "#00FF80", "#00FFFF", "#0080FF", "#0000FF", "#8000FF", "#FF00FF", "#FF0080", "#000000", "#A9A9A9", "#800000", "#804000", "#808000", "#008040", "#008080", "#004080", "#800060" ]

  @result['nodes'].each do |user|
    @repos = @@api.get("/users/#{user['name']}/repos", user['public_repos'])
    languages = {}
    if @repos.count == 0
      user['scriptlanguage'] = 'nothing'
    else
      @repos.each do |repo|
        if languages.has_key? repo['language']
          languages[repo['language']] += 1
        else
          languages[repo['language']] = 1
        end
      end

      most_used_languages = {}
      languages.each do |lang_name, lang_count|
        if most_used_languages.has_key? lang_count
          most_used_languages[lang_count] << lang_name
        else
          most_used_languages[lang_count] = [lang_name]
        end
      end
      #{12 => ["Ruby", "C++"], 5 => ["Javascript"], 3 => ['HTML', 'CSS']}

      user['scriptlanguage'] = most_used_languages.sort {|a,b| b[0] <=> a[0]}[0][1]
      #['C++', 'Ruby']
    end
  end

  #prepring to get legend for scriptlanguages
  @scriptlanguage_legend = []
  @result['nodes'].each do |user|
    @scriptlanguage_legend << {"lang" => user['scriptlanguage'], "count" => 0, "color" => ""}
  end
  @legend = @scriptlanguage_legend.uniq
  #add colors for languages
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
  #get languages, count them and add color to result
  @legend.each do |lang|
    @result['nodes'].each do |lang2|
      if lang["lang"] == lang2["scriptlanguage"] then
        lang["count"] += 1
        lang["color"] = @color[counter]
        lang2["color"] = @color[counter]
      end
    end
    counter += 1
  end
  #language sort descending by counts
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

  user_data = @@api.get("/users/#{@user}")

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
    @data[@user] = @@api.get("/users/#{@user}")
    @data[@user]['level'] = 0
    @data[@user]['follower_count'] = @data[@user]['followers']
    @data[@user]['followers'] = @@api.get("/users/#{@user}/followers")
    @data[@user]['user'] = @@api.get("/users/#{@user}")
    get_data
    process_circle_data
    end
  erb :circle
end

end
