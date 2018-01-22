require_relative '../node/node.rb'
require_relative './wallet.rb'
require_relative './wallet_cli.rb'

class WalletNode < Odyn
  CONFIG = Config.settings[:wallet]

  configure do
    set server: "thin"
    set port: CONFIG['port']
    set traps: false
    set logging: Logger::ERROR
    set quiet: CONFIG['quiet']
    set bind: CONFIG['ip']
  end

  def initialize
    super
    async do
      WalletCli.new(@blockchain)
    end
  end
end

WalletNode.start!
