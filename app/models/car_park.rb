class CarPark < ActiveRecord::Base

  def summary_json
    json = {
      :id => self.id_public,
      :facility_name => self.name,
      :expiration => '2099-12-31T23:59:59Z',
      :updated => Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
      :type => 'Parking',
      :lat => self.lat,
      :long => self.long,
      :features => {
        :occupancy => self.occupancy,
        :occupancy_percentage => self.occupancy_percentage,
        :capacity => self.capacity
      }
    }
    json
  end

  def detailed_json
    json = {
      :id => self.id_public,
      :facility_name => self.name,
      :expiration => '2099-12-31T23:59:59Z',
      :updated => Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
      :type => 'Parking',
      :lat => self.lat,
      :long => self.long,
      :features => {
        :occupancy => self.occupancy,
        :occupancy_percentage => self.occupancy_percentage,
        :capacity => self.capacity
      },
      :address => "",
      :postcode => "",
      :phone => "",
      :email => "",
      :web => "",
      :displayed_hours => "",
      :eligibility_information => ""
    }
    json
  end

  def summary_xml(xml)
    xml.send(:'facility') {
      xml.send(:'id', self.id_public)
      xml.send(:'facility_name', self.name)
      xml.send(:'expiration', '2099-12-31T23:59:59Z')
      xml.send(:'updated', Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"))
      xml.send(:'type', 'Parking')
      xml.send(:'brief_description', self.name)
      xml.send(:'lat', self.lat)
      xml.send(:'long', self.long)
      xml.send(:'features') {
        xml.send(:'occupancy', self.occupancy)
        xml.send(:'occupancy', self.occupancy_percentage)
        xml.send(:'capacity', self.capacity)
      }
    }
  end

  def detailed_xml(xml)
    xml.send(:'facility') {
      xml.send(:'id', self.id_public)
      xml.send(:'facility_name', self.name)
      xml.send(:'expiration', '2099-12-31T23:59:59Z')
      xml.send(:'updated', Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"))
      xml.send(:'type', 'Parking')
      xml.send(:'brief_description', self.name)
      xml.send(:'lat', self.lat)
      xml.send(:'long', self.long)
      xml.send(:'features') {
        xml.send(:'occupancy', self.occupancy)
        xml.send(:'occupancy', self.occupancy_percentage)
        xml.send(:'capacity', self.capacity)
      }
      xml.send(:'address', "")
      xml.send(:'postcode', "")
      xml.send(:'phone', "")
      xml.send(:'email', "")
      xml.send(:'web', "")
      xml.send(:'displayed_hours', "")
      xml.send(:'eligibility_information', "")
    }
  end
end