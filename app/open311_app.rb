class Open311App < Sinatra::Base

  set :services_api_root, '/dev/v2'
  set :facilities_api_root, '/dev/v1'
  set :facility_prefix_community_group, 'CG'

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
          @headers = line.encode("UTF-8", invalid: :replace, undef: :replace).split("$")
        else
          columns = line.encode("UTF-8", invalid: :replace, undef: :replace).split("$")
          row = Hash.new
          columns.each_with_index { |item, index|
            row[@headers[index]] = item
          }
          # set the ID to the correct format for Community Groups
          row['Id'] = "#{settings.facility_prefix_community_group}#{row['Id']}"
          # set our internal type to Community Group
          row['internaltype'] = 'Community Groups'
          @rows << row
        end
      end
    end

    @rows.sort! { |a, b| a['ItemTitle'] <=> b['ItemTitle'] }
  end

  def community_facility_summary(xml, row)
    xml.send(:'facility') {
      xml.send(:'id', "#{row['Id']}")
      xml.send(:'facility_name', row['ItemTitle'])
      xml.send(:'expiration', '2099-12-31T23:59:59Z')
      xml.send(:'type', row['internaltype'])
      xml.send(:'brief_description', row['Other'])
    }
  end

  def community_facility_detailed(xml, row)
    xml.send(:'facility') {
      xml.send(:'id', "#{row['Id']}")
      xml.send(:'facility_name', row['ItemTitle'])
      xml.send(:'expiration', '2099-12-31T23:59:59Z')
      xml.send(:'type', row['internaltype'])
      xml.send(:'brief_description', row['Other'])
      xml.send(:'description', row['Other'] + row['OtherTwo'])
      xml.send(:'features') {

      }
      xml.send(:'address', "#{row['FirstAddressOne']}, #{row['FirstAddressTwo']}, #{row['FirstAddressThree']}, #{row['FirstAddressFour']}")
      xml.send(:'postcode', row['FirstPost'])
      xml.send(:'phone', row['FirstPhone'])
      xml.send(:'email', row['FirstEmail'])
      xml.send(:'web', row['WebOne'])
      xml.send(:'displayed_hours', row['Times'] + row['TimesTwo'])
      xml.send(:'eligibility_information', row['Restricted'])
    }
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

  get '/' do
    erb :index
  end

  # http://localhost:4567/dev/v1/facilities/all.xml
  get "#{settings.facilities_api_root}/facilities/*" do
    path = params[:splat].first
    category = path.split('.').first

    content_type 'text/xml'

    # as a temp step for now, load all the community contacts
    load_community_contacts

    # build a list of valid facilities
    valid_facilities = []
    @rows.each do |row|
      valid_facilities << row['Id']
    end

    if category.nil?
      halt 400, 'facility category was not provided'
    end

    valid_categories = ['all', 'community groups', 'parking']
    if valid_categories.include?(category) == false and valid_facilities.include?(category) == false
      halt 404, "facility category provided was not found: #{category}"
    end



    #TODO: Only return content for the require category

    #TODO: Generate URI for each facility


    builder = Nokogiri::XML::Builder.new do |xml|
      xml.send(:'facilities') {

        # Are we looking for category summary facilities
        # or are we looking for a specific facility?

        if valid_categories.include?(category)
          @rows.each do |row|
            if row['internaltype'].downcase == category.downcase or category == 'all'
              community_facility_summary(xml, row)
            end
          end
        end

        if valid_facilities.include?(category)

          row = nil
          @rows.each do |check_row|
            if check_row['Id'] == category
              row = check_row
              break
            end
          end

          if row
           community_facility_detailed(xml, row)
          end
        end

      }
    end

    builder.to_xml
  end

  # http://localhost:4567/dev/v2/services.xml
  get "#{settings.services_api_root}/services.xml" do
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
  get "#{settings.services_api_root}/services/*" do
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