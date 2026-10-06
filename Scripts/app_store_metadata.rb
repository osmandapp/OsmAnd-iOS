#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'app_store_metadata/metadata'

command = ARGV.shift
version = ARGV.shift
unless %w[validate generate].include?(command) && version
  abort 'Usage: Scripts/app_store_metadata.rb validate|generate VERSION [locale,...]'
end

begin
  path = File.join(AppStoreMetadata::ROOT, 'app-store', 'metadata.md')
  records = AppStoreMetadata.parse(File.read(path, encoding: 'UTF-8'))
  expected = ARGV.empty? ? records.keys : ARGV.shift.split(',')
  resolved = AppStoreMetadata.validate(records, expected_locales: expected, version: version)
  if command == 'generate'
    output = File.join(AppStoreMetadata::ROOT, '.generated', 'app-store-metadata')
    AppStoreMetadata.generate(resolved, output)
    puts "Generated #{resolved.length} locales in #{output}"
  else
    puts "Validated #{resolved.length} locales for #{version}"
  end
rescue AppStoreMetadata::Error, Errno::ENOENT => e
  abort "ERROR: #{e.message}\nNothing was uploaded."
end
