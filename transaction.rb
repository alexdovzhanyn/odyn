class Transaction
  attr_reader :receiving_address, :sender_address, :tokens

  def initialize(sender, receiver, amount)
    @receiving_address = receiver
    @sender_address = sender
    @tokens = amount
  end

  def broadcast
  end
end
