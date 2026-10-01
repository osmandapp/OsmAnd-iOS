# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require_relative 'metadata'
require_relative 'auth'

class MetadataTest < Minitest::Test
  def test_api_key_accepts_raw_or_base64_pem_without_exposing_it
    pem = OpenSSL::PKey::EC.generate('prime256v1').to_pem
    assert_equal pem, AppStoreMetadata.api_key_pem(pem)
    assert_equal pem, AppStoreMetadata.api_key_pem(Base64.strict_encode64(pem))
    assert_raises(AppStoreMetadata::Error) { AppStoreMetadata.api_key_pem('wrong key') }
    public_pem = OpenSSL::PKey::RSA.generate(1024).public_key.to_pem
    assert_raises(AppStoreMetadata::Error) { AppStoreMetadata.api_key_pem(public_pem) }
  end

  def sample(locale = 'en-US')
    <<~TEXT
      ## #{locale}

      Title: OsmAnd Maps

      Subtitle: Offline maps

      Promotional Text:
      Text: with colon
      Another line

      What's New:
      #{AppStoreMetadata::MARKER}

      Description:
      See https://example.com/a:b

      Title: a label inside the description
      • Українська, 日本語, العربية
    TEXT
  end

  def test_multiline_unicode_urls_and_crlf
    records = AppStoreMetadata.parse(sample.gsub("\n", "\r\n"))
    assert_equal "Text: with colon\nAnother line", records['en-US']['Promotional Text']
    assert_includes records['en-US']['Description'], 'https://example.com/a:b'
    assert_includes records['en-US']['Description'], '日本語'
    assert_includes records['en-US']['Description'], 'Title: a label'
  end

  def test_marked_public_draft_parses
    draft = "<!-- #{AppStoreMetadata::TEST_MARKER} -->\n\n" + sample
    assert_equal ['en-US'], AppStoreMetadata.parse(draft).keys
    assert_includes draft, AppStoreMetadata::TEST_MARKER
  end

  def test_spanish_todo_is_not_a_placeholder
    records = AppStoreMetadata.parse(sample('es-ES'))
    records['es-ES']['Description'] = 'Todos los mapas, todo en un lugar.'
    resolved = AppStoreMetadata.validate(records, expected_locales: ['es-ES'],
                                                  version: '5.4.0', selected_fields: ['Description'])
    assert_equal 'Todos los mapas, todo en un lugar.', resolved['es-ES']['Description']
    records['es-ES']['Description'] = 'TODO'
    assert_raises(AppStoreMetadata::Error) do
      AppStoreMetadata.validate(records, expected_locales: ['es-ES'],
                                         version: '5.4.0', selected_fields: ['Description'])
    end
  end

  def test_duplicate_locale
    assert_raises(AppStoreMetadata::Error) { AppStoreMetadata.parse(sample + sample) }
  end

  def test_missing_and_unknown_locale
    records = AppStoreMetadata.parse(sample)
    assert_raises(AppStoreMetadata::Error) do
      AppStoreMetadata.validate(records, expected_locales: ['de-DE'], version: '5.4.0')
    end
  end

  def test_bad_marker_and_todo
    records = AppStoreMetadata.parse(sample)
    records['en-US']["What's New"] = 'manual'
    assert_raises(AppStoreMetadata::Error) do
      AppStoreMetadata.validate(records, expected_locales: ['en-US'], version: '5.4.0')
    end
    records['en-US']["What's New"] = AppStoreMetadata::MARKER
    records['en-US']['Title'] = 'TODO'
    assert_raises(AppStoreMetadata::Error) do
      AppStoreMetadata.validate(records, expected_locales: ['en-US'], version: '5.4.0')
    end
  end

  def test_missing_field_and_bad_locale_mapping
    records = AppStoreMetadata.parse(sample)
    records['en-US'].delete('Description')
    assert_match(/missing fields Description/, assert_raises(AppStoreMetadata::Error) {
      AppStoreMetadata.validate(records, expected_locales: ['en-US'], version: '5.4.0')
    }.message)
    records = AppStoreMetadata.parse(sample('xx-YY'))
    assert_match(/no application locale mapping/, assert_raises(AppStoreMetadata::Error) {
      AppStoreMetadata.validate(records, expected_locales: ['xx-YY'], version: '5.4.0')
    }.message)
  end

  def test_missing_and_empty_release_notes
    records = AppStoreMetadata.parse(sample)
    [{}, { 'ios_release_5_4' => '  ' }].each do |strings|
      AppStoreMetadata.stub(:strings_for, strings) do
        assert_match(/missing or empty ios_release_5_4/, assert_raises(AppStoreMetadata::Error) {
          AppStoreMetadata.validate(records, expected_locales: ['en-US'], version: '5.4.0')
        }.message)
      end
    end
  end

  def test_release_notes_and_generated_files
    records = AppStoreMetadata.parse(sample)
    resolved = AppStoreMetadata.validate(records, expected_locales: ['en-US'], version: '5.4.0')
    assert_includes resolved['en-US']["What's New"], 'Terrain shadows'
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'stale.txt'), 'old')
      AppStoreMetadata.generate(resolved, dir)
      refute File.exist?(File.join(dir, 'stale.txt'))
      names = Dir.children(File.join(dir, 'en-US')).sort
      assert_equal %w[description.txt name.txt promotional_text.txt release_notes.txt subtitle.txt], names
      refute_includes names, 'keywords.txt'
      assert_equal resolved, AppStoreMetadata.read_generated(dir, expected_locales: ['en-US'],
                                                                  selected_fields: AppStoreMetadata::FIELDS.keys)
    end
    assert_equal %w[description promotional_text whats_new],
                 AppStoreMetadata.version_attributes(resolved['en-US']).keys.sort
    assert_equal %w[name subtitle], AppStoreMetadata.info_attributes(resolved['en-US']).keys.sort
  end

  def test_length_and_missing_release_key
    records = AppStoreMetadata.parse(sample)
    records['en-US']['Title'] = 'A' * 31
    assert_raises(AppStoreMetadata::Error) do
      AppStoreMetadata.validate(records, expected_locales: ['en-US'], version: '5.4.0')
    end
    records['en-US']['Title'] = 'OsmAnd'
    records['en-US']['Promotional Text'] = 'A' * 171
    assert_match(/maximum 170/, assert_raises(AppStoreMetadata::Error) {
      AppStoreMetadata.validate(records, expected_locales: ['en-US'], version: '5.4.0')
    }.message)
    records['en-US']['Promotional Text'] = 'Valid'
    assert_raises(AppStoreMetadata::Error) do
      AppStoreMetadata.validate(records, expected_locales: ['en-US'], version: '99.99.0')
    end
  end

  def test_bootstrap_round_trip_and_no_keywords
    source = AppStoreMetadata.render_bootstrap('en-US' => {
      'Title' => 'OsmAnd', 'Subtitle' => 'Offline maps',
      'Promotional Text' => "First line\nSecond: line",
      'Description' => "Перший абзац\n\nДругий абзац"
    })
    refute_includes source, 'Keywords'
    parsed = AppStoreMetadata.parse(source)
    assert_equal "Перший абзац\n\nДругий абзац", parsed['en-US']['Description']
    assert_equal AppStoreMetadata::MARKER, parsed['en-US']["What's New"]
  end

  def test_rejects_keywords_field
    assert_raises(AppStoreMetadata::Error) do
      AppStoreMetadata.parse(sample.sub('Subtitle:', "Keywords: secret\n\nSubtitle:"))
    end
  end

  def test_only_selected_field_is_validated_generated_and_uploaded
    records = AppStoreMetadata.parse(sample)
    records['en-US']['Title'] = 'TODO'
    resolved = AppStoreMetadata.validate(records, expected_locales: ['en-US'],
                                                  version: '99.99.0', selected_fields: ['Subtitle'])
    assert_equal({ 'Subtitle' => 'Offline maps' }, resolved['en-US'])
    assert_empty AppStoreMetadata.version_attributes(resolved['en-US'])
    assert_equal({ 'subtitle' => 'Offline maps' }, AppStoreMetadata.info_attributes(resolved['en-US']))
    Dir.mktmpdir do |dir|
      AppStoreMetadata.generate(resolved, dir)
      assert_equal ['subtitle.txt'], Dir.children(File.join(dir, 'en-US'))
      assert_equal resolved, AppStoreMetadata.read_generated(dir, expected_locales: ['en-US'],
                                                                  selected_fields: ['Subtitle'])
    end
  end

  def test_no_fields_selected_fails_before_upload
    records = AppStoreMetadata.parse(sample)
    assert_match(/select at least one/, assert_raises(AppStoreMetadata::Error) {
      AppStoreMetadata.validate(records, expected_locales: ['en-US'], version: '5.4.0', selected_fields: [])
    }.message)
  end

  def test_generated_reader_rejects_unexpected_file
    records = AppStoreMetadata.parse(sample)
    resolved = AppStoreMetadata.validate(records, expected_locales: ['en-US'],
                                                  version: '99.99.0', selected_fields: ['Subtitle'])
    Dir.mktmpdir do |dir|
      AppStoreMetadata.generate(resolved, dir)
      File.write(File.join(dir, 'en-US', 'keywords.txt'), 'unexpected')
      assert_match(/generated file mismatch/, assert_raises(AppStoreMetadata::Error) {
        AppStoreMetadata.read_generated(dir, expected_locales: ['en-US'],
                                            selected_fields: ['Subtitle'])
      }.message)
    end
  end
end
