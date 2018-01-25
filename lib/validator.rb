module Validator
  def self.valid_block?(block, ledger)
    last_block = ledger.latest_blocks(1).last
    valid = [
      block.index == last_block.index + 1,
      block.previous_hash == last_block.hash,
      block.hash == block.calculate_hash,
      valid_coinbase?(block),
      all_transactions_valid?(block.transactions, ledger)
    ].all?

    puts "\e[32mBlock Valid\e[0m" if valid
    return valid
  end

  def self.valid_transaction?(transaction, ledger)
    return false unless transaction.inputs.reduce(0) { |sum, input| sum + input[:amount] } >= transaction.outputs.reduce(0) { |sum, output| sum + output[:amount] }

    transaction.inputs.each do |input|
      utxo = ledger.find_utxo(input[:txoid])
      return false if !utxo || input[:amount] != utxo[:amount] || input[:address] != utxo[:address]

      # Verify the transaction signature
      group = OpenSSL::PKey::EC::Group.new('secp256k1')
      key = OpenSSL::PKey::EC.new(group)
      key.public_key = OpenSSL::PKey::EC::Point.new(group, OpenSSL::BN.new(input[:address], 16))

      return false if !key.dsa_verify_asn1(input[:txoid], Base64.decode64(input[:signature]))
    end

    puts "\e[32mTransaction Valid\e[0m"
    return true
  end

  def self.valid_coinbase?(block)
    # A block must include a coinbase in order to be valid.
    transactions = block.transactions.dup
    coinbase = transactions.shift
    return false if !coinbase.instance_of? Coinbase

    fees = transactions.reduce(0) {|sum,  tx| sum += tx.fee}

    # If the miner is trying to claim a reward too high (or too low), the block is invalid
    coinbase.total == Coinbase.appropriate_reward_for_block(block.index) + fees
  end

  def self.all_transactions_valid?(transactions, ledger)
    transactions = transactions.dup
    transactions.shift

    transactions.all? {|transaction| valid_transaction?(transaction, ledger) }
  end
end
