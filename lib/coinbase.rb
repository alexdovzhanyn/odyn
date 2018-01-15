class Coinbase < Transaction
  attr_reader :recipient, :amount, :timestamp, :id

  def initialize(recipient, amount)
    @recipient = recipient
    @amount = amount
    @timestamp = Time.now
    @id = Digest::SHA256.hexdigest(recipient .to_s + amount.to_s + timestamp.to_s)
  end

  def self.appropriate_reward_for_block(block_index)
    # Every 200,000 blocks, we halve the block reward
    100 / 2**(block_index / 200000)
  end

end
