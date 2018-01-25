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
          puts "#{transactions.length} transactions found"

          fees = transactions.reduce(0) {|sum,  tx| sum += tx.fee}

          # Add a coinbase to the beginning of the block in order to credit the miner
          # and make the block valid (the first transaction in a block must be a coinbase)
          transactions.unshift(Coinbase.new(CONFIG['wallet_address'], Coinbase.appropriate_reward_for_block(@blockchain.chain.last.index + 1) + fees))
          @blockchain.mine_block(transactions)
        end
      end
    end
  end
end

MinerNode.start!
