# frozen_string_literal: true

module AppStoreMetadata
  # Shared with the release-notes work in PR #5727. This maps application resources,
  # not the set of locales currently enabled in App Store Connect.
  LOCALE_MAP = {
    'ar' => 'ar-SA', 'ca' => 'ca', 'cs' => 'cs', 'da' => 'da',
    'de' => 'de-DE', 'el' => 'el', 'en' => 'en-US', 'en-GB' => 'en-GB',
    'es' => 'es-ES', 'es-US' => 'es-MX', 'fi' => 'fi', 'fr' => 'fr-FR',
    'he' => 'he', 'hi' => 'hi', 'hr' => 'hr', 'hu' => 'hu',
    'id' => 'id', 'it' => 'it', 'ja' => 'ja', 'ko' => 'ko',
    'nb' => 'no', 'nl' => 'nl-NL', 'pl' => 'pl', 'pt' => 'pt-PT',
    'pt-BR' => 'pt-BR', 'ro-RO' => 'ro', 'ru' => 'ru', 'sk' => 'sk',
    'sv' => 'sv', 'tr' => 'tr', 'uk' => 'uk', 'vi' => 'vi',
    'zh-Hans' => 'zh-Hans', 'zh-Hant' => 'zh-Hant'
  }.freeze

  APP_TO_STORE = LOCALE_MAP.freeze
  STORE_TO_APP = LOCALE_MAP.invert.freeze
end
