# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'open3'
require_relative 'locale_map'

module AppStoreMetadata
  ROOT = File.expand_path('../..', __dir__)
  MARKER = '@localization(help_what_is_new)'
  TEST_MARKER = 'LOCAL TEST ONLY - DO NOT PUBLISH'
  FIELDS = {
    'Title' => 'name', 'Subtitle' => 'subtitle',
    'Promotional Text' => 'promotional_text', 'What\'s New' => 'release_notes',
    'Description' => 'description'
  }.freeze
  LIMITS = { 'Title' => 30, 'Subtitle' => 30, 'Promotional Text' => 170,
             'What\'s New' => 4000, 'Description' => 4000 }.freeze

  class Error < StandardError; end

  def self.parse(source)
    raise Error, 'metadata is not valid UTF-8' unless source.valid_encoding?
    text = source.encode('UTF-8').sub(/\A\uFEFF/, '').gsub(/\r\n?/, "\n")
    records = {}
    locale = nil
    field = nil
    text.each_line.with_index(1) do |line, number|
      bare = line.chomp
      if (match = bare.match(/\A## ([a-z]{2,3}(?:-[A-Za-z0-9]+)*)\s*\z/))
        locale = match[1]
        raise Error, "line #{number}: duplicate locale #{locale}" if records.key?(locale)
        records[locale] = {}
        field = nil
      elsif locale.nil? && bare == "<!-- #{TEST_MARKER} -->"
        next
      elsif locale && field == 'Description' && !bare.match?(/\A(?:Keywords|Screenshots|Screenshot Captions|Pricing):/i)
        records[locale][field] << "\n" << bare
      elsif locale && (match = bare.match(/\A(Title|Subtitle|Promotional Text|What's New|Description):(?:[ \t]*(.*))?\z/))
        field = match[1]
        raise Error, "#{locale}: duplicate field #{field}" if records[locale].key?(field)
        records[locale][field] = match[2].to_s
      elsif locale && bare.match?(/\A(?:Keywords|Screenshots|Screenshot Captions|Pricing):/i)
        raise Error, "#{locale}: unsupported field at line #{number}"
      elsif locale && field
        records[locale][field] << "\n" << bare
      elsif bare.strip.empty?
        next
      else
        raise Error, "line #{number}: text outside a metadata field or invalid heading"
      end
    end
    raise Error, 'no locale sections found' if records.empty?
    records.each_value do |fields|
      fields.each { |key, value| fields[key] = value.sub(/\A\n+/, '').sub(/\n+\z/, '') }
    end
    records
  rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError => e
    raise Error, "metadata is not valid UTF-8: #{e.message}"
  end

  def self.release_key(version)
    match = version.to_s.match(/\A(\d+)\.(\d+)(?:\.\d+)*\z/)
    raise Error, "invalid version #{version.inspect}" unless match
    "ios_release_#{match[1]}_#{match[2]}"
  end

  def self.strings_for(app_locale)
    path = File.join(ROOT, 'Resources', 'Localizations', "#{app_locale}.lproj", 'Localizable.strings')
    raise Error, "#{app_locale}: missing #{path}" unless File.file?(path)
    output, status = Open3.capture2e('plutil', '-convert', 'json', '-o', '-', path)
    raise Error, "#{app_locale}: cannot parse Localizable.strings: #{output}" unless status.success?
    JSON.parse(output)
  rescue JSON::ParserError => e
    raise Error, "#{app_locale}: invalid strings JSON: #{e.message}"
  end

  def self.length(value)
    value.encode('UTF-16LE').bytesize / 2
  end

  def self.validate(records, expected_locales:, version:, selected_fields: FIELDS.keys)
    unknown_selection = selected_fields - FIELDS.keys
    raise Error, "unknown selected fields: #{unknown_selection.join(', ')}" unless unknown_selection.empty?
    raise Error, 'select at least one metadata field' if selected_fields.empty?
    expected = expected_locales.sort.uniq
    actual = records.keys.sort
    missing = expected - actual
    extra = actual - expected
    raise Error, "locale mismatch: missing #{missing.join(', ')}; unsupported #{extra.join(', ')}" unless missing.empty? && extra.empty?
    key = release_key(version) if selected_fields.include?("What's New")
    resolved = {}
    records.each do |locale, fields|
      app_locale = STORE_TO_APP[locale]
      raise Error, "#{locale}: no application locale mapping" unless app_locale
      unknown = fields.keys - FIELDS.keys
      raise Error, "#{locale}: unknown fields #{unknown.join(', ')}" unless unknown.empty?
      absent = FIELDS.keys - fields.keys
      raise Error, "#{locale}: missing fields #{absent.join(', ')}" unless absent.empty?
      raise Error, "#{locale}: What's New must be exactly #{MARKER}" unless fields["What's New"] == MARKER
      values = fields.select { |name, _| selected_fields.include?(name) }
      if selected_fields.include?("What's New")
        strings = strings_for(app_locale)
        notes = strings[key]
        raise Error, "#{locale}: missing or empty #{key} in #{app_locale}.lproj" if notes.to_s.strip.empty?
        values["What's New"] = notes.gsub(/\r\n?/, "\n").gsub(/\n[ \t]*\n+/, "\n").sub(/\n+\z/, '')
      end
      values.each do |name, value|
        raise Error, "#{locale}: #{name} contains TODO placeholder" if value.match?(/\b(?:TODO|TBD)\b|<placeholder>/)
        raise Error, "#{locale}: #{name} is empty" if value.strip.empty? && !['Subtitle', 'Promotional Text'].include?(name)
        count = length(value)
        maximum = LIMITS.fetch(name)
        raise Error, "#{locale}: #{name} length #{count}, maximum #{maximum}" if count > maximum
        raise Error, "#{locale}: Title length #{count}, minimum 2" if name == 'Title' && count < 2
      end
      resolved[locale] = values
    end
    resolved
  end

  def self.generate(resolved, output)
    FileUtils.rm_rf(output)
    resolved.sort.each do |locale, fields|
      dir = File.join(output, locale)
      FileUtils.mkdir_p(dir)
      FIELDS.each do |name, filename|
        next unless fields.key?(name)
        File.write(File.join(dir, "#{filename}.txt"), fields.fetch(name) + "\n", encoding: 'UTF-8')
      end
    end
  end

  def self.read_generated(output, expected_locales:, selected_fields:)
    actual_locales = Dir.children(output).sort
    expected = expected_locales.sort
    raise Error, "generated locale mismatch: expected #{expected.join(', ')}, got #{actual_locales.join(', ')}" unless actual_locales == expected

    expected_files = selected_fields.map { |name| "#{FIELDS.fetch(name)}.txt" }.sort
    expected.to_h do |locale|
      dir = File.join(output, locale)
      actual_files = Dir.children(dir).sort
      raise Error, "#{locale}: generated file mismatch: expected #{expected_files.join(', ')}, got #{actual_files.join(', ')}" unless actual_files == expected_files

      fields = selected_fields.to_h do |name|
        filename = "#{FIELDS.fetch(name)}.txt"
        value = File.read(File.join(dir, filename), encoding: 'UTF-8')
        raise Error, "#{locale}: generated #{filename} has no final newline" unless value.end_with?("\n")
        [name, value.delete_suffix("\n")]
      end
      [locale, fields]
    end
  end

  def self.version_attributes(fields)
    mapping = { 'Description' => 'description', 'Promotional Text' => 'promotional_text',
                "What's New" => 'whats_new' }
    mapping.each_with_object({}) do |(field, attribute), result|
      result[attribute] = fields.fetch(field) if fields.key?(field)
    end
  end

  def self.info_attributes(fields)
    mapping = { 'Title' => 'name', 'Subtitle' => 'subtitle' }
    mapping.each_with_object({}) do |(field, attribute), result|
      result[attribute] = fields.fetch(field) if fields.key?(field)
    end
  end

  def self.render_bootstrap(locales)
    locales.sort.map do |locale, data|
      values = {
        'Title' => data.fetch('Title'), 'Subtitle' => data.fetch('Subtitle', ''),
        'Promotional Text' => data.fetch('Promotional Text', ''),
        "What's New" => MARKER, 'Description' => data.fetch('Description')
      }
      "## #{locale}\n\n" + values.map { |key, value| "#{key}:\n#{value}\n" }.join("\n")
    end.join("\n")
  end
end
