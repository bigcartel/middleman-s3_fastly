require 'middleman-core'

class Middleman::S3Fastly < ::Middleman::Extension
  option :aws_access_key_id, nil, 'AWS access key ID', required: true
  option :aws_secret_access_key, nil, 'AWS secret access key', required: true
  option :s3_caching_policies, {}
  option :s3_bucket, nil, 'S3 bucket', required: true
  option :s3_region, nil
  option :s3_delete, true
  option :s3_prefer_gzip, false
  option :s3_path_style, true
  option :s3_reduced_redundancy_storage, false
  option :s3_acl, 'public-read'
  option :s3_encryption, false
  option :s3_prefix, nil
  option :s3_version_bucket, false
  option :s3_index_document, nil
  option :s3_error_document, nil
  option :fastly_api_key, nil, 'Fastly API key', required: true
  option :fastly_service_id, nil, 'Fasly service ID', required: true
  option :fastly_purge_keys, []
  option :fastly_purge_urls, []
  option :fastly_purge_all, false

  def initialize(app, options_hash={}, &block)
    super

    require 'middleman-s3_sync'
    require 'fastly'

    activate_s3_sync
  end

  def after_build
    add_caching_policies_to_s3
    sync_s3
    purge_fastly
  end

  private

  def activate_s3_sync
    app.activate :s3_sync do |s3_sync|
      s3_sync.aws_access_key_id = options.aws_access_key_id
      s3_sync.aws_secret_access_key = options.aws_secret_access_key
      s3_sync.bucket = options.s3_bucket
      s3_sync.region = options.s3_region
      s3_sync.delete = options.s3_delete
      s3_sync.prefer_gzip = options.s3_prefer_gzip
      s3_sync.path_style = options.s3_path_style
      s3_sync.reduced_redundancy_storage = options.s3_reduced_redundancy_storage
      s3_sync.acl = options.s3_acl
      s3_sync.encryption = options.s3_encryption
      s3_sync.prefix = options.s3_prefix
      s3_sync.version_bucket = options.s3_version_bucket
      s3_sync.index_document = options.s3_index_document
      s3_sync.error_document = options.s3_error_document
    end
  end

  def add_caching_policies_to_s3
    say 's3_sync', "Adding caching policies to #{options.s3_bucket}."

    options.s3_caching_policies.each do |content_type, policy|
      say 's3_sync', "#{ANSI.green{'Caching'}} #{content_type} with #{ANSI.white{policy.to_s}}"
      ::Middleman::S3Sync.add_caching_policy content_type, policy
    end
  end

  def sync_s3
    ::Middleman::S3Sync.sync
  end

  def fastly
    @fastly ||= Fastly.new(api_key: options.fastly_api_key)
  end

  def fastly_service
    @fastly_service ||= Fastly::Service.new({ id: options.fastly_service_id }, fastly)
  end

  def purge_fastly
    if options.fastly_purge_all
      say 'fastly', 'Purging all caches.'
      fastly_service.purge_all
    else
      say 'fastly', 'Purging specified keys and URLs.'

      options.fastly_purge_keys.each do |key|
        say 'fastly', "#{ANSI.red{'Purging'}} key #{ANSI.white{key}}"
        fastly_service.purge_by_key(key)
      end

      options.fastly_purge_urls.each do |url|
        say 'fastly', "#{ANSI.red{'Purging'}} URL #{ANSI.white{key}}"
        fastly.purge(url)
      end
    end
  end

  def say(pre, message)
    puts "#{ANSI.green{pre.to_s.rjust(12)}}  #{message}"
  end
end
