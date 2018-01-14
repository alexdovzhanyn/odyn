require 'yaml'

module Config
    extend self
  
    @settings = {}
    attr_reader :settings

    GLOBAL_CONFIG = './config/global.yml'   
    MINER_CONFIG = './config/miner.yml'
    NODE_CONFIG = './config/node.yml'

    def load!()
      global = YAML::load_file(GLOBAL_CONFIG)
      miner = YAML::load_file(MINER_CONFIG)
      node = YAML::load_file(NODE_CONFIG)
      
      env = global['env']
      
      @settings['env'] = env;
      @settings['node'] = node[env];
      @settings['miner'] = miner[env];
    end
end

Config.load!
