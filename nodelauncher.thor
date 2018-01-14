
require 'thor'

require_relative './node/node.rb'

class NodeLauncher < Thor
    desc "blockchain node args", "provides arguments for node initialization"
    def port(port_num)
      begin
        Odyn.set :port, Integer(port_num)
        Odyn.start!
      rescue Exception => e
        puts e
      end
    end
end
