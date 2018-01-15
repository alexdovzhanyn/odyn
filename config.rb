require 'yaml'

module Config
  attr_reader :settings
  extend self

  GLOBAL_CONFIG = './config/global.yml'
  MINER_CONFIG = './config/miner.yml'
  NODE_CONFIG = './config/node.yml'

  def load!()
    @settings = {}
    env = YAML::load_file(GLOBAL_CONFIG)['env']

    @settings[:env] = env
    @settings[:node] = YAML::load_file(NODE_CONFIG)[env]
    @settings[:miner] = YAML::load_file(MINER_CONFIG)[env]
  end
end

Config.load!
