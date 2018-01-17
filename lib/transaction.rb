class Transaction
  attr_reader :sender, :inputs, :outputs, :designations, :timestamp, :id, :signature, :fee

  def initialize(designations, inputs)
    @sender = Wallet.new.public_key_hex
    @inputs = inputs.map {|i| i.merge({signature: sign_utxo(i[:txoid])}) }
    @designations = designations
    @timestamp = Time.now
    @outputs, @fee = calculate_outputs
    @id = Digest::SHA256.hexdigest(sender.to_s + calculate_merkle_root(inputs).first.to_s + calculate_merkle_root(@outputs).first.to_s + timestamp.to_s)
  end

  private #===============================================================

  def sum_inputs
    @inputs.reduce(0) { |sum, input| sum + input[:amount] }
  end

  def calculate_outputs
    outputs = []
    leftovers = sum_inputs

    designations.each do |designation|
      txoid = SecureRandom.hex
      outputs << { txoid: txoid, address: designation[:address], amount: designation[:amount] }
      leftovers -= designation[:amount]
    end

    return outputs, leftovers
  end

  def sign_utxo(txoid)
    wallet = Wallet.new
    wallet.authorize_utxo(txoid)
  end
end
