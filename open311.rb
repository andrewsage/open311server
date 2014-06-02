require 'sinatra'
require 'nokogiri'

def valid_jurisdiction?(jurisdiction_id)
  valid = true
  
  unless jurisdiction_id.nil?
    valid_jurisdictions = []
    if valid_jurisdictions.include?(jurisdiction_id) == false
      valid = false
    end
  end
  
  valid
end

get '/hi' do
  "Hello World!"
end

# http://localhost:4567/dev/v2/services.xml
get '/dev/v2/services.xml' do
  # jurisdiction_id is optional if there is only a single endpoint server
  jurisdiction_id = params[:jurisdiction_id]
  content_type 'text/xml'
  
  if valid_jurisdiction?(jurisdiction_id) == false
    halt 404, 'jurisdiction_id provided was not found'
  end
  
  #"TODO: Return list of services for #{jurisdiction_id}"
  
  builder = Nokogiri::XML::Builder.new do |xml|
    xml.send(:'services') {
      xml.send(:'service') {
        xml.send(:'service_code', '001')
        xml.send(:'service_name', 'Curb or curb ramp defect')
        xml.send(:'type', 'blackbox')
        xml.send(:'keywords', 'curb, pavement, uneven')
        xml.send(:'group', 'street')
        xml.send(:'description', 'Pavement curb or ramp has problems such as cracking, missing pieces, holes, and/or chipped curb')
        xml.send(:'metadata', 'true')
      }
      
      xml.send(:'service') {
        xml.send(:'service_code', '002')
        xml.send(:'service_name', 'Rubbish')
        xml.send(:'type', 'realtime')
        xml.send(:'keywords', 'rubbish, bins, mess')
        xml.send(:'group', 'sanitation')
        xml.send(:'description', 'Wheelie bins overflowing rubbish on to the street')
        xml.send(:'metadata', 'true')
      }
    }
  end
  
  builder.to_xml
end


# http://localhost:4567/dev/v2/services/033.xml
get '/dev/v2/services/*' do
  path = params[:splat].first
  service_code = path.split('.').first
  # jurisdiction_id is optional if there is only a single endpoint server
  jurisdiction_id = params[:jurisdiction_id]
  content_type 'text/xml'
  #"TODO: Return list of services for #{jurisdiction_id}"
  
  if service_code.nil?
    halt 400, 'service_code was not provided'
  end
  
  valid_services = ['001', '002']
  if valid_services.include?(service_code) == false
    halt 404, 'service_code provided was not found'
  end
  
  if valid_jurisdiction?(jurisdiction_id) == false
    halt 404, 'jurisdiction_id provided was not found'
  end
  
=begin
  builder = Nokogiri::XML::Builder.new do |xml|
    xml.send(:'services') {
      xml.send(:'service') {
        xml.send(:'service_code', '001')
        xml.send(:'service_name', 'Curb or curb ramp defect')
        xml.send(:'type', 'realtime')
        xml.send(:'keywords', 'curb, pavement, uneven')
        xml.send(:'group', 'street')
        xml.send(:'description', 'Pavement curb or ramp has problems such as cracking, missing pieces, holes, and/or chipped curb')
        xml.send(:'metadata', 'true')
      }
      
      xml.send(:'service') {
        xml.send(:'service_code', '002')
        xml.send(:'service_name', 'Rubbish')
        xml.send(:'type', 'realtime')
        xml.send(:'keywords', 'rubbish, bins, mess')
        xml.send(:'group', 'sanitation')
        xml.send(:'description', 'Wheelie bins overflowing rubbish on to the street')
        xml.send(:'metadata', 'true')
      }
    }
  end
  
  builder.to_xml
=end
end