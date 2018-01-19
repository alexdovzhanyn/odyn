require_relative '../node/node.rb'
require_relative './wallet.rb'

class WalletNode < Odyn
  CONFIG = Config.settings[:wallet]

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

    async do
      wallet = Wallet.new

      loop do
        block_to_discard_at = wallet.discard_at_which_block?(wallet.primary_key_hex)
        if @blockchain.chain.last.index >= block_to_discard_at
          puts 'Rotating Keys...'
          wallet.rotate_keys
        end
      end
    end
  end
end

WalletNode.start!
