require "test_helper"

class Aemet::FeedTest < ActiveSupport::TestCase
  setup do
    @atom = file_fixture("aemet/feed.atom").read
    @archive = file_fixture("aemet/archive.tar.gz").read
  end

  test "lee el instante de la última elaboración" do
    assert_equal Time.utc(2026, 9, 6, 18, 55, 20), stubbed_feed.updated_at
  end

  test "descarga el tar.gz enlazado en la primera entrada y devuelve sus mensajes" do
    messages = stubbed_feed.messages

    assert_equal 4, messages.size
    assert_equal 1, messages.count(&:minor?)
    assert_includes messages.map(&:zone_code), "743103"
  end

  test "no descarga los XML sueltos: le basta el tar.gz" do
    feed = stubbed_feed
    feed.messages

    assert_equal 2, @requests.size, "solo debería pedir el Atom y el tar.gz"
    assert @requests.last.end_with?(".tar.gz")
  end

  private

    # Se sustituye la descarga y no la red entera: así el test cubre el recorrido
    # del Atom, la elección del tar.gz y el desempaquetado.
    def stubbed_feed
      @requests = []
      atom, archive, requests = @atom, @archive, @requests
      feed = Aemet::Feed.new
      feed.define_singleton_method(:get) do |url|
        requests << url
        url.end_with?(".tar.gz") ? archive : atom
      end
      feed
    end
end
