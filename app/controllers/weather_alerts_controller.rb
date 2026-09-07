class WeatherAlertsController < ApplicationController
  def index
    @board = WeatherAlertBoard.new
  end

  def show
    @alert = WeatherAlert.includes(weather_zone: { weather_territory: { province: :region } }).find(params[:id])
    @history = WeatherAlert.history(@alert.weather_zone, @alert.phenomenon_code, at: @alert.onset)
  end
end
