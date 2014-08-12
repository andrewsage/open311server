require 'json'
require 'mechanize'
require "sinatra/activerecord"

class CarPark < ActiveRecord::Base
end

class School < ActiveRecord::Base
  has_many :school_types
end

class SchoolType < ActiveRecord::Base
  belongs_to :school
end

class CommunityCentre < ActiveRecord::Base
end

class Open311App < Sinatra::Base
  register Sinatra::ActiveRecordExtension

  set :database_file, '../config/database.yml'
  set :services_api_root, '/dev/v2'
  set :facilities_api_root, '/dev/v1'
  set :facility_prefix_community_group, 'CG'
  set :facility_prefix_car_park, 'CP'
  set :facility_prefix_school, 'SC'

  # The following are temporary data loading routines for development
  # At some future point a database will be used to contain this data

  def load_schools

    data_path = File.expand_path("../../data/schools.json", __FILE__)
    json = JSON.parse(IO.read(data_path))

    json.each_with_index do |school_json, index|
      school_data = Hash.new

      school_data['Id'] = "#{settings.facility_prefix_school}#{index + 1}"
      school_data['name'] = school_json['school_name']
      school_data['address'] = school_json['address']
      school_data['post_code'] = school_json['post_code']
      school_data['telephone'] = school_json['telephone']
      school_data['fax'] = school_json['fax']
      school_data['web'] = school_json['web']
      school_data['email'] = school_json['email']
      school_data['school_type'] = school_json['school_type']
      school_data['head_teacher'] = school_json['head_teacher']
      school_data['lat'] = school_json['lat']
      school_data['long'] = school_json['long']

      school = School.find_by_id_public(school_data['Id'])
      if school.nil?
        school = School.create(:id_public => school_data['Id'])
      end
      school.name = school_data['name']
      school.address = school_data['address']
      school.post_code = school_data['post_code']
      school.telephone = school_data['telephone']
      school.fax = school_data['fax']
      school.web = school_data['web']
      school.email = school_data['email']
      school.school_types.destroy_all
      school_data['school_type'].each do |type|
        school.school_types.create(:name => type)
      end

      #school.school_type = school_data['school_type']
      school.head_teacher = school_data['head_teacher']
      school.lat= school_data['lat']
      school.long = school_data['long']
      school.save
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


    raw_data.each do |row|
      car_park_data = Hash.new
      car_park_data['Id'] = row[0]
      car_park_data['name'] = row[1]
      car_park_data['lat'] = row[2]
      car_park_data['long'] = row[3]

      car_park = CarPark.find_by_id_public(car_park_data['Id'])
      if car_park.nil?
        car_park = CarPark.create(:id_public => car_park_data['Id'],
          :name => car_park_data['name'],
          :lat => car_park_data['lat'],
          :long => car_park_data['long'])
      end
    end

    # load and add the live parking data
    doc = Nokogiri::XML(File.open("./data/XMLCarParkData.xml"))
    root = doc.root
    items = root.xpath("carPark")
    items.each do |item|
      id_code = item.at('systemCodeNumber').text
      occupancy = item.at('occupancy').text
      occupancy_percentage = item.at('occupancyPercentage').text
      date = item.at('date').text
      id_code = id_code.sub('-', '')
      car_park = CarPark.find_by_id_public(id_code)
      if car_park
        car_park.occupancy = occupancy
        car_park.save
      end
    end
  end

  def load_community_centres

    load_community_contacts
    agent = Mechanize.new

    @community_groups.each do |row|
      if row['SubCategory'] == 'Community Centres'
        community_centre = CommunityCentre.find_by_id_public(row['Id'])
        if community_centre.nil?
          community_centre = CommunityCentre.create(:id_public => row['Id'])
        end
        community_centre.name = row['ItemTitle']
        community_centre.address = "#{row['FirstAddressOne']}, #{row['FirstAddressTwo']}, #{row['FirstAddressThree']}, #{row['FirstAddressFour']}"
        community_centre.post_code = row['FirstPost']
        community_centre.telephone = row['FirstPhone']
        community_centre.fax = row['FirstFax']
        community_centre.web = row['WebOne']
        community_centre.email = row['FirstEmail']
        community_centre.brief_description = row['Other']
        community_centre.description = row['Other'] + row['OtherTwo']
        community_centre.displayed_hours = row['Times'] + row['TimesTwo']
        community_centre.eligibility_information = row['Restricted']

        json = JSON.parse(agent.get("http://nominatim.openstreetmap.org/search.php?q=#{URI::encode(community_centre.address)}&format=json").body)
        if json.first
          community_centre.lat = json.first['lat']
          community_centre.long = json.first['lon']
        end

        community_centre.save
      end
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

  def parking_facility_summary(xml, car_park)
    xml.send(:'facility') {
      xml.send(:'id', "#{car_park.id_public}")
      xml.send(:'facility_name', car_park.name)
      xml.send(:'expiration', '2099-12-31T23:59:59Z')
      xml.send(:'updated', Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"))
      xml.send(:'type', 'Parking')
      xml.send(:'brief_description', car_park.name)
      xml.send(:'lat', car_park.lat)
      xml.send(:'long', car_park.long)
      xml.send(:'features') {
        xml.send(:'occupancy', car_park.occupancy)
        xml.send(:'capacity', car_park.capacity)
      }
    }
  end

  def parking_facility_detailed(xml, car_park)
    xml.send(:'facility') {
      xml.send(:'id', "#{car_park.id_public}")
      xml.send(:'facility_name', car_park.name)
      xml.send(:'expiration', '2099-12-31T23:59:59Z')
      xml.send(:'updated', Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"))
      xml.send(:'type', 'Parking')
      xml.send(:'brief_description', car_park.name)
      xml.send(:'lat', car_park.lat)
      xml.send(:'long', car_park.long)
      xml.send(:'features') {
        xml.send(:'occupancy', car_park.occupancy)
        xml.send(:'capacity', car_park.capacity)
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

  def community_centre_facility_summary(xml, row)
    xml.send(:'facility') {
      xml.send(:'id', "#{row['id_public']}")
      xml.send(:'facility_name', row['name'])
      xml.send(:'expiration', '2099-12-31T23:59:59Z')
      xml.send(:'type', 'Community Centre')
      xml.send(:'brief_description', row.brief_description)
      xml.send(:'lat', row['lat'])
      xml.send(:'long', row['long'])
    }
  end

  def community_centre_facility_detailed(xml, row)
    xml.send(:'facility') {
      xml.send(:'id', "#{row['id_public']}")
      xml.send(:'facility_name', row['name'])
      xml.send(:'expiration', '2099-12-31T23:59:59Z')
      xml.send(:'type', 'Community Centre')
      xml.send(:'brief_description', row.brief_description)
      xml.send(:'description', row.description)
      xml.send(:'lat', row['lat'])
      xml.send(:'long', row['long'])
      xml.send(:'features') {
      }
      xml.send(:'address', row['address'])
      xml.send(:'postcode', row['post_code'])
      xml.send(:'phone', row['telephone'])
      xml.send(:'email', row['email'])
      xml.send(:'web', row['web'])
      xml.send(:'displayed_hours', row.displayed_hours)
      xml.send(:'eligibility_information', row.eligibility_information)
    }
  end

  def school_facility_summary(xml, row)
    xml.send(:'facility') {
      xml.send(:'id', "#{row['id_public']}")
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
      xml.send(:'id', "#{row['id_public']}")
      xml.send(:'facility_name', row['name'])
      xml.send(:'expiration', '2099-12-31T23:59:59Z')
      xml.send(:'type', 'School')
      xml.send(:'brief_description', row['name'])
      xml.send(:'lat', row['lat'])
      xml.send(:'long', row['long'])
      xml.send(:'features') {
        row.school_types.each do |type|
          xml.send(:'school_type', type.name)
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

    # build a list of valid facilities
    valid_facilities = []
    CommunityCentre.all.each do |row|
      valid_facilities << row['id_public']
    end
    CarPark.all.each do |row|
      valid_facilities << row['id_public']
    end
    School.all.each do |row|
      valid_facilities << row['id_public']
    end
    if category.nil?
      halt 400, 'facility category was not provided'
    end

    valid_categories = ['all', 'community centres', 'parking', 'schools']
    if valid_categories.include?(category) == false and valid_facilities.include?(category) == false
      halt 404, "facility category provided was not found: #{category}"
    end

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.send(:'facilities') {

        # Are we looking for category summary facilities
        # or are we looking for a specific facility?

        if valid_categories.include?(category)
          if category.downcase == 'community centres' or category == 'all'
            CommunityCentre.all.each do |community_centre|
              community_centre_facility_summary(xml, community_centre)
            end
          end
          if category.downcase == 'parking' or category == 'all'
            CarPark.all.each do |car_park|
              parking_facility_summary(xml, car_park)
            end
          end
          if category.downcase == 'schools' or category == 'all'
            School.all.each do |school|
              school_facility_summary(xml, school)
            end
          end
        end

        if valid_facilities.include?(category)

          row = nil

          case category[0, 2]
          when settings.facility_prefix_community_group
            CommunityCentre.all.each do |check_row|
              if check_row.id_public == category
                community_centre_facility_detailed(xml, check_row)
                break
              end
            end

          when settings.facility_prefix_car_park
            CarPark.all.each do |check_row|
              if check_row.id_public == category
                parking_facility_detailed(xml, check_row)
                break
              end
            end

          when settings.facility_prefix_school
            School.all.each do |check_row|
                if check_row.id_public == category
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

  # Handle requests to reload the source data
  get '/load_car_park_data' do
    load_car_parks
    redirect '/'
  end

  get '/load_school_data' do
    load_schools
    redirect '/'
  end

  get '/load_community_centres_data' do
    load_community_centres
    redirect '/'
  end
end