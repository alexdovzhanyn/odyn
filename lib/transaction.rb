require 'digest'
require 'pry'
require 'json'

require_relative '../wallet/wallet.rb'

class Transaction
  attr_reader :recipient, :sender, :amount, :timestamp, :id, :signature

  def initialize(recipient, amount)
    @recipient = recipient
    @sender = Wallet.new.public_key_hex
    @amount = amount
    @timestamp = Time.now
    @id = Digest::SHA256.hexdigest(sender.to_s + recipient .to_s + amount.to_s + timestamp.to_s)
    @signature = sign_transaction
  end

  private #===============================================================

  def sign_transaction
    wallet = Wallet.new
    wallet.authorize_transaction(@id)
  end
end
