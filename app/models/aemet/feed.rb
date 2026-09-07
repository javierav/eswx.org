require "net/http"
require "rubygems/package"
require "stringio"
require "zlib"

module Aemet
  # Canal Atom de avisos de AEMET para toda España.
  #
  # AEMET no ofrece push ni webhooks, así que hay que consultar el canal. Su primera
  # entrada enlaza un tar.gz con todos los mensajes CAP vigentes, de modo que basta
  # con ese fichero: no hace falta descargar los XML uno a uno. Los avisos anteriores
  # que siguen en vigor se repiten en cada tar.gz, y los caducados desaparecen.
  #
  # No sabe nada de la base de datos.
  class Feed
    URL = "https://www.aemet.es/documentos_d/eltiempo/prediccion/avisos/rss/CAP_AFAE_ATOM.xml".freeze
    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 30

    Error = Class.new(StandardError)

    def initialize(url: URL)
      @url = url
    end

    # Instante de la última elaboración. Todas las entradas comparten este valor,
    # así que sirve para saber si hay algo nuevo antes de bajarse el tar.gz.
    def updated_at
      value = document.at_xpath("/feed/updated")&.text
      value.present? ? Time.zone.parse(value) : nil
    end

    def messages
      archive_url ? unpack(get(archive_url)).map { |xml| CapMessage.new(xml) } : []
    end

    private

      def document
        @document ||= Nokogiri::XML(get(@url)).tap(&:remove_namespaces!)
      end

      def archive_url
        document.xpath("/feed/entry/link/@href").map(&:value).find { |href| href.end_with?(".tar.gz") }
      end

      def unpack(body)
        Gem::Package::TarReader.new(Zlib::GzipReader.new(StringIO.new(body))).filter_map do |entry|
          entry.read if entry.file? && entry.full_name.end_with?(".xml")
        end
      end

      def get(url)
        uri = URI.parse(url)
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
          open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
          http.get(uri.request_uri)
        end
        raise Error, "#{url}: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

        response.body
      end
  end
end
