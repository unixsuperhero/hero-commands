#!/usr/bin/env ruby

require 'nokogiri'


html_file = 'regexp-info-quickref.html'

data = IO.read(html_file)

page = Nokogiri::HTML(data)

first_table = page.css('table')[2]
second_table = page.css('table')[3]

re_features = first_table.css('tr td:last-child').flat_map(&:text).sort.uniq

re_features += second_table.css('tr td:last-child').flat_map(&:text).sort.uniq

filesize = IO.write('regexp_features', re_features.join("\n"))

puts
puts format('number of features: %s', re_features.length)
puts format('filesize: %s', filesize)
puts

