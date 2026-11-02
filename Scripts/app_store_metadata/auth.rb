# frozen_string_literal: true

require 'base64'
require 'openssl'

module AppStoreMetadata
  def self.api_key_pem(value)
    source = value.to_s.strip
    raise Error, 'ASC_KEY_P8 is empty' if source.empty?

    pem = if source.start_with?('-----BEGIN ')
            source
          else
            Base64.strict_decode64(source.delete("\r\n"))
          end
    key = OpenSSL::PKey.read(pem)
    raise Error, 'ASC_KEY_P8 must contain an EC private key' unless key.is_a?(OpenSSL::PKey::EC) && key.private?
    pem.strip + "\n"
  rescue ArgumentError, OpenSSL::PKey::PKeyError
    raise Error, 'ASC_KEY_P8 is not a valid .p8 private key (raw PEM or Base64 PEM expected)'
  end
end
