require 'pstore'

class Ledger
  attr_reader :ledger
  def initialize
    @ledger = PStore.new('ledger.pstore')
  end

  def write(block)
    ledger.transaction do
      ledger[block.hash] = block

      ledger.commit
    end
  end

  def find(hash)
    ledger.transaction do
      ledger[hash]
    end
  end

  def last_20_blocks
    ledger.transaction do
      ledger.roots.last(20).map{|hash| ledger[hash] }
    end
  end
end
