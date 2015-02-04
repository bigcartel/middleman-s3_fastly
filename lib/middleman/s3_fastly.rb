require 'middleman-s3_sync'

class Middleman::S3Fastly < Middleman::Extension
  option :api_key, nil, 'Fastly API Key'
  option :service_id, nil, 'Fastly Service ID'
  option :hostname, nil, 'Service Hostname'

  def initialize(app, options_hash={}, &block)
    super

    # Block below is run with a different binding so we need to stash a local
    # variable to access the options
    my_options = options
    app.after_s3_sync { 
      puts 'Issuing Fastly Purge'.rjust(12).light_green
      system(%Q!curl -X POST -H "Accept: application/json" -H "Fastly-Key: #{my_options.api_key}" https://api.fastly.com/service/#{my_options.service_id}/purge/#{my_options.hostname}+text-html!)
    }
  end

  def self.configure(app, deploy_env)
    return unless deploy_env

    config = Bundler.with_clean_env {
      YAML.load(`knife data bag show static-sites #{deploy_env} --secret-file .chef-keys/#{deploy_env}`)
    }
    puts("No deploy configuration for #{deploy_env}") || exit(1) unless config

    sync_config = config.delete('s3-sync')
    fastly_config = config.delete('fastly')
    fastly_config[:hostname] = config['repos'][repo_name]
    puts("Repo #{repo_name} is not configured to deploy to #{deploy_env}") || exit(1) unless fastly_config[:hostname]

    app.activate :s3_sync, sync_config do |s3_sync|
      s3_sync.prefer_gzip = false
      s3_sync.after_build = true
      s3_sync.bucket = fastly_config[:hostname].gsub('.', '-')
      sync_config.each_pair do |key, value|
        s3_sync.send "#{key}=", value
      end
    end

    a_year = 60 * 60 * 24 * 365
    app.default_caching_policy public: true, max_age: a_year
    app.caching_policy 'text/html', s_maxage: a_year

    app.activate(:s3_fastly, fastly_config.symbolize_keys) if fastly_config
  end

  def self.repo_name
    @repo_name ||= begin
      remote = `git config --get remote.origin.url`.chomp
      remote.sub(/^git@github\.com:(.+?)\.git$/, '\1')
    end
  end
end

Middleman::Extensions.register(:s3_fastly, Middleman::S3Fastly)