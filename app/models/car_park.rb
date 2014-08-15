class CarPark < ActiveRecord::Base

  def summary_xml(xml)
    xml.send(:'facility') {
      xml.send(:'id', "#{self.id_public}")
      xml.send(:'facility_name', self.name)
      xml.send(:'expiration', '2099-12-31T23:59:59Z')
      xml.send(:'updated', Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"))
      xml.send(:'type', 'Parking')
      xml.send(:'brief_description', self.name)
      xml.send(:'lat', self.lat)
      xml.send(:'long', self.long)
      xml.send(:'features') {
        xml.send(:'occupancy', self.occupancy)
        xml.send(:'capacity', self.capacity)
      }
    }
  end

  def detailed_xml(xml)
    xml.send(:'facility') {
      xml.send(:'id', "#{self.id_public}")
      xml.send(:'facility_name', self.name)
      xml.send(:'expiration', '2099-12-31T23:59:59Z')
      xml.send(:'updated', Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"))
      xml.send(:'type', 'Parking')
      xml.send(:'brief_description', self.name)
      xml.send(:'lat', self.lat)
      xml.send(:'long', self.long)
      xml.send(:'features') {
        xml.send(:'occupancy', self.occupancy)
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