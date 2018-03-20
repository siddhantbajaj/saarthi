module Api
  module V1
    class HomeController < ApplicationController
      def test
        lat = params[:latitude].to_f
        long = params[:longitude].to_f
        arrival_date = Date.strptime(params[:arrival_date])
        departure_date = Date.strptime(params[:departure_date])
        duration_of_trip = (departure_date - arrival_date).to_i
        start_time = params[:arrival_time].to_i + 2
        end_time = params[:departure_time].to_i + 2
        start_hour = 10
        end_hour = 22


        user_location = [lat,long]
        locations_with_distance = []

        Location.all.each do |location|
          location_lat = location.latitude
          location_long = location.longitude
          url = "https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=#{lat},#{long}&destinations=#{location_lat},#{location_long}&key=AIzaSyDEfqnpcFmoX3VI7iuz-7gOVCvQKSMjRU8"
          response = HTTParty.get(url).parsed_response
          #distance = response["rows"][0]["elements"][0]["distance"]
          duration = response["rows"][0]["elements"][0]["duration"]
          destination = [location_lat,location_long]
          distance = calculate_distance(user_location, destination)
          new_location = location.attributes
          new_location[:distance] = distance
          new_location[:duration] = duration
          locations_with_distance.push(new_location)
        end

        sorted_locations = get_sorted_locations_array(locations_with_distance)
        day = 1
        time = start_time


        sorted_locations.each do |location|
          time = time + (location[:duration]["value"]/3600).to_i

          if time < start_hour || time > end_hour || (time + location["average_time"]) > end_hour
            time = start_hour
            day = day + 1
          end

          location[:start_time] = time
          time = time + location["average_time"]
          location[:end_time] = time
          location[:day] = day



        end

        data = Hash.new
        data[:locations] = sorted_locations

        return response_data(data, "Success", 200)
      end

      def calculate_distance loc1, loc2
        rad_per_deg = Math::PI/180  # PI / 180
        rkm = 6371                  # Earth radius in kilometers
        rm = rkm * 1000             # Radius in meters

        dlat_rad = (loc2[0]-loc1[0]) * rad_per_deg  # Delta, converted to rad
        dlon_rad = (loc2[1]-loc1[1]) * rad_per_deg

        lat1_rad, lon1_rad = loc1.map {|i| i * rad_per_deg }
        lat2_rad, lon2_rad = loc2.map {|i| i * rad_per_deg }

        a = Math.sin(dlat_rad/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad/2)**2
        c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1-a))

        rm * c # Delta in meters
      end

      def get_sorted_locations_array locations
        locations.sort {|first_location, second_location| first_location[:distance] <=> second_location[:distance]}
      end
    end
  end
end
