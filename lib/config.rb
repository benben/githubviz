$:.unshift File.expand_path(File.dirname(__FILE__))

env    = ENV['RACK_ENV'] || "development"

if env == 'development'
  require 'sqlite3'
else
  require 'pg'
end

begin
  @@config = YAML.load_file('database.yml')[env]
rescue
  db = URI.parse(ENV['DATABASE_URL'])

  @@config = {
    "adapter" => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
    "host" => db.host,
    "username" => db.user,
    "password" => db.password,
    "database" => db.path[1..-1],
    "encoding" => 'utf8'
  }
end
