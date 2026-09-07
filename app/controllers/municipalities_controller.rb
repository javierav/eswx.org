class MunicipalitiesController < ApplicationController
  LIMIT = 30

  def index
    @query = params[:q].to_s
    @municipalities = Municipality.search(@query).includes(:province, :weather_zone).limit(LIMIT)
  end

  def show
    @municipality = Municipality.includes(weather_zone: { weather_territory: { province: :region } })
      .find_by!(ine_code: params[:id])
    @alerts = @municipality.weather_zone.weather_alerts.active.by_urgency
      .includes(weather_zone: { weather_territory: { province: :region } })
  end
end
