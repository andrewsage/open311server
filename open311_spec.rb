ENV['RACK_ENV'] = 'test'

require './open311'
require 'rspec'
require 'rack/test'
require 'nokogiri'

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

describe 'The Open311 App' do
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  it "says hello" do
    get '/hi'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('Hello World!')
  end
  
  describe 'lists services' do
    it "should return 404 for invalid jurisdiction_id" do
      get '/dev/v2/services.xml?jurisdiction_id=city.gov'
      expect(last_response.status).to eq(404)
      expect(last_response.body).to eq('jurisdiction_id provided was not found')
    end
    
    it "should be xml" do 
      get '/dev/v2/services.xml'
      expect(last_response['Content-Type']).to start_with('text/xml')
    end
    
    it "should have services tag" do
      get '/dev/v2/services.xml'
      xml_doc  = Nokogiri::XML(last_response.body)
      expect(xml_doc.xpath('services')).not_to be_empty
    end
    
    it "each service should contain the required fields" do
      required_fields = %w(service_code service_name description metadata type keywords group)
      
      get '/dev/v2/services.xml'
      xml_doc  = Nokogiri::XML(last_response.body)
      xml_doc.xpath("//service").each do |service_xml|
        required_fields.each do |field|
          #puts "#{field} = #{service_xml.xpath(field).text}"
          expect(service_xml.xpath(field)).not_to be_empty
        end
      end
    end
    
    describe "each service should have valid values for" do
      it "metadata" do
        valid_values = %w(true false)
      
        get '/dev/v2/services.xml'
        xml_doc  = Nokogiri::XML(last_response.body)
        xml_doc.xpath("//service").each do |service_xml|
          expect(valid_values).to include(service_xml.xpath('metadata').text)
        end
      end
      
      it "type" do
        valid_values = %w(realtime batch blackbox)
      
        get '/dev/v2/services.xml'
        xml_doc  = Nokogiri::XML(last_response.body)
        xml_doc.xpath("//service").each do |service_xml|
          expect(valid_values).to include(service_xml.xpath('type').text)
        end
      end
    end
  end
  
  describe 'get service' do
    it "should be xml" do
      get '/dev/v2/services/001.xml'
      expect(last_response['Content-Type']).to start_with('text/xml')
    end
    
    it "should return 400 for no service code" do
      get '/dev/v2/services/'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('service_code was not provided')
    end
    
    it "should return 404 for invalid service code" do
      get '/dev/v2/services/fred'
      expect(last_response.status).to eq(404)
      expect(last_response.body).to eq('service_code provided was not found')
    end
    
    it "should return 404 for invalid jurisdiction_id" do
      get '/dev/v2/services/001.xml?jurisdiction_id=city.gov'
      expect(last_response.status).to eq(404)
      expect(last_response.body).to eq('jurisdiction_id provided was not found')
    end
    
    it "should have a service_defintion tag as the root" do
      get '/dev/v2/services/001.xml'
      xml_doc  = Nokogiri::XML(last_response.body)
      expect(xml_doc.xpath('service_definition')).not_to be_empty
    end
    
    it "should have a service code that matches the requested service code" do  
      service_code = '001'
      get "/dev/v2/services/#{service_code}.xml"
      xml_doc  = Nokogiri::XML(last_response.body)
      service_xml = xml_doc.xpath('service_definition')
      expect(service_xml.xpath('service_code').text).to eq(service_code)  
    end
    
    it "should have an attributes node" do
      get '/dev/v2/services/001.xml'
      xml_doc  = Nokogiri::XML(last_response.body)
      attributes_xml = xml_doc.xpath('service_definition/attributes')
      expect(attributes_xml).not_to be_empty
    end
    
  end
end