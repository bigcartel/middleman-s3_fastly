require 'middleman-core'

Middleman::Extensions.register :s3_fastly do
  require 'middleman-s3_fastly/extension'
  Middleman::S3Fastly
end
