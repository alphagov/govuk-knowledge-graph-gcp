#!/usr/bin/env ruby
require 'optparse'
require 'json'
require 'govspeak'

# Parse the command-line arguments
options = {}
OptionParser.new do |parser|
  parser.on("--input_col COLUMN", "The column name of the column to convert from govspeak to html.") do |v|
    options[:input_col] = v
  end

  parser.on("--id_cols x,y,z", Array, "Names of columns to be preserved in the output, separated by commas, e.g. --id_cols=url,slug") do |v|
    options[:id_cols] = v
  end
end.parse!

raise OptionParser::MissingArgument if options[:input_col].nil?

ARGF.each_line do |line|
  json = JSON.parse(line)
  out = {}
  options[:id_cols].each do |id_col|
    out[id_col] = json[id_col]
  end
  out["html"] = Govspeak::Document.new(json[options[:input_col]]).to_html
  STDOUT.puts JSON::dump(out)
end
