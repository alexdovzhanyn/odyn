class Coinbase < Transaction
  attr_reader :timestamp, :id

  def initialize(miner_address, amount)
    @timestamp = Time.now
    @id = Digest::SHA256.hexdigest(miner_address .to_s + timestamp.to_s)
    @outputs = [{txoid: "#{@id}:0", address: miner_address, amount: amount}]
  end

  def self.appropriate_reward_for_block(block_index)
    # Every 200,000 blocks, we halve the block reward
    100 / 2**(block_index / 200000)
  end

  def total
    outputs.first[:amount]
  end
end
