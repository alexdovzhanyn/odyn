require 'csv'

class Ledger
  def initialize(filename = 'ledger.txt')
    @filename = filename

    CSV.open(@filename, 'wb') do |ledger|
      ledger << ['index', 'timestamp', 'data', 'previous_hash', 'hash', 'nonce', 'difficulty']
    end
  end

  def write(block)
    CSV.open(@filename, 'a') do |ledger|
      ledger << [block.index, block.timestamp, block.data, block.previous_hash, block.hash, block.nonce, block.difficulty]
    end
  end
end
