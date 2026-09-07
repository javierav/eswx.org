module WeatherAlertsHelper
  # Las horas se muestran en la hora local de la zona avisada: Canarias va una hora
  # por detrás y un aviso "hasta las 20:59" significa cosas distintas en cada sitio.
  def alert_time(alert, time)
    l(time.in_time_zone(alert.local_time_zone), format: :alert)
  end

  def alert_period(alert)
    t("weather_alerts.period", from: alert_time(alert, alert.onset), to: alert_time(alert, alert.expires))
  end
end
