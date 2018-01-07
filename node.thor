
require 'thor'

require_relative './node/node.rb'

# run form cli example: 
#    thor node:port 9999

class Node < Thor
    desc "blockchain node args", "provides arguments for node initialization"
    def port(port_num)
      Odyn.port = port_num
      Odyn.start!
    end
end
  