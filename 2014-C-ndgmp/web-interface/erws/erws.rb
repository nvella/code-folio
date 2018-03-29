# Extensible Ruby Web Server

module ERWS
  NAME = "ERWS"
  VERSION = "0.0.1"
end

require 'socket'

require_relative 'erws/server'
require_relative 'erws/connection'
require_relative 'erws/path_base'
require_relative 'erws/path_physical'
