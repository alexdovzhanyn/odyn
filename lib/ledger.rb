class Ledger
  attr_reader :ledger
  def initialize
    Dir.mkdir('data') unless Dir.exist?('data')
    @ledger = PStore.new('data/ledger.pstore')
    @utxos = PStore.new('data/utxo.pstore')
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

  def latest_blocks(number_of_blocks = 20)
    ledger.transaction do
      ledger.roots.last(number_of_blocks).map{|hash| ledger[hash] }
    end
  end
end
