require "test_helper"
require "turbo/broadcastable/test_helper"

class RefreshWeatherAlertsJobTest < ActiveJob::TestCase
  include Turbo::Broadcastable::TestHelper

  test "importa lo que trae el canal y difunde el tablero" do
    assert_turbo_stream_broadcasts "weather_alerts", count: 1 do
      assert_equal 3, RefreshWeatherAlertsJob.new.perform(feed: stubbed_feed)
    end
  end

  test "no difunde nada si el canal no trae avisos nuevos" do
    RefreshWeatherAlertsJob.new.perform(feed: stubbed_feed)

    # capture, y no assert_no_turbo_stream_broadcasts, porque este último mira el
    # total del stream y la primera pasada ya ha difundido.
    second = capture_turbo_stream_broadcasts "weather_alerts" do
      assert_equal 0, RefreshWeatherAlertsJob.new.perform(feed: stubbed_feed)
    end

    assert_empty second
  end

  private

    def stubbed_feed
      archive = file_fixture("aemet/archive.tar.gz").read
      atom = file_fixture("aemet/feed.atom").read
      feed = Aemet::Feed.new
      feed.define_singleton_method(:get) { |url| url.end_with?(".tar.gz") ? archive : atom }
      feed
    end
end
