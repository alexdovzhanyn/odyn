require 'digest'
require 'pry'
require 'json'

class Coinbase < Transaction
  attr_reader :recipient, :amount, :timestamp, :id

  def initialize(recipient, amount)
    @recipient = recipient
    @amount = amount
    @timestamp = Time.now
    @id = Digest::SHA256.hexdigest(recipient .to_s + amount.to_s + timestamp.to_s)
  end

end
