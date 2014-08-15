class CommunityCentre < ActiveRecord::Base
  def summary_xml(xml)
    xml.send(:'facility') {
      xml.send(:'id', self.id_public)
      xml.send(:'facility_name', self.name)
      xml.send(:'expiration', '2099-12-31T23:59:59Z')
      xml.send(:'type', 'Community Centre')
      xml.send(:'brief_description', self.brief_description)
      xml.send(:'lat', self.lat)
      xml.send(:'long', self.long)
    }
  end

  def detailed_xml(xml)
    xml.send(:'facility') {
      xml.send(:'id', self.id_public)
      xml.send(:'facility_name', self.name)
      xml.send(:'expiration', '2099-12-31T23:59:59Z')
      xml.send(:'type', 'Community Centre')
      xml.send(:'brief_description', self.brief_description)
      xml.send(:'description', self.description)
      xml.send(:'lat', self.lat)
      xml.send(:'long', self.long)
      xml.send(:'features') {
      }
      xml.send(:'address', self.address)
      xml.send(:'postcode', self.post_code)
      xml.send(:'phone', self.telephone)
      xml.send(:'email', self.email)
      xml.send(:'web', self.web)
      xml.send(:'displayed_hours', self.displayed_hours)
      xml.send(:'eligibility_information', self.eligibility_information)
    }
  end
end