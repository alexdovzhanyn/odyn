class Block
  attr_reader :index, :timestamp, :nonce, :transactions, :previous_hash, :difficulty, :merkle_root
  attr_accessor :hash

  def initialize(index,  transactions, previous_hash, difficulty)
    @index = index
    @timestamp = nil
    @transactions = transactions
    @previous_hash = previous_hash
    @nonce = 0
    @hash = (2**256-1).to_s(16)
    @difficulty = difficulty
  end

  def calculate_hash
    @hash = Digest::SHA256.hexdigest(@index.to_s + @previous_hash.to_s + @nonce.to_s + @merkle_root)
  end

  def mine
    puts "Calculating Merkle root...."
    @merkle_root = calculate_merkle_root(transactions.map{|transaction| transaction.id}).first
    puts "\e[34mMerkle root found:\e[0m #{@merkle_root}\n"

    puts "Mining Block: #{index}"
    time_started = Time.now

    # We want to find a number that is lower than the difficulty target
    # 16 to the power of 64 lets us capture all numbers in the 64 hex space number scheme
    # The difficulty determines the scale at which we set the threshold for the difficulty
    target = (16**(64 - @difficulty) - 1).round(0)

    until @hash.to_i(16) < target
      @nonce += 1
      @hash = calculate_hash
      speed = sprintf("%.2f KH/s", @nonce/Time.at(Time.now - time_started).to_f/1000)

      print "Block hash: #{hash}\t Time Elapsed: #{Time.at((Time.now - time_started).to_i).utc.strftime("%H:%M:%S")} Speed: #{speed}\r"
      $stdout.flush
    end

    @timestamp = Time.now
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
end
