class WeatherZonesController < ApplicationController
  # Consulta por punto geográfico: lleva a la zona que lo contiene.
  def index
    zone = coordinates && WeatherZone.containing(*coordinates)
    return redirect_to(weather_zone_path(zone)) if zone

    @zones = WeatherZone.inland.includes(weather_territory: :province).ordered
    flash.now[:notice] = t(".not_found") if coordinates
  end

  def show
    @zone = WeatherZone.includes(weather_territory: { province: :region }).find_by!(code: params[:id])
    # Los avisos que siguen en pie, incluidos los que empiezan más adelante; que
    # in_force devuelva solo lo vigente ahora mismo es una consulta del histórico,
    # no lo que espera ver quien mira su zona.
    @alerts = @zone.weather_alerts.active.by_urgency.includes(weather_zone: { weather_territory: { province: :region } })
    @municipalities = @zone.municipalities.ordered
  end

  private

    def coordinates
      return if params[:lat].blank? || params[:lng].blank?

      [ Float(params[:lat]), Float(params[:lng]) ]
    rescue ArgumentError
      nil
    end
end
