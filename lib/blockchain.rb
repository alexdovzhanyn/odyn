require 'base64'
require 'observer'

require_relative './block'
require_relative './ledger'
require_relative './transaction'

class Blockchain
  include Observable
  attr_reader :chain, :difficulty, :ledger, :transaction_pool

  def initialize
    @ledger = Ledger.new
    @difficulty = 3

    ledger.write(generate_genesis_block) unless ledger.find('GENESIS')

    @chain = ledger.last_20_blocks
    @transaction_pool = []
  end

  def mine_block(transactions)
    block = Block.new(chain.last.index + 1, transactions, chain.last.hash, difficulty)
    block.mine

    changed
    notify_observers(Base64.encode64(YAML::dump(block)))
  end

  def append_verified_block(block)
    @chain << block
    @ledger.write(block)
  end

  def valid_transaction?(transaction)
    group = OpenSSL::PKey::EC::Group.new('secp256k1')
    key = OpenSSL::PKey::EC.new(group)
    key.public_key = OpenSSL::PKey::EC::Point.new(group, OpenSSL::BN.new(transaction.sender, 16))
    key.dsa_verify_asn1(transaction.id, Base64.decode64(transaction.signature))
  end

  def valid_block?(block)
    return true unless block.index != @chain.last.index + 1 || block.previous_hash != @chain.last.hash || block.hash != block.calculate_hash
  end

  private #===============================================================

  def generate_genesis_block
    block = Block.new(0, 'Genesis Block', 0, 0)
    block.hash = 'GENESIS'

    block
  end
end
