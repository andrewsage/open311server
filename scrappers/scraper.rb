# -*- coding: utf-8 -*-

require 'json'
require 'mechanize'
class Scrapper

  SOURCE_URL = "http://www.aberdeencity.gov.uk/education_learning/schools/scc_schools_list.asp"
  # Aberdeen format post code
  POST_CODE = /AB[0-9]{2} [0-9][A-Z]{2}/


  def scrape
    schools = []
    agent = Mechanize.new
    doc = agent.get(SOURCE_URL).parser

    doc.css('table').each do |table|
      table.css('tbody').each do |body|
        body.css('tr').each do |row|
          if row.css('td').count > 0
            cols = row.css('td').map {|r| r.text.lstrip.rstrip.squeeze(" ") }
            school_name = row.css('td')[1].css('strong').text
            post_code = extract_post_code(cols[1])
            address_line = cols[1]
            address_line = address_line.sub(school_name, "")
            address_line = address_line.sub(post_code, "")
            p URI::encode(extract_address(address_line))
            json = JSON.parse(agent.get("http://nominatim.openstreetmap.org/search.php?q=#{URI::encode(extract_address(address_line))}&format=json").body)
            if json.first
              lat = json.first['lat']
              long = json.first['lon']
            else
              lat = ""
              long = ""
            end
            datum = {
              school_type: convert_school_type(cols[0]),
              school_name: school_name,
              address: extract_address(address_line),
              post_code: post_code,
              email: extract_email(cols[1]),
              web: extract_web(cols[1]),
              head_teacher: cols[2],
              telephone: cols[3],
              fax: cols[4],
              lat: lat,
              long: long
            }
            puts JSON.dump(datum)
            schools << datum
          end
        end
      end
    end

    #puts JSON.dump(schools)

    File.open("schools.json","w") do |f|
      f.write(schools.to_json)
    end

  end

  def convert_school_type(raw)
    type_mappings = {"I" => "Infant",
      "N" => "Nursery",
      "P" => "Primary",
      "SP" => "Special Needs Unit / Base / School",
      "PSC" => "Pupil Support Centre",
      "6YRS" => "Secondary School up to 6th year - all Secondary Schools have Pupil Support Centres",
      "CC" => "Community Centre"}

    types = raw.split('/')

    converted = []
    types.each do |type|
      converted << type_mappings[type]
    end

    converted
  end

  def extract_name(raw)
    p raw
    raw = raw.squeeze(" ")
    lines = raw.split(/\n|,/)
    lines.each_with_index do |line, index|
      lines[index] = line.lstrip.rstrip
    end

    lines[0]
  end

  def extract_address(raw)
    raw = raw.squeeze(" ")
    lines = raw.split(/\n|,/)
    address = []
    lines.each_with_index do |line, index|
        line = line.lstrip.rstrip
        if line.empty?
        elsif line.downcase.match(/email:(.)*/)
        elsif line.match(/http:(.)*|www.(.)*/)
        else
          address << line
        end
    end

    address.join(', ')
  end

  def extract_post_code(raw)
    post_code = raw.match(POST_CODE).to_s
  end

  def extract_email(raw)
    email = ""
    raw = raw.squeeze(" ")
    lines = raw.split(/\n|,/)
    lines.each_with_index do |line, index|
      lines[index] = line.lstrip.rstrip
      if lines[index].downcase.match(/email:(.)*/)
        email = lines[index].downcase.sub(/email:/, "")
        break
      end
    end

    email
  end

  def extract_web(raw)
    web = ""
    raw = raw.squeeze(" ")
    lines = raw.split(/\n|,/)
    lines.each_with_index do |line, index|
      lines[index] = line.lstrip.rstrip
      if lines[index].match(/http:(.)*|www.(.)*/)
        web = line
        break
      end
    end

    web
  end
end

s = Scrapper.new
s.scrape