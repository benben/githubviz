$LOAD_PATH << "./lib"
$:.unshift File.expand_path(File.dirname(__FILE__))
require "lib/githubviz"

run GithubViz
