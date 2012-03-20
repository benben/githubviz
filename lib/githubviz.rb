#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'github-v3-api'


MAX_LEVELS = 2

class GithubViz < Sinatra::Base

set :public_directory, Proc.new { File.join(root, "public") }
set :public_folder, File.dirname(__FILE__) + '/public'

def get_data
  if @level < MAX_LEVELS
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
  @result = {}
  erb :index
end

post '/' do
  @level = 0

  @data = {}

  @result = {}

  @user = params[:user]
  if @user


    @api = GitHubV3API.new(ENV['GITHUB_API_KEY'])

    @data[@user] = @api.get("/users/#{@user}")
    @data[@user]['level'] = 0
    @data[@user]['follower_count'] = @data[@user]['followers']
    @data[@user]['followers'] = @api.get("/users/#{@user}/followers")
    get_data
    process_data
  end
  erb :index
end

end
