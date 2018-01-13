require 'digest'

class Block
  attr_reader :index, :timestamp, :nonce, :transactions, :previous_hash, :difficulty, :merkle_root
  attr_accessor :hash

  def initialize(index,  transactions, previous_hash, difficulty)
    @index = index
    @timestamp = Time.now
    @transactions = transactions
    @previous_hash = previous_hash
    @nonce = 0
    @hash = ""
    @difficulty = difficulty
  end

  def calculate_hash
    @hash = Digest::SHA256.hexdigest(@index.to_s + @timestamp.to_s + @previous_hash.to_s + @nonce.to_s + @merkle_root)
  end

  def mine
    puts "Calculating Merkle root...."
    @merkle_root = calculate_merkle_root(transactions.map{|transaction| transaction.id}).first
    puts "Merkle root found: #{@merkle_root}\n"

    puts "Mining Block: #{index}"
    time_started = Time.now

    until @hash.start_with?("0" * difficulty)
      @nonce += 1
      @hash = calculate_hash
      speed = sprintf("%.2f KH/s", @nonce/Time.at(Time.now - time_started).to_f/1000)

      print "Block hash: #{hash}\t Time Elapsed: #{Time.at((Time.now - time_started).to_i).utc.strftime("%H:%M:%S")} Speed: #{speed}\r"
      $stdout.flush
    end

    puts "\nCalculated block hash: #{hash}, using nonce: #{nonce}"
  end

  def to_json(options = nil)
    return {
      index: index,
      timestamp: timestamp,
      merkle_root: merkle_root,
      hash: hash,
      previous_hash: previous_hash,
      difficulty: difficulty,
      nonce: nonce,
      total_transactions: transactions.length,
      transactions: transactions
    }.to_json
  end

  def calculate_merkle_root(transactions)
    unless transactions.length == 1
      transactions = calculate_merkle_root(transactions.each_slice(2).map{|a, b| Digest::SHA256.hexdigest(a.to_s + b.to_s)})
    end

    transactions
  end
end
