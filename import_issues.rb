#!/usr/bin/ruby
require './lib/backlogII.rb'
require 'optparse'
require 'io/console'
require 'nkf'
require 'csv'




#
# Command
#

OPTS = {}
OptionParser.new do |opt|
  begin
    opt.program_name = File.basename($0)
    opt.version      = '0.1.0'

    opt.banner = "Usage: #{opt.program_name} [options] file.csv"

    opt.separator ''
    opt.separator 'Options:'

    opt.on('-c config.rb', '--config', 'Use ./config.rb settings') {|v| OPTS[:c] = v}

    opt.on_tail('-h', '--help', 'show this help message and exit') do
      puts opt
      exit
    end
    opt.on_tail('-v', '--version', 'show program\'s version number and exit') do
      puts "#{opt.program_name} #{opt.version}"
      exit
    end

    opt.parse!(ARGV)
  rescue => e
    puts "Error: #{e}.\nTry '-h' option for more information."
    exit
  end
end

if OPTS[:c]
  $:.unshift File.join(File.dirname(__FILE__))
  require OPTS[:c]
else
  print 'Space: '
  SPACE = STDIN.gets.chop
  print 'User: '
  USER = STDIN.gets.chop
  print 'Password: '
  PASSWORD = STDIN.noecho(&:gets).chop
  print "\nProject Key: "
  PROJECT_KEY = STDIN.gets.chop
end




#
# Load CSV file
#

CODES = {
    NKF::JIS      => 'JIS',
    NKF::EUC      => 'EUC',
    NKF::SJIS     => 'SJIS',
    NKF::UTF8    	=> 'UTF-8',
    NKF::UTF16    => 'UTF-16',
    NKF::BINARY   => 'BINARY',
    NKF::ASCII    => 'ASCII',
    NKF::UNKNOWN  => 'UNKNOWN',
}

begin
  path_to_csv = ARGV[0]
  f = open(path_to_csv, 'r')
  contents = f.read
  f.close
rescue => e
  puts "Error #{e.faultCode}: #{e.faultString}"
  exit
end

begin
  csv = {}
  case CODES[NKF.guess(contents)]
    when 'UTF-8'
      csv = CSV.read(path_to_csv, headers: true, encoding: 'UTF-8:UTF-8').map(&:to_hash)
    when 'SJIS'
      csv = CSV.read(path_to_csv, headers: true, encoding: 'Shift_JIS:UTF-8').map(&:to_hash)
    else
      puts 'Error: input file type is UTF-8 & SJIS only.'
      exit
  end
rescue => e
  puts "Error #{e.faultCode}: #{e.faultString}"
end




#
# Import issues
#

obj = BacklogII::Object::FileColumnNames.new
client = BacklogII::Client.new(SPACE, USER, PASSWORD)

PROJECT_ID = client.get_project_id(PROJECT_KEY)


# Research attributes[issue types, components & versions(= milestone)] form host space
space_attributes = {
    obj.issue_type => client.get_issue_type_names(PROJECT_ID),
    obj.components => client.get_component_names(PROJECT_ID),
    obj.versions   => client.get_version_names(PROJECT_ID)
}
puts "Check issue's attributes in space"

# Get new attributes[issue types, components & versions(= milestone)] form csv
new_attributes = {}
space_attributes.each do |key, value|
  a = []
  csv.each do |row|
    # Exist attributes in csv row data?
    unless row[key].nil?
      # attributes: Check possibility of multiple selected value
      words = row[key].to_s.split(',')
      words.each do |word|
        word = word.to_s
        # Compare attributes of space & attributes of csv
        unless value.include?(word)
          a.push word
        end
      end
    end
  end
  new_attributes.store(key, a.uniq)
end
puts "Check issue's attributes in csv"

# Create new issue's attributes[issue types, components & versions(= milestone)] to space
new_attributes[obj.issue_type].each do |v|
  client.add_issue_type(PROJECT_ID, v)
end
new_attributes[obj.components].each do |v|
  client.add_component(PROJECT_ID, v)
end
new_attributes[obj.versions].each do |v|
  client.add_version(PROJECT_ID, v)
end
puts "Create new issue's attributes"


# Check Comments length
csv_headers = csv[0].keys.join(', ')
comments_length = csv_headers.scan(obj.comment).length
puts "Check max comments length (#{comments_length})"

# Create issues
csv.each do |row|
  client.create_issues(PROJECT_ID, row)
  latest_key = client.find_latest_issue(PROJECT_ID)
  puts "Create issue: #{latest_key}"
  client.update_issue(latest_key, row)
  puts '  Update resolution & comment'
  client.add_comments(latest_key, comments_length, row)
  puts '  Add comment'
  client.switch_status(latest_key, row)
  puts '  Update status'
  sleep 1
end
puts "\nfinished."