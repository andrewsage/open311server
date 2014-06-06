# Columns separated by , rows separated by |
# The file does contain newlines in fields without quotes
rows = []
headers = []
File.open("./data/CommunityContacts.txt", "r") do |infile|
  
  while (line = infile.gets('|'))
    line = line.force_encoding('BINARY')
    line = line.chomp("|")
    # work out the headers
    if headers.count == 0
      headers = line.encode("UTF-8", invalid: :replace, undef: :replace).split(",")
    else
      columns = line.encode("UTF-8", invalid: :replace, undef: :replace).split(",")
      row = Hash.new
      columns.each_with_index { |item, index|
        row[headers[index]] = item
      }
      rows << row
    end 
  end
end

puts "#{rows.count} entries to process"

puts rows[0]
