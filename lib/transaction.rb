require 'digest'

class Transaction
  attr_reader :recipient, :sender, :amount, :timestamp, :id

  def initialize(sender, recipient, amount)
    @recipient = recipient
    @sender = sender
    @amount = amount
    @timestamp = Time.now
    @id = SecureRandom.hex
  end

  def to_json(options)
    {
      sender: sender,
      recipient: recipient,
      amount: amount,
      timestamp: timestamp,
      id: Digest::SHA256.hexdigest(sender.to_s + recipient .to_s + amount.to_s + timestamp.to_s)
    }.to_json
  end
end
