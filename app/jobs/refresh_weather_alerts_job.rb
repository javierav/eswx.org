# Consulta el canal de AEMET y difunde el tablero si ha llegado algo nuevo.
class RefreshWeatherAlertsJob < ApplicationJob
  queue_as :default

  retry_on Aemet::Feed::Error, Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET, SocketError,
    wait: :polynomially_longer, attempts: 5

  # El canal se recibe como parámetro para poder sustituirlo en las pruebas; la
  # programación de recurring.yml encola el job sin argumentos.
  def perform(feed: Aemet::Feed.new)
    imported = WeatherAlert.refresh_from_aemet(feed: feed)
    broadcast_board if imported.positive?
    imported
  end

  private

    # Se difunde el tablero entero en lugar de aviso por aviso: un refresco puede
    # crear, sustituir y caducar avisos a la vez, y reemplazar el bloque lo resuelve
    # de una pasada. Va en síncrono porque esto ya es un job en segundo plano.
    def broadcast_board
      Turbo::StreamsChannel.broadcast_replace_to(
        "weather_alerts",
        target: "weather_alerts_board",
        partial: "weather_alerts/board",
        locals: { board: WeatherAlertBoard.new }
      )
    end
end
