require 'bundler'

begin
  Bundler.setup
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rack/large-uploads'
Dir[File.expand_path("../support/**/*.rb", __FILE__)].each do
  |f| require f
end

RSpec.configure do |config|
  config.mock_with :rr
end
