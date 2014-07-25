require 'json'

class Open311App < Sinatra::Base

  set :services_api_root, '/dev/v2'
  set :facilities_api_root, '/dev/v1'
  set :facility_prefix_community_group, 'CG'
  set :facility_prefix_car_park, 'CP'
  set :facility_prefix_school, 'SC'

  # The following are temporary data loading routines for development
  # At some future point a database will be used to contain this data

  def load_schools
    @schools = []

    data_path = File.expand_path("../../data/schools.json", __FILE__)
    json = JSON.parse(IO.read(data_path))

    json.each_with_index do |school_json, index|
      school = Hash.new

      school['Id'] = "#{settings.facility_prefix_school}#{index + 1}"
      school['name'] = school_json['school_name']
      school['address'] = school_json['address']
      school['post_code'] = school_json['post_code']
      school['telephone'] = school_json['telephone']
      school['fax'] = school_json['fax']
      school['web'] = school_json['web']
      school['email'] = school_json['email']
      school['school_type'] = school_json['school_type']
      school['head_teacher'] = school_json['head_teacher']
      school['lat'] = school_json['lat']
      school['long'] = school_json['long']

      @schools << school
    end
  end

  def load_car_parks

    raw_data = [
      ["CP01", "Harriet Street Car Park", 57.148624,-2.1006504],
      ["CP02", "Loch Street Car Park", 57.149373,-2.1001346],
      ["CP03", "The Mall Trinity Car Park", 57.1458388,-2.1007275],
      ["CP04", "Shiprow", 57.1468981,-2.093786],
      ["CP05", "Gallowgate Car Park", 57.1512768,-2.0986005],
      ["CP06", "West North Street Car Park", 57.1499781,-2.0930345],
      ["CP07", "Denburn Car Park", 57.148618,-2.1065774],
      ["CP08", "Chapel Street Car Park", 57.1458485,-2.1112149],
      ["CP09", "South College Street Car Park", 57.1378417,-2.0981296],
      ["CP10", "Union Square Car Park", 57.1438026,-2.0953213]
      ]

    @car_parks = []
    raw_data.each do |row|
      car_park = Hash.new

      car_park['Id'] = row[0]
      car_park['name'] = row[1]
      car_park['lat'] = row[2]
      car_park['long'] = row[3]

      @car_parks << car_park
    end
  end

  def load_community_contacts
    # Columns separated by , rows separated by |
    # The file does contain newlines in fields without quotes
    @community_groups = []

    @contacts = []
    @headers = []
    File.open("./data/Contact.txt", "r") do |infile|

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
          #row['Id'] = "#{settings.facility_prefix_community_group}#{row['Id']}"
          @contacts << row
        end
      end
    end

    @headers = []
    @categories = []
    File.open("./data/Category.txt", "r") do |infile|

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
          @categories << row
        end
      end
    end

    @headers = []
    @subcategories = []
    File.open("./data/SubCategory.txt", "r") do |infile|

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
          category = nil
          @categories.each do |check_category|
            if check_category['Id'] == row['CategoryId']
              category = check_category
              break
            end
          end
          row.delete('CategoryId')
          row['Category'] = category['Name']
          @subcategories << row
        end
      end
    end
    @subcategories.sort! { |a, b| a['Name'] <=> b['Name'] }


    @headers = []
    @contactsubcategories = []
    File.open("./data/ContactSubcategory.txt", "r") do |infile|

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
          subcategory = nil
          @subcategories.each do |check_subcategory|
            if check_subcategory['Id'] == row['SubCategoryId']
              subcategory = check_subcategory
              break
            end
          end
          row['SubCategory'] = subcategory['Name'] unless subcategory.nil?
          row['Category'] = subcategory['Category'] unless subcategory.nil?
          contact = nil
          @contacts.each do |check_contact|
            if check_contact['Id'] == row['ContactId']
              contact = check_contact
              break
            end
          end
          if contact
            row.merge!(contact)
            # set the ID to the correct format for Community Groups
            row['Id'] = "#{settings.facility_prefix_community_group}#{row['Id']}"
            @community_groups << row
          end
        end
      end
    end

    @community_groups.sort! { |a, b| a['ItemTitle'] <=> b['ItemTitle'] }
  end

  def community_facility_summary(xml, row)
    xml.send(:'facility') {
=begin
      row.keys.each do |key|
        xml.send(:"#{key}", row[key])
      end
=end
      xml.send(:'id', "#{row['Id']}")
      xml.send(:'category', row['Category'])
      xml.send(:'sub_category', row['SubCategory'])
      xml.send(:'facility_name', row['ItemTitle'])
      xml.send(:'expiration', '2099-12-31T23:59:59Z')
      xml.send(:'type', 'Community Group')
      xml.send(:'brief_description', row['Other'])
    }
  end

  def community_facility_detailed(xml, row)
    xml.send(:'facility') {
      xml.send(:'id', "#{row['Id']}")
      xml.send(:'facility_name', row['ItemTitle'])
      xml.send(:'expiration', '2099-12-31T23:59:59Z')
      xml.send(:'type', 'Community Group')
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

  def parking_facility_summary(xml, row)
    xml.send(:'facility') {
      xml.send(:'id', "#{row['Id']}")
      xml.send(:'facility_name', row['name'])
      xml.send(:'expiration', '2099-12-31T23:59:59Z')
      xml.send(:'type', 'Parking')
      xml.send(:'brief_description', row['name'])
      xml.send(:'lat', row['lat'])
      xml.send(:'long', row['long'])
    }
  end

  def parking_facility_detailed(xml, row)
    xml.send(:'facility') {
      xml.send(:'id', "#{row['Id']}")
      xml.send(:'facility_name', row['name'])
      xml.send(:'expiration', '2099-12-31T23:59:59Z')
      xml.send(:'type', 'Parking')
      xml.send(:'brief_description', row['name'])
      xml.send(:'lat', row['lat'])
      xml.send(:'long', row['long'])
      xml.send(:'features') {
        xml.send(:'occupancy', 500)
        xml.send(:'occupancypercentage', 60)
      }
      xml.send(:'address', "")
      xml.send(:'postcode', "")
      xml.send(:'phone', "")
      xml.send(:'email', "")
      xml.send(:'web', "")
      xml.send(:'displayed_hours', row['Times'])
      xml.send(:'eligibility_information', "")
    }
  end

  def school_facility_summary(xml, row)
    xml.send(:'facility') {
      xml.send(:'id', "#{row['Id']}")
      xml.send(:'facility_name', row['name'])
      xml.send(:'expiration', '2099-12-31T23:59:59Z')
      xml.send(:'type', 'School')
      xml.send(:'brief_description', row['name'])
      xml.send(:'lat', row['lat'])
      xml.send(:'long', row['long'])
    }
  end

  def school_facility_detailed(xml, row)
    xml.send(:'facility') {
      xml.send(:'id', "#{row['Id']}")
      xml.send(:'facility_name', row['name'])
      xml.send(:'expiration', '2099-12-31T23:59:59Z')
      xml.send(:'type', 'School')
      xml.send(:'brief_description', row['name'])
      xml.send(:'lat', row['lat'])
      xml.send(:'long', row['long'])
      xml.send(:'features') {
        row['school_type'].each do |type|
          xml.send(:'school_type', type)
        end
        xml.send(:'head_teacher', row['head_teacher'])
      }
      xml.send(:'address', row['address'])
      xml.send(:'postcode', row['post_code'])
      xml.send(:'phone', row['telephone'])
      xml.send(:'email', row['email'])
      xml.send(:'web', row['web'])
      xml.send(:'eligibility_information', "")
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

  get '/map' do
    erb :map
  end

  # http://localhost:4567/dev/v1/sub_categories/all.xml
  get "#{settings.facilities_api_root}/sub_categories/*" do
  path = params[:splat].first
    category = path.split('.').first

    content_type 'text/xml'

    # as a temp step for now, load all the community contacts
    load_community_contacts

    # build a list of valid facilities
    valid_facilities = []
    @community_groups.each do |row|
      valid_facilities << row['Id']
    end

    if category.nil?
      halt 400, 'facility category was not provided'
    end

    valid_categories = ['all']
    if valid_categories.include?(category) == false and valid_facilities.include?(category) == false
      halt 404, "facility category provided was not found: #{category}"
    end

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.send(:'sub_categories') {

        # Are we looking for category summary facilities
        # or are we looking for a specific facility?

        if valid_categories.include?(category)
          if category.downcase == 'community groups' or category == 'all'
            @subcategories.each do |row|
              xml.send(:'sub_category') {
                row.keys.each do |key|
                xml.send(:"#{key}", row[key])
              end
              }
            end
          end
        end
      }
    end

    builder.to_xml
  end


  # http://localhost:4567/dev/v1/facilities/all.xml
  get "#{settings.facilities_api_root}/facilities/*" do
    path = params[:splat].first
    category = path.split('.').first

    content_type 'text/xml'

    # as a temp step for now, load all the community contacts
    load_community_contacts

    # as a temp step for now, load all the parking data
    load_car_parks

    # as a temp step for now, load all the schools data
    load_schools

    # build a list of valid facilities
    valid_facilities = []
    @community_groups.each do |row|
      valid_facilities << row['Id']
    end
    @car_parks.each do |row|
      valid_facilities << row['Id']
    end
    @schools.each do |row|
      valid_facilities << row['Id']
    end
    if category.nil?
      halt 400, 'facility category was not provided'
    end

    valid_categories = ['all', 'community groups', 'parking', 'schools']
    if valid_categories.include?(category) == false and valid_facilities.include?(category) == false
      halt 404, "facility category provided was not found: #{category}"
    end

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.send(:'facilities') {

        # Are we looking for category summary facilities
        # or are we looking for a specific facility?

        if valid_categories.include?(category)
          if category.downcase == 'community groups' or category == 'all'
            @community_groups.each do |row|
              community_facility_summary(xml, row)
            end
          end
          if category.downcase == 'parking' or category == 'all'
            @car_parks.each do |car_park|
              parking_facility_summary(xml, car_park)
            end
          end
          if category.downcase == 'schools' or category == 'all'
            @schools.each do |school|
              school_facility_summary(xml, school)
            end
          end
        end

        if valid_facilities.include?(category)

          row = nil

          case category[0, 2]
          when settings.facility_prefix_community_group
            @community_groups.each do |check_row|
              if check_row['Id'] == category
                community_facility_detailed(xml, check_row)
                break
              end
            end

          when settings.facility_prefix_car_park
            @car_parks.each do |check_row|
              if check_row['Id'] == category
                parking_facility_detailed(xml, check_row)
                break
              end
            end

          when settings.facility_prefix_school
            @schools.each do |check_row|
                if check_row['Id'] == category
                  school_facility_detailed(xml, check_row)
                  break
                end
              end
          else
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

              @community_groups.each do |row|

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