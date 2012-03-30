#!/usr/bin/env rake
require "bundler/gem_tasks"

begin
  Bundler.setup
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts 'run `bundle install` to install missing gems'
  exit e.status_code
end

require 'rake'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = '-Ispec'
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.rspec_opts = '-Ispec'
  spec.rcov       = true
end

task :default => :spec
