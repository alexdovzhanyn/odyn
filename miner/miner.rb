require_relative '../node/node.rb'
require_relative '../lib/coinbase.rb'

class MinerNode < Odyn
  configure do
    set server: "thin"
    set port: 3333
    set traps: false
    set logging: nil # Should be set to nil for production
    set quiet: true # Should be set to true for production
    set bind: '0.0.0.0'
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
