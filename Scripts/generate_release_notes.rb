#!/usr/bin/env ruby
# frozen_string_literal: true

# Generates App Store Connect release notes from the in-app "What's new" strings.
#
# Release notes are already written and translated in Resources/Localizations/<lang>.lproj/
# Localizable.strings under the key "ios_release_<major>_<minor>" (the same text the
# What's new bottom sheet shows). This script maps every .lproj to its App Store Connect
# locale and writes fastlane/metadata/<locale>/release_notes.txt, so nothing has to be
# pasted into App Store Connect by hand.
#
# Usage: Scripts/generate_release_notes.rb <marketing version> [output dir]
#   Scripts/generate_release_notes.rb 5.4.0
#   Scripts/generate_release_notes.rb 5.4.0 fastlane/metadata

require 'json'
require 'fileutils'

# .lproj directory -> App Store Connect locale.
# Only locales App Store Connect actually accepts are listed; the rest are skipped.
LOCALE_MAP = {
  'ar' => 'ar-SA',
  'ca' => 'ca',
  'cs' => 'cs',
  'da' => 'da',
  'de' => 'de-DE',
  'el' => 'el',
  'en' => 'en-US',
  'en-GB' => 'en-GB',
  'es' => 'es-ES',
  'es-US' => 'es-MX',
  'fi' => 'fi',
  'fr' => 'fr-FR',
  'he' => 'he',
  'hi' => 'hi',
  'hr' => 'hr',
  'hu' => 'hu',
  'id' => 'id',
  'it' => 'it',
  'ja' => 'ja',
  'ko' => 'ko',
  'nb' => 'no',
  'nl' => 'nl-NL',
  'pl' => 'pl',
  'pt' => 'pt-PT',
  'pt-BR' => 'pt-BR',
  'ro-RO' => 'ro',
  'ru' => 'ru',
  'sk' => 'sk',
  'sv' => 'sv',
  'tr' => 'tr',
  'uk' => 'uk',
  'vi' => 'vi',
  'zh-Hans' => 'zh-Hans',
  'zh-Hant' => 'zh-Hant'
}.freeze

# App Store Connect rejects release notes longer than this.
MAX_LENGTH = 4000

# en-US is mandatory: it is the fallback App Store shows for every locale we do not upload.
FALLBACK_LOCALE = 'en-US'

def die(message)
  warn "error: #{message}"
  exit 1
end

# "5.4.0" / "5.4" / "5.4.0.5433" -> "ios_release_5_4"
def release_key(version)
  parts = version.strip.split('.')
  die("cannot parse version '#{version}'") if parts.size < 2
  "ios_release_#{parts[0]}_#{parts[1]}"
end

# Localizable.strings is an old-style plist, so plutil parses it including all escapes.
def read_strings(path)
  json = `plutil -convert json -o - "#{path}" 2>/dev/null`
  return nil unless $?.success?

  JSON.parse(json)
rescue JSON::ParserError
  nil
end

def clean(text)
  # Normalise the bullet lines and drop the trailing newline the in-app string carries.
  text.gsub("\r\n", "\n").split("\n").map(&:strip).reject(&:empty?).join("\n")
end

version = ARGV[0]
die('usage: generate_release_notes.rb <marketing version> [output dir]') if version.nil? || version.empty?

root = File.expand_path('..', __dir__)
localizations = File.join(root, 'Resources', 'Localizations')
out_dir = ARGV[1] ? File.expand_path(ARGV[1]) : File.join(root, 'fastlane', 'metadata')
key = release_key(version)

written = []
skipped = []

LOCALE_MAP.each do |lproj, locale|
  strings_path = File.join(localizations, "#{lproj}.lproj", 'Localizable.strings')
  next unless File.exist?(strings_path)

  strings = read_strings(strings_path)
  if strings.nil?
    warn "warning: could not parse #{lproj}.lproj/Localizable.strings, skipping"
    next
  end

  notes = strings[key]
  if notes.nil? || notes.strip.empty?
    skipped << locale
    next
  end

  notes = clean(notes)
  if notes.length > MAX_LENGTH
    warn "warning: #{locale} release notes are #{notes.length} chars, truncating to #{MAX_LENGTH}"
    notes = notes[0, MAX_LENGTH]
  end

  locale_dir = File.join(out_dir, locale)
  FileUtils.mkdir_p(locale_dir)
  File.write(File.join(locale_dir, 'release_notes.txt'), notes + "\n")
  written << locale
end

if written.include?(FALLBACK_LOCALE)
  puts "Generated release notes for #{key} in #{written.size} locale(s): #{written.sort.join(', ')}"
  puts "Not translated yet (App Store falls back to #{FALLBACK_LOCALE}): #{skipped.sort.join(', ')}" unless skipped.empty?
else
  die("#{key} is missing from en.lproj/Localizable.strings - add the English release notes first")
end
