require 'digest'

class Block
  attr_reader :index, :timestamp, :nonce, :hash, :transactions, :previous_hash, :difficulty

  def initialize(index,  transactions, previous_hash, difficulty)
    @index = index
    @timestamp = Time.now
    @transactions = transactions
    @previous_hash = previous_hash
    @hash = calculate_hash
    @nonce = 0
    @difficulty = difficulty
  end

  def calculate_hash
    @hash = Digest::SHA256.hexdigest(@index.to_s + @timestamp.to_s + @transactions.to_s + @previous_hash.to_s + @nonce.to_s)
  end

  def mine
    puts "Mining Block: #{index}"
    time_started = Time.now

    until @hash.start_with?("0" * difficulty)
      @nonce += 1
      @hash = calculate_hash
      print "Block hash: #{hash}\t Time Elapsed: #{Time.at((Time.now - time_started).to_i).utc.strftime("%H:%M:%S")}\r"
      $stdout.flush
    end

    puts "\nCalculated block hash: #{hash}, using nonce: #{nonce}"
  end

  def to_json(*)
    return {
      index: index,
      timestamp: timestamp,
      transactions: transactions,
      previous_hash: previous_hash,
      hash: hash,
      nonce: nonce,
      difficulty: difficulty
    }.to_json
  end
end
