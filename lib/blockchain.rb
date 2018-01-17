class Blockchain
  include Observable
  attr_reader :chain, :difficulty, :ledger, :transaction_pool

  TARGET_BLOCKTIME = 120.0 # 2 minutes
  BLOCK_REBALANCE_OFFSET = 10080 # 10080 blocks at 2 minutes each should be every 2 weeks

  def initialize
    @ledger = Ledger.new

    ledger.write(generate_genesis_block) unless ledger.find('GENESIS')

    @chain = ledger.latest_blocks
    @difficulty = chain.last.difficulty
    @transaction_pool = []
  end

  def mine_block(transactions)
    block = Block.new(chain.last.index + 1, transactions, chain.last.hash, difficulty)
    block.mine

    # We've found the block hash. Notify the observers (Node.rb) that it should verify
    # the integrity of the block and broadcast it to peers
    changed
    notify_observers(Base64.encode64(YAML::dump(block)))
  end

  def append_verified_block(block)
    @chain << block
    @ledger.write(block)

    if block.index % BLOCK_REBALANCE_OFFSET == 0
      rebalance_difficulty
    end
  end

  def valid_transaction?(transaction)
    return false unless transaction.inputs.reduce(0) { |sum, input| sum + input[:amount] } >= transaction.designations.reduce(0) { |sum, designation| sum + designation[:amount] }
    valid = true

    transaction.inputs.each do |input|
      group = OpenSSL::PKey::EC::Group.new('secp256k1')
      key = OpenSSL::PKey::EC.new(group)
      key.public_key = OpenSSL::PKey::EC::Point.new(group, OpenSSL::BN.new(input[:address], 16))

      if !key.dsa_verify_asn1(input[:txoid], Base64.decode64(input[:signature]))
        valid = false
      end
    end

    return valid
  end

  def valid_block?(block)
    [
      block.index == @chain.last.index + 1,
      block.previous_hash == @chain.last.hash,
      block.hash == block.calculate_hash,
      valid_coinbase?(block),
      all_transactions_valid?(block.transactions)
    ].all?
  end

  def rebalance_difficulty
    beginning_of_block_chunk = chain.length - BLOCK_REBALANCE_OFFSET + 1 > 0 ? chain.length - BLOCK_REBALANCE_OFFSET + 1 : 0
    average_seconds_per_block = (chain.last.timestamp.to_f - chain[beginning_of_block_chunk].timestamp.to_f) / BLOCK_REBALANCE_OFFSET
    network_speed_ratio = TARGET_BLOCKTIME / average_seconds_per_block

    prev_difficulty, @difficulty = @difficulty, Math.log(network_speed_ratio, 16)

    puts "Block difficulty set to #{@difficulty}, changed from #{prev_difficulty}.\n Average block time for past #{BLOCK_REBALANCE_OFFSET} blocks was #{average_seconds_per_block} seconds."
  end

  private #===============================================================

  def generate_genesis_block
    block = Block.new(0, 'Genesis Block', 0, 5.0)
    block.hash = 'GENESIS'

    block
  end

  def valid_coinbase?(block)
    # A block must include a coinbase in order to be valid.
    transactions = block.transactions.dup
    coinbase = transactions.shift
    return false if !coinbase.instance_of? Coinbase

    fees = transactions.reduce(0) {|sum,  tx| sum += tx.fee}

    # If the miner is trying to claim a reward too high (or too low), the block is invalid
    coinbase.amount <= Coinbase.appropriate_reward_for_block(block.index) + fees
  end

  def all_transactions_valid?(transactions)
    transactions = transactions.dup
    transactions.shift

    transactions.all? {|transaction| valid_transaction? transaction }
  end
end
