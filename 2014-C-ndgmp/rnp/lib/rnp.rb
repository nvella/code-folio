# rnp
# by nick

module RNP
  NAME = "RNP"
  VERSION = "0.0.1"
  PROTOCOL = 1
  
  LOCAL_DIR = "#{File.dirname(__FILE__)}/.."
end

require 'socket'
# require 'zlib'
require 'set'

require_relative 'rnp/io_patches'
require_relative 'rnp/set_patches'
require_relative 'rnp/array_patches'

require_relative 'rnp/server'
require_relative 'rnp/connection'
require_relative 'rnp/job'
require_relative 'rnp/config_file'
