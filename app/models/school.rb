class School < ActiveRecord::Base
  has_many :school_types

  def summary_xml(xml)
    xml.send(:'facility') {
      xml.send(:'id', self.id_public)
      xml.send(:'facility_name', self.name)
      xml.send(:'expiration', '2099-12-31T23:59:59Z')
      xml.send(:'type', 'School')
      xml.send(:'brief_description', self.name)
      xml.send(:'lat', self.lat)
      xml.send(:'long', self.long)
    }
  end

  def detailed_xml(xml)
    xml.send(:'facility') {
      xml.send(:'id', self.id_public)
      xml.send(:'facility_name', self.name)
      xml.send(:'expiration', '2099-12-31T23:59:59Z')
      xml.send(:'type', 'School')
      xml.send(:'brief_description', self.name)
      xml.send(:'lat', self.lat)
      xml.send(:'long', self.long)
      xml.send(:'features') {
        school_types.each do |type|
          xml.send(:'school_type', type.name)
        end
        xml.send(:'head_teacher', self.head_teacher)
      }
      xml.send(:'address', self.address)
      xml.send(:'postcode', self.post_code)
      xml.send(:'phone', self.telephone)
      xml.send(:'email', self.email)
      xml.send(:'web', self.web)
      xml.send(:'eligibility_information', "")
    }
  end
end