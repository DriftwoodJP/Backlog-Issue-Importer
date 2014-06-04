$:.unshift File.join(File.dirname(__FILE__))

module BacklogII
  require 'backlogII/api'
  require 'backlogII/object'
  require 'backlogII/client'
end