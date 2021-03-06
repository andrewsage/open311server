require 'json'
require 'mechanize'
require "sinatra/activerecord"
require 'sinatra/contrib'
require 'logger'


class Open311App < Sinatra::Base
  register Sinatra::ActiveRecordExtension
  register Sinatra::Contrib

  ::Logger.class_eval { alias :write :'<<' }
  access_log = ::File.join(::File.dirname(::File.expand_path(__FILE__)),'log','access.log')
  access_logger = ::Logger.new(access_log)
  error_logger = ::File.new(::File.join(::File.dirname(::File.expand_path(__FILE__)),'log','error.log'),"a+")
  error_logger.sync = true

  configure do
    use ::Rack::CommonLogger, access_logger
  end

  before {
    env["rack.errors"] =  error_logger
  }

  set :database_file, '../config/database.yml'
  set :services_api_root, '/dev/v2'
  set :facilities_api_root, '/dev/v1'
  set :facility_prefix_community_group, 'CG'
  set :facility_prefix_car_park, 'CP'
  set :facility_prefix_school, 'SC'

  before /.*/ do
    if request.url.match(/.json$/)
      request.accept.unshift('application/json')
      request.path_info = request.path_info.gsub(/.json$/,'')
    end
  end

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

    CarPark.delete_all

    # 0 - id
    # 1 - name
    # 2 - lat
    # 3 - long
    # 4 - tariff
    # 5 - accessibility
    # 6 - address
    # 7 - operated by
    raw_data = [
      ["CP01", "Harriet Street", 57.148624,-2.1006504, ""],
      ["CP02", "Loch Street", 57.149373,-2.1001346, ""],
      ["CP03", "The Mall Trinity", 57.1458388,-2.1007275, ""],
      ["CP04", "Shiprow", 57.1468981,-2.093786, ""],
      ["CP05", "Gallowgate", 57.1512768,-2.0986005, ""],
      ["CP06", "West North Street", 57.1499781,-2.0930345, ""],
      ["CP07", "Denburn", 57.148618,-2.1065774, ""],
      ["CP08", "Chapel Street", 57.1458485,-2.1112149, ""],
      ["CP09", "South College Street", 57.1378417,-2.0981296, ""],
      ["CP10", "Union Square", 57.1438026,-2.0953213,
      "0-2 hrs &pound;2.50<br>2-3 hrs &pound;3.50<br>3-4 hrs &pound;4.50<br>4-5 hrs &pound;5.50<br>5-6 hrs &pound;6.50<br>6-7 hrs &pound;10.00<br>7 hrs+ &pound;15.00<br>6pm - 4am &pound;1.00 **<p>**Customers can park for only &pound;1 after 6pm. This rate is applicable to vehicles entering the car park after 6pm and leaving before 4am.</p><p>If you enter the car park before 6pm you will qualify for the &pound;1 tariff, however, will be charged the normal rate for hours prior to 6pm.</p><p>A new daily rate is chargeable from 4am each day.</p><p>Additional part days are chargeable each day as per the rates above.  The maximum charge for any 24 hour period is &pound;15.</p><p>Lost tickets will be chargeable at the full daily rate of &pound;15.</p>"
      ]
    ]


    raw_data.each do |row|
      car_park_data = Hash.new
      car_park_data['Id'] = row[0]
      car_park_data['name'] = row[1]
      car_park_data['lat'] = row[2]
      car_park_data['long'] = row[3]
      car_park_data['tariff'] = row[4]

      car_park = CarPark.find_by_id_public(car_park_data['Id'])
      if car_park.nil?
        car_park = CarPark.create(:id_public => car_park_data['Id'],
          :lat => car_park_data['lat'],
          :long => car_park_data['long'])
      end
      car_park.tariff = car_park_data['tariff']
      car_park.name = car_park_data['name']
      car_park.save
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
        car_park.occupancy_percentage = occupancy_percentage
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
  get "#{settings.facilities_api_root}/facilities/*", :provides => [:xml, :json] do
    path = params[:splat].first
    category = path.split('.').first

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

    respond_to do |f|
      f.json {
        objects = []

            # Are we looking for category summary facilities
            # or are we looking for a specific facility?

            if valid_categories.include?(category)
              if category.downcase == 'community centres' or category == 'all'
                CommunityCentre.all.each do |community_centre|
                  objects << community_centre.summary_json
                end
              end
              if category.downcase == 'parking' or category == 'all'
                CarPark.all.each do |car_park|
                  objects << car_park.summary_json
                end
              end
              if category.downcase == 'schools' or category == 'all'
                School.all.each do |school|
                  objects << school.summary_json
                end
              end
            end

            if valid_facilities.include?(category)
              case category[0, 2]
              when settings.facility_prefix_community_group
                CommunityCentre.all.each do |community_centre|
                  if community_centre.id_public == category
                    objects = community_centre.detailed_json
                    break
                  end
                end

              when settings.facility_prefix_car_park
                CarPark.all.each do |car_park|
                  if car_park.id_public == category
                    objects = car_park.detailed_json
                    break
                  end
                end

              when settings.facility_prefix_school
                School.all.each do |school|
                    if school.id_public == category
                      objects = school.detailed_json
                      break
                    end
                  end
              else
              end
            end

            objects.to_json
       }
      f.xml {
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.send(:'facilities') {

            # Are we looking for category summary facilities
            # or are we looking for a specific facility?

            if valid_categories.include?(category)
              if category.downcase == 'community centres' or category == 'all'
                CommunityCentre.all.each do |community_centre|
                  community_centre.summary_xml(xml)
                end
              end
              if category.downcase == 'parking' or category == 'all'
                CarPark.all.each do |car_park|
                  car_park.summary_xml(xml)
                end
              end
              if category.downcase == 'schools' or category == 'all'
                School.all.each do |school|
                  school.summary_xml(xml)
                end
              end
            end

            if valid_facilities.include?(category)
              case category[0, 2]
              when settings.facility_prefix_community_group
                CommunityCentre.all.each do |community_centre|
                  if community_centre.id_public == category
                    community_centre.detailed_xml(xml)
                    break
                  end
                end

              when settings.facility_prefix_car_park
                CarPark.all.each do |car_park|
                  if car_park.id_public == category
                    car_park.detailed_xml(xml)
                    break
                  end
                end

              when settings.facility_prefix_school
                School.all.each do |school|
                    if school.id_public == category
                      school.detailed_xml(xml)
                      break
                    end
                  end
              else
              end
            end
          }
        end

        builder.to_xml
      }
    end
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