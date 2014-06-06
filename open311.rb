require 'sinatra/base'
require 'nokogiri'

class Open311App < Sinatra::Base

  
  # The following are temporary data loading routines for development
  # At some future point a database will be used to contain this data
  def load_community_contacts
    # Columns separated by , rows separated by |
    # The file does contain newlines in fields without quotes
    @rows = []
    @headers = []
    File.open("./data/CommunityContacts.txt", "r") do |infile|
  
      while (line = infile.gets('|'))
        line = line.force_encoding('BINARY')
        line = line.chomp("|")
        # work out the headers
        if @headers.count == 0
          @headers = line.encode("UTF-8", invalid: :replace, undef: :replace).split(",")
        else
          columns = line.encode("UTF-8", invalid: :replace, undef: :replace).split(",")
          row = Hash.new
          columns.each_with_index { |item, index|
            row[@headers[index]] = item
          }
          @rows << row
        end 
      end
    end
    
    @rows.sort! { |a, b| a['ItemTitle'] <=> b['ItemTitle'] }
  end

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
          xml.send(:'service_name', 'Community Centre Contacts')
          xml.send(:'type', 'blackbox')
          xml.send(:'keywords', 'communit centre, contacts')
          xml.send(:'group', 'resources')
          xml.send(:'description', 'Information about community centres')
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
  
    valid_services = ['001']
    if valid_services.include?(service_code) == false
      halt 404, 'service_code provided was not found'
    end
  
    if valid_jurisdiction?(jurisdiction_id) == false
      halt 404, 'jurisdiction_id provided was not found'
    end
  
    load_community_contacts
    
  
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.send(:'service_definition') {
        xml.send(:'service_code', '001')
        xml.send(:'attributes') {
          xml.send(:'attribute') {
            xml.send(:'variable', 'true')  # true/false - is user input required
            xml.send(:'code', 'A1')
            xml.send(:'datatype', 'singlevaluelist') # string, number, datetime, text, singlevaluelist, multivaluelist
            xml.send(:'required', 'false') # true/false - is value required to submit service request
            xml.send(:'datatype_description', '')
            xml.send(:'order', '1') # Any positive integer not used for other attributes in the same service_code
            xml.send(:'description', 'What community group are you looking for?')
            xml.send(:'values') {
              
              @rows.each do |row|
              
                xml.send(:'value') {
                  xml.send(:'key', row['Id']) # The unique identifier associated with an option for singlevaluelist or multivaluelist. This is analogous to the value attribute in an html option tag.
                  xml.send(:'name', row['ItemTitle']) # The human readable title of an option for singlevaluelist or multivaluelist. This is analogous to the innerhtml text node of an html option tag.
                }
              end
            }
          }
          xml.send(:'attribute') {
            xml.send(:'variable', 'true')  # true/false - is user input required
            xml.send(:'code', 'A2')
            xml.send(:'datatype', 'string') # string, number, datetime, text, singlevaluelist, multivaluelist
            xml.send(:'required', 'false') # true/false - is value required to submit service request
            xml.send(:'datatype_description', '')
            xml.send(:'order', '2') # Any positive integer not used for other attributes in the same service_code
            xml.send(:'description', 'Keywords you are looking for')
          }
        }
      }
    end
  
    builder.to_xml
  end
end