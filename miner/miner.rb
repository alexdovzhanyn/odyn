require_relative '../node/node.rb'
require_relative '../lib/coinbase.rb'

require_relative '../config.rb'

class MinerNode < Odyn
  configure do
    config = Config.settings['miner'];
    set server: "thin"
    set port: config['port']
    set traps: false
    set logging: config['logging']
    set quiet: config['quiet']
    set bind: config['ip']
  end

  def initialize
    super

    miner = Thread.new do
      loop do
        if @blockchain
          transactions = @blockchain.transaction_pool.shift(1000)
          if transactions.empty?
            sleep 2
          else
            puts "#{transactions.length} transactions found"
            transactions.unshift(Coinbase.new(Wallet.new.public_key_hex, 120))
            @blockchain.add_block(transactions)
          end
        end
      end
    end
  end
end

MinerNode.start!
