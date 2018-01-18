class Transaction
  attr_reader :sender, :inputs, :outputs, :designations, :timestamp, :id, :fee

  def initialize(designations, inputs)
    @sender = Wallet.new.public_key_hex
    @inputs = inputs.map {|i| i.merge({signature: sign_utxo(i[:txoid])}) }
    @designations = designations
    @timestamp = Time.now
    @outputs, @fee = calculate_outputs
    @id = Digest::SHA256.hexdigest(sender.to_s + calculate_merkle_root(inputs).first.to_s + calculate_merkle_root(@outputs).first.to_s + timestamp.to_s)
  end

  def to_json(options = nil)
    return {
      id: id,
      sender: sender,
      timestamp: timestamp,
      inputs: inputs,
      outputs: outputs,
      fee: fee
    }.to_json
  end

  private #===============================================================

  def sum_inputs
    @inputs.reduce(0) { |sum, input| sum + input[:amount] }
  end

  def calculate_outputs
    outputs = []
    leftovers = sum_inputs

    designations.each_with_index do |designation, idx|
      outputs << { txoid: "#{@id}:#{idx}", address: designation[:address], amount: designation[:amount] }
      leftovers -= designation[:amount]
    end

    return outputs, leftovers
  end

  def sign_utxo(txoid)
    wallet = Wallet.new
    wallet.authorize_utxo(txoid)
  end
end
