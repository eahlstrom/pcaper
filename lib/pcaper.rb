require 'sequel'
require 'digest'

module Pcaper
  VERSION = "0.0.1"
  DIR = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  DB = Sequel.sqlite(File.join(DIR, 'db', 'pcaps.db'))

  module Models
  end
end
Sequel::Model.db = Pcaper::DB

require 'pcaper/capinfo'
require 'pcaper/find_closed_pcaps'
require 'pcaper/models/pcaps'
require 'pcaper/models/directory'

