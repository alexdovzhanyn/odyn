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

  # This should only get called after we've verified that a block is valid
  def append_verified_block(block)
    @chain << block
    @ledger.write(block)

    if block.index % BLOCK_REBALANCE_OFFSET == 0
      rebalance_difficulty
    end
  end

  # Any UTXOs used in a block must be discarded from our UTXO pool, otherwise
  # there will be a possibility of double spending funds
  def update_utxo_pool(block)
    parse_block_utxos(block)
    discard_used_utxos_from_pool(block)
  end

  def rebalance_difficulty
    beginning_of_block_chunk = chain.length - BLOCK_REBALANCE_OFFSET + 1 > 0 ? chain.length - BLOCK_REBALANCE_OFFSET + 1 : 0
    average_seconds_per_block = (chain.last.timestamp.to_f - chain[beginning_of_block_chunk].timestamp.to_f) / BLOCK_REBALANCE_OFFSET
    network_speed_ratio = TARGET_BLOCKTIME / average_seconds_per_block

    prev_difficulty, @difficulty = @difficulty, @difficulty + Math.log(network_speed_ratio, 16)

    puts "Block difficulty set to #{@difficulty}, changed from #{prev_difficulty}.\n Average block time for past #{BLOCK_REBALANCE_OFFSET} blocks was #{average_seconds_per_block} seconds."
  end

  private #===============================================================

  # We need a block to start with, as a basis for everyone to base their chain 
  def generate_genesis_block
    block = Block.new(0, 'Genesis Block', 0, 5.0)
    block.hash = 'GENESIS'

    block
  end

  def parse_block_utxos(block)
    block.transactions.map{|tx| tx.outputs}.flatten.each do |utxo|
      ledger.add_utxo_to_pool(utxo)
    end
  end

  def discard_used_utxos_from_pool(block)
    block.transactions.map{|tx| tx.inputs}.flatten.compact.each do |used_txo|
      ledger.remove_utxo_from_pool(used_txo)
    end
  end
end
