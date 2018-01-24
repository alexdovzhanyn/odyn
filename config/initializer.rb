require 'sinatra/base'
require 'sinatra/json'
require 'thin'
require 'json'
require 'pry'
require 'httparty'
require 'yaml'
require 'digest'
require 'base64'
require 'observer'
require 'openssl'
require 'pstore'
require 'logger'

require_relative '../lib/helpers.rb'
require_relative '../lib/validator.rb'
require_relative '../lib/ledger.rb'
require_relative '../lib/transaction.rb'
require_relative '../lib/coinbase.rb'
require_relative '../lib/block.rb'
require_relative '../lib/blockchain.rb'
require_relative '../config.rb'

# Turn off shitty logging
module Thin
  module Logging
    def log_info(msg); return; end
  end
end

class Rack::CommonLogger
  def call(env)
    @app.call(env)
  end
end
