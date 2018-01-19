class Transaction
  attr_reader :inputs, :outputs, :designations, :timestamp, :id, :fee

  def initialize(designations, inputs)
    @inputs = inputs
    @designations = designations
    @timestamp = Time.now
    @id = Digest::SHA256.hexdigest(calculate_merkle_root(inputs).first.to_s + timestamp.to_s)
    @outputs, @fee = calculate_outputs
  end

  def to_json(options = nil)
    return {
      id: id,
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
end
