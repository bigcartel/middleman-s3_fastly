require 'middleman-s3_sync'

class Middleman::S3Fastly < Middleman::Extension
  option :api_key, nil, 'Fastly API Key'
  option :service_id, nil, 'Fastly Service ID'
  option :hostname, nil, 'Service Hostname'
  option :scheme, 'https', 'Service Scheme'
  option :purge_paths, nil, 'Paths to purge'

  def initialize(app, options_hash={}, &block)
    super

    # Block below is run with a different binding so we need to stash a local
    # variable to access the options
    my_options = options
    app.after_s3_sync {
      puts ANSI.green{ 'Issuing Fastly Purges'.rjust(12) }

      key_purges = %w( text-html text-xml text-plain )
      key_purges.each { |key|
        $stdout.write "  KEY #{key}: "
        system(%Q!curl -X POST -H "Accept: application/json" -H "Fastly-Key: #{my_options.api_key}" https://api.fastly.com/service/#{my_options.service_id}/purge/#{my_options.hostname}+#{key}!)
      }

      [my_options[:purge_paths]].flatten.compact.each { |url|
        $stdout.write "  URL #{url}: "
        system("curl -X PURGE #{my_options.scheme}://#{my_options.hostname}#{url}")
      }
    }
  end

  def self.configure(app, deploy_env, options={})
    return unless deploy_env

    fastly_config = {
      api_key: fetch_env('FASTLY_KEY'),
      service_id: fetch_env('FASTLY_ID'),
      hostname: fetch_env('HOSTNAME')
    }

    sync_config = {
      aws_access_key_id: fetch_env('AWS_ACCESS_KEY_ID'),
      aws_secret_access_key: fetch_env('AWS_SECRET_ACCESS_KEY')
    }

    app.activate :s3_sync, sync_config do |s3_sync|
      s3_sync.prefer_gzip = false
      s3_sync.after_build = true

      s3_sync.bucket = fastly_config[:hostname].gsub('.', '-')
      sync_config.each_pair do |key, value|
        s3_sync.send "#{key}=", value
      end
    end

    a_year = 60 * 60 * 24 * 365

    default_caching_policy = options.delete(:default_caching_policy) {
      { public: true, max_age: a_year }
    }

    caching_policies = options.delete(:caching_policies) {
      { 'text/html' => { s_maxage: a_year }}
    }

    app.default_caching_policy default_caching_policy

    caching_policies.each do |content_type, policy|
      app.caching_policy content_type, policy
    end

    fastly_config.merge! options
    app.activate(:s3_fastly, fastly_config.symbolize_keys)
  end

  def self.secret_file(env)
    try = %w( ~/.chef-keys/static-sites .chef-keys )
    found = try.collect { |dir|
      keyfile = File.expand_path(File.join(dir, env))
      keyfile if File.exists?(keyfile)
    }.compact

    puts("Unable to find secret key for #{env} in search folders: #{try.join(', ')}") || exit(1) if found.empty?
    found.first
  end

  def self.repo_name
    @repo_name ||= begin
      remote = `git config --get remote.origin.url`.chomp
      remote.sub(/^(?:https:\/\/|git@)github\.com(?::|\/)(.+?)\.git$/, '\1')
    end
  end

  def self.fetch_env(key)
    ENV[key] || puts("Missing required environment variable #{key}") || exit(1)
  end
end

Middleman::Extensions.register(:s3_fastly, Middleman::S3Fastly)
