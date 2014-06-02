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
  
  builder = Nokogiri::XML::Builder.new do |xml|
    xml.send(:'service_definition') {
      xml.send(:'service_code', '001')
      xml.send(:'attributes') {
        xml.send(:'attribute') {
          xml.send(:'variable', 'false')  # true/false - is user input required
          xml.send(:'code', 'A1')
          xml.send(:'datatype', 'string') # string, number, datetime, text, singlevaluelist, multivaluelist
          xml.send(:'required', 'false') # true/false - is value required to submit service request
          xml.send(:'datatype_description', '')
          xml.send(:'order', '2') # Any positive integer not used for other attributes in the same service_code
          xml.send(:'description', '')
          xml.send(:'values') {
            xml.send(:'value') {
              xml.send(:'key', '123') # The unique identifier associated with an option for singlevaluelist or multivaluelist. This is analogous to the value attribute in an html option tag.
              xml.send(:'name', 'test') # The human readable title of an option for singlevaluelist or multivaluelist. This is analogous to the innerhtml text node of an html option tag.
            }
            xml.send(:'value') {
              xml.send(:'key', '124')
              xml.send(:'name', 'another test')
            }
          }
        }
        xml.send(:'attribute') {
          xml.send(:'variable', 'false')  # true/false - is user input required
          xml.send(:'code', 'A2')
          xml.send(:'datatype', 'string') # string, number, datetime, text, singlevaluelist, multivaluelist
          xml.send(:'required', 'false') # true/false - is value required to submit service request
          xml.send(:'datatype_description', '')
          xml.send(:'order', '1') # Any positive integer not used for other attributes in the same service_code
          xml.send(:'description', '')
          xml.send(:'values') {
            xml.send(:'value') {
              xml.send(:'key', '123') # The unique identifier associated with an option for singlevaluelist or multivaluelist. This is analogous to the value attribute in an html option tag.
              xml.send(:'name', 'test') # The human readable title of an option for singlevaluelist or multivaluelist. This is analogous to the innerhtml text node of an html option tag.
            }
          }
        }
      }
    }
  end
  
  builder.to_xml
end