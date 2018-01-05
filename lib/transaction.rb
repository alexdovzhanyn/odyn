class Transaction
  attr_reader :receiving_address, :sender_address, :tokens

  def initialize(sender, recipient, amount)
    @recipient = recipient
    @sender = sender
    @amount = amount
  end

  def broadcast
  end
end
