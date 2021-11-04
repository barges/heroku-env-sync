#!/usr/bin/env ruby
# ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)
# load Gem.bin_path('bundler', 'bundle')

require 'optparse'

SKIPPED_KEYS = %w/
  HEROKU_
/


def setup_params
  options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: heroku_vars_sync.rb [options]"

    opts.on("-s", "--source SOURCE_APP", "Source heroku application name") do |v|
      options[:source] = v
    end

    opts.on("-t", "--target TARGET_APP", "Target heroku application name") do |v|
      options[:target] = v
    end

    opts.on("-o", "--override KEY=VALUE", "Override key, pass multiple -o KEY=VALUE to override multiple keys") do |v|
      options[:override] ||= []
      options[:override] << v
    end

    opts.on("-h", "--help", "Prints this help") do
      puts opts
      puts "These keys will be skipped automatically:"
      puts SKIPPED_KEYS.map { |k| "  - #{ k }*" }
      exit
    end
  end.parse!
  options
end

def validate_params(params)
  if params[:source].nil?
    puts "You must specify source application name, use --help"
    exit
  end
  if params[:target].nil?
    puts "You must specify target application name, use --help"
    exit
  end
end

def save_backup_config(app_name)
  fname = "./#{ app_name }-backup-#{ Time.now.utc.to_i }.env"
  puts "Saving the #{ app_name } current environment backup to #{ fname }..."
  current_target = `heroku config -s -a #{ app_name }`
  if current_target.empty?
    puts "Cannot access #{ app_name }"
    exit(1)
  end
  File.open(fname, 'w') { |f| f.write(current_target) }
  puts "Done"
  current_target
end

def check_overrides(line, overrides)
  key, value = line.split("=", 2)
  overrides.each do |override|
    if override =~ /^#{ key }/
      puts "Replacing #{key}\n     FROM:#{ line }\n       TO:#{ override }"
      return override
    end
  end
  line
end

def cleanup_env(source_env, overrides)
  clean_env = []
  source_env.split("\n").map do |line|
    pass = true
    SKIPPED_KEYS.each do |skipped_key|
      if line =~ /^#{ skipped_key }/
        pass = false
      end
    end
    if pass
      clean_env << check_overrides(line, overrides)
    else
      puts "Skipping #{ line }"
    end
  end
  clean_env
end

def add_missed_vars(parsed_env, overrides)
  matched = []
  parsed_env.each do |line|
    key, value = line.split("=", 2)
    overrides.each do |override|
      okey, ovalue = override.split("=", 2)
      matched << override if okey == key
    end
  end
  missed = overrides - matched
  missed.each do |missed_var|
    puts "Adding #{ missed_var }"
  end
  missed
end


def confirmation(text)
  puts "Type #{ text } to proceed:"
  itext = gets.chomp
  if itext != text
    puts "Exiting..."
    exit(1)
  end
end

def final_warning(parsed_env, app_name)
  puts "We're going to set #{ parsed_env.size } variables, total size=#{ parsed_env.join("\n").length } bytes"
  confirmation(app_name)
  # fname = "./#{ app_name }-backup-#{ Time.now.utc.to_i }.env"
  # File.open(fname, "w") { |f| f.write parsed_env.join("\n") }
end

def set_target_env(parsed_env, app_name)
  `heroku config:add #{ parsed_env.join(' ') } -a #{ app_name }`
end

def proceed(config)
  save_backup_config(config[:target])
  source_env = save_backup_config(config[:source])
  parsed_env = cleanup_env(source_env, config[:override] || [])
  parsed_env += add_missed_vars(parsed_env, config[:override] || [])
  final_warning(parsed_env, config[:target])
  set_target_env(parsed_env, config[:target])
end

def go
  config = setup_params
  validate_params(config)
  puts "FROM: #{ config[:source] }"
  puts "  TO: #{ config[:target] }"
  puts " SET: #{ (config[:override] ||[]).join("\n      ") }"
  puts "That will overwrite the current heroku environment params at #{ config[:target] }"
  confirmation(config[:target])
  proceed(config)
end

go
