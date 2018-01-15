require_relative '../node/node.rb'

class MinerNode < Odyn
  CONFIG = Config.settings[:miner]

  configure do
    set server: "thin"
    set port: CONFIG['port']
    set traps: false
    set logging: CONFIG['logging']
    set quiet: CONFIG['quiet']
    set bind: CONFIG['ip']
  end

  def initialize
    super

    miner = async do
      loop do
        if @blockchain
          transactions = @blockchain.transaction_pool.shift(1000)
          if transactions.empty?
            sleep 2
          else
            puts "#{transactions.length} transactions found"
            transactions.unshift(Coinbase.new(Wallet.new.public_key_hex, 120))
            @blockchain.mine_block(transactions)
          end
        end
      end
    end
  end
end

MinerNode.start!
