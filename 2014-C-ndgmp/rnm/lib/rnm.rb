# rnm
# by nick

module RNM
  NAME = 'RNM'
  VERSION = '0.0.1'
  PROTOCOL = 0
  
  LOCAL_DIR = "#{File.dirname(__FILE__)}/.."
end

require 'socket'
require 'zlib'
require 'set'

require_relative 'rnm/set_patches'

require_relative 'rnm/application'
require_relative 'rnm/remote_pool'
require_relative 'rnm/gol_world'
require_relative 'rnm/worker'
require_relative 'rnm/job'
