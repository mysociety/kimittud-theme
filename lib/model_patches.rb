# encoding: UTF-8
# coding: UTF-8
# -*- coding: UTF-8 -*-
# Add a callback - to be executed before each request in development,
# and at startup in production - to patch existing app classes.
# Doing so in init/environment.rb wouldn't work in development, since
# classes are reloaded, but initialization is not run each time.
# See http://stackoverflow.com/questions/7072758/plugin-not-reloading-in-development-mode
#
Rails.configuration.after_initialize do
  class InfoRequest::State::CustomCalculator < InfoRequest::State::Calculator
    def transitions(opts = {})
      transitions = super
      transitions[:pending].delete('internal_review')
      transitions[:complete].delete('internal_review')
      transitions[:other].delete('internal_review')
      transitions
    end
  end
end

Rails.configuration.to_prepare do
  InfoRequest.class_eval do
    def state(_opts = {})
      InfoRequest::State::CustomCalculator.new(self)
    end
  end

  # OutgoingMessage.class_eval do
  OutgoingMessage::Template::InitialRequest.class_eval do
    # Add intro paragraph to new request template
    def default_letter
      return nil if self.message_type == 'followup'
      #"If you uncomment this line, this text will appear as default text in every message"
    end

    def template_string(replacements)
      law_msg = <<~TXT.strip
        Az információs önrendelkezési jogról és az információszabadságról szóló 2011. évi CXII. törvény (a továbbiakban: Infotv.) 28. § (1) bekezdése alapján a következő adatigénylést terjesztem elő.

        Kérem, szíveskedjen elektronikus másolatban megküldeni részemre

        (__ IGÉNYELT ADATOK MEGJELÖLÉSE __)

        Az Infotv. 30. § (2) bekezdése szerint kérem, hogy a másolatokat és az egyéb igényelt adatokat elektronikus úton szíveskedjen részemre a feladó e-mail címére megküldeni. Ha az igényelt adatokat bármely okból nem lehet e-mailben megküldeni, akkor kérem, hogy azokat a kimittud.atlatszo.hu weboldalon töltse fel.

        Mivel adatigénylésemben elektronikus másolatban és elektronikus úton kérem az adatok kiadását, ezért az adatigénylés teljesítéséért az Infotv. 29. § (3)-(5) bekezdései alapján költségtérítés megállapítására nincs mód. Ha az adatok kiadása a kért módon lehetetlen volna, és iratmásolatok adathordozókra másolásához és kézbesítéséhez kapcsolódóan a hivatkozott törvényi rendelkezések alkalmazásával mégis költségtérítést állapítanának meg, úgy kérem, hogy előzetesen elektronikus úton tájékoztasson erről. Ebben az esetben azt is kérem, hogy a tájékoztatásban tételesen jelölje meg a költségtérítés számítása során figyelembe vett költségtényezőket.

        Kérem, hogy abban az esetben, ha az igényelt adatoknak csak egy részét tekinti megismerhetőnek, az Infotv. 30. § (1) bekezdése alapján azokat az adatigénylés részbeni megtagadásával együtt küldje meg számomra.

        Felhívom szíves figyelmét, hogy a Nemzeti Adatvédelmi és Információszabadság Hatóság NAIH/2015/4710/2/V. számú állásfoglalásából következően a jelen adatigénylés az Infotv. 29. § (1b) bekezdése alapján nem tagadható meg, mivel tartalmazza az adatigénylő nevét és elérhetőségét. Ezen túlmenő adatok megadását az adatkezelő NAIH állásfoglalás szerint nem kérheti, továbbá nem jogosult a személyazonosság ellenőrzésére sem.

        Segítő együttműködését előre is köszönöm.

        Kelt: #{I18n.localize(Time.now.to_date, :format => :long)}
      TXT
      msg = salutation(replacements)
      msg += letter(replacements)
      msg += "\n\n"
      msg += law_msg
      msg += "\n\n"
      msg += signoff(replacements)
      msg += "\n\n"
    end
  end

  PublicBodyCSV.class_eval do
    def self.default_fields
      [:name,
      :short_name,
      :url_name,
      :request_email,
      :tag_string,
      :calculated_home_page,
      :publication_scheme,
      :disclosure_log,
      :notes,
      :created_at,
      :updated_at,
      :version]
    end
    def self.default_headers
      ['Name',
      'Short name',
      'URL name',
      'Email',
      'Tags',
      'Home page',
      'Publication scheme',
      'Disclosure log',
      'Notes',
      'Created at',
      'Updated at',
      'Version']
    end
  end
end
