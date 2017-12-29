require './block'
require './ledger'

class Blockchain
  attr_reader :chain, :difficulty, :ledger

  def initialize
    genesis = generate_genesis_block
    @chain = [genesis]
    @difficulty = 5

    @ledger = Ledger.new
    @ledger.write(genesis)
  end

  def generate_genesis_block
    Block.new(0, 'Genesis Block', 0)
  end

  def add_block(block)
    block.mine(difficulty)

    if valid_block? block
      @chain << block
      @ledger.write(block)
    else
      puts "Invalid block: #{block}"
    end
  end

  def valid_block?(block)
    return true unless block.index != @chain.last.index + 1 || block.previous_hash != @chain.last.hash || block.hash != block.calculate_hash
  end
end
