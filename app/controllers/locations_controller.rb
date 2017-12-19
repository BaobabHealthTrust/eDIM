class LocationsController < ApplicationController
  def suggestions
    workstation_id = LocationTag.select(:location_tag_id).find_by_name(["workstation location",])
    locations = workstation_id.location_tag_map.collect{|x| x.location_id}
    names = Location.select(:name, :location_id).where("name LIKE '%#{params[:search_string]}%'
                                                        AND location_id in (?)", locations).map do |v|
      "<li value=\"#{v.location_id}\">#{v.name}</li>"
    end

    facilities= Location.select(:name,:location_id).where("name LIKE '%#{params[:search_string]}%' AND description = ?",
                                                          'Health Centre , Public Health Facility').map do |v|
      "<li value=\"#{v.location_id}\">#{v.name}</li>"
    end

    render :text => names.join('') + facilities.join('')
  end
end
