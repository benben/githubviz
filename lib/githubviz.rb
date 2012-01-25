#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'github-v3-api'


MAX_LEVELS = 2

set :public_directory, Proc.new { File.join(root, "public") }

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


    @api = GitHubV3API.new('c1616feca6aa3e63655dd92766a475c2227ed6a0')

    @data[@user] = @api.get("/users/#{@user}")
    @data[@user]['level'] = 0
    @data[@user]['follower_count'] = @data[@user]['followers']
    @data[@user]['followers'] = @api.get("/users/#{@user}/followers")
    get_data
    process_data
  end
  erb :index
end

__END__

@@ index
<html>
  <head>
    <meta http-equiv="content-type" content="text/html;charset=utf-8">
    <title>githubviz</title>
    <script type="text/javascript" src="d3.js?2.7.2"></script>
    <style>
      circle.node {
        stroke: #fff;
        stroke-width: 1.5px;
      }

      line.link {
        stroke: #999;
        stroke-opacity: .6;
      }

      * {
        margin:0px;
        padding: 0px;
      }
    </style>
  </head>
  <body>
    <div id="header">
    <div style="float:left;">
    <h1>githubviz</h1>
    </div>
    <div style="padding-top:10px;">
    <form action="/" method="post">
      <label>Enter your username:</label>
      <input name="user" type="text">
      <input type="submit" value="Do it!">
    </form>
    </div>
    </div>
    <% if @result.length > 0 %>
    <div style="clear:left;">
      <div class='gallery' id='chart'> </div>
    </div>
    <script src='d3.layout.js?2.7.2' type='text/javascript'></script>
    <script src='d3.geom.js?2.7.2' type='text/javascript'> </script>
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js"></script>
    <script type='text/javascript'>
    $(function (){

      var w = $(window).width(),
          h = $(window).height() - $("#header").height() -20,
          fill = d3.scale.category20();

      var vis = d3.select("#chart").append("svg")
          .attr("width", w)
          .attr("height", h);

        var json = <%= @result.to_json %>;//{"nodes":[{"name":"juliane","group":1,"img":"https://secure.gravatar.com/avatar/5bd2a03ffe77cfb6f1abc0fb3cc18663?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png","follower_count":1},{"name":"benben","group":1,"img":"https://secure.gravatar.com/avatar/614a4e493d7c353296519bba720e77c5?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png","follower_count":0},{"name":"JuliAne","group":1,"img":"https://secure.gravatar.com/avatar/5bd2a03ffe77cfb6f1abc0fb3cc18663?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png","follower_count":0},{"name":"rzschoch","group":1,"img":"https://secure.gravatar.com/avatar/8da5b48f92cf4acd420f8a0501f551bb?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png","follower_count":0},{"name":"toxin20","group":1,"img":"https://secure.gravatar.com/avatar/29a3b85e704ec06a72df8897a726920e?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png","follower_count":0},{"name":"oferreiro","group":1,"img":"https://secure.gravatar.com/avatar/556d6126a97bd84eda05e4d171a09cc3?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png","follower_count":0},{"name":"foospy","group":1,"img":"https://secure.gravatar.com/avatar/3a72e15146a263e2fe7a5128b8370bf1?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png","follower_count":0},{"name":"underdoeg","group":1,"img":"https://secure.gravatar.com/avatar/6ff8fe2dd72480f1685ee15e374205b7?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png","follower_count":0},{"name":"lennyjpg","group":1,"img":"https://secure.gravatar.com/avatar/48a9cc3bdc4dc863b352b35d295da1c8?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png","follower_count":0},{"name":"bascht","group":1,"img":"https://secure.gravatar.com/avatar/8656dc5476c819d4dcbd932a5744122a?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png","follower_count":0},{"name":"charlenopires","group":1,"img":"https://secure.gravatar.com/avatar/4f03547679f181e7aa0747f97990d9ff?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png","follower_count":0},{"name":"m9dfukc","group":1,"img":"https://secure.gravatar.com/avatar/dd9bcb2492b9e1d7de126ba78247f6ac?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png","follower_count":0},{"name":"timscaffidi","group":1,"img":"https://secure.gravatar.com/avatar/2ad43b65cb02eca2b722133681647492?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png","follower_count":0},{"name":"rtomas","group":1,"img":"https://secure.gravatar.com/avatar/005c9f21f1dd00f8117998ae8c3a9370?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png","follower_count":0},{"name":"kennon","group":1,"img":"https://secure.gravatar.com/avatar/2e61dc774247ac88118e16b47c4b0588?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png","follower_count":0},{"name":"lhm","group":1,"img":"https://secure.gravatar.com/avatar/84019fbfc27bc409b13ee769660ff55a?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png","follower_count":0},{"name":"casualistic","group":1,"img":"https://secure.gravatar.com/avatar/2013e02085a028693db427268ef52389?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png","follower_count":0},{"name":"tobaco","group":1,"img":"https://secure.gravatar.com/avatar/0b8547484330973d9fd6053d3281e93d?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png","follower_count":0},{"name":"einspunktnull","group":1,"img":"https://secure.gravatar.com/avatar/17e1af3581ecfce9146f6420ee39125b?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png","follower_count":0},{"name":"skylamer","group":1,"img":"https://secure.gravatar.com/avatar/d4465dbe8f27acebdabe4ce016e534a5?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png","follower_count":0},{"name":"DudleySmith","group":1,"img":"https://secure.gravatar.com/avatar/c0dd77c69bd4a4c30f556ac31c06634c?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png","follower_count":0},{"name":"t-p","group":1,"img":"https://secure.gravatar.com/avatar/2ca880149f8052195672ed21777b0fb9?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png","follower_count":0}],"links":[{"source":0,"target":1,"value":1},{"source":1,"target":2,"value":1},{"source":1,"target":3,"value":1},{"source":1,"target":4,"value":1},{"source":1,"target":5,"value":1},{"source":1,"target":6,"value":1},{"source":1,"target":7,"value":1},{"source":1,"target":8,"value":1},{"source":1,"target":9,"value":1},{"source":1,"target":10,"value":1},{"source":1,"target":11,"value":1},{"source":1,"target":12,"value":1},{"source":1,"target":13,"value":1},{"source":1,"target":14,"value":1},{"source":1,"target":15,"value":1},{"source":1,"target":16,"value":1},{"source":1,"target":17,"value":1},{"source":1,"target":18,"value":1},{"source":1,"target":19,"value":1},{"source":1,"target":20,"value":1},{"source":1,"target":21,"value":1},{"source":2,"target":1,"value":1},{"source":3,"target":1,"value":1},{"source":3,"target":14,"value":1},{"source":3,"target":19,"value":1},{"source":7,"target":8,"value":1},{"source":7,"target":1,"value":1},{"source":7,"target":4,"value":1},{"source":7,"target":11,"value":1},{"source":8,"target":7,"value":1},{"source":9,"target":1,"value":1},{"source":11,"target":7,"value":1},{"source":12,"target":11,"value":1},{"source":14,"target":1,"value":1},{"source":14,"target":19,"value":1},{"source":15,"target":1,"value":1},{"source":18,"target":1,"value":1},{"source":21,"target":1,"value":1}]};
        //
           //d3.json("miserables.json", function(json) {
        var force = d3.layout.force()
            .charge(-500)
            .linkDistance(275)
            .gravity(0.8)
            .linkStrength(0.2)
            .nodes(json.nodes)
            .links(json.links)
            .size([w, h])
            .start();

        var link = vis.selectAll("line.link")
            .data(json.links)
          .enter().append("line")
            .attr("class", "link")
            .style("stroke-width", function(d) { return Math.sqrt(d.value); })
            .attr("x1", function(d) { return d.source.x; })
            .attr("y1", function(d) { return d.source.y; })
            .attr("x2", function(d) { return d.target.x; })
            .attr("y2", function(d) { return d.target.y; });

        var node = vis.selectAll("image.node")
            .data(json.nodes)
              .enter().append("svg:image")
            .attr("xlink:href", function(d) { return d.img; })
            //.attr("class", "node")
            .attr("width", "25px")
            .attr("height", "25px")
            .attr("x", function(d) { return d.x-12.5; })
            .attr("y", function(d) { return d.y-12.5; })
            //.attr("r", 50)
            //.style("fill", function(d) { return fill(d.follower_count); })
            .call(force.drag);

        node.append("title")
            .text(function(d) { return d.name; });

        force.on("tick", function() {
          link.attr("x1", function(d) { return d.source.x; })
              .attr("y1", function(d) { return d.source.y; })
              .attr("x2", function(d) { return d.target.x; })
              .attr("y2", function(d) { return d.target.y; });

          node.attr("x", function(d) { return d.x-12.5; })
          .attr("y", function(d) { return d.y-12.5; });
        //});
      });
    });


    </script>
    <% end %>
  </body>
</html>
