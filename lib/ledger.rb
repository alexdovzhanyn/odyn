class Ledger
  attr_reader :ledger, :utxo_pool

  def initialize
    Dir.mkdir('data') unless Dir.exist?('data')
    @ledger = PStore.new('data/ledger.pstore')
    @utxo_pool = PStore.new('data/utxo.pstore')
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

  def block_by_index(index)
    ledger.instance_variable_get('@table').find{|k,v| v.index == index }.last # Is this hacky?
  end

  def add_utxo_to_pool(utxo)
    utxo_pool.transaction do
      utxo_pool[utxo[:txoid]] = utxo

      utxo_pool.commit
    end
  end

  def remove_utxo_from_pool(utxo)
    utxo_pool.transaction do
      utxo_pool.delete utxo[:txoid]
    end
  end

  def find_utxo(txoid)
    utxo_pool.transaction do
      utxo_pool[txoid]
    end
  end

  def all_utxos
    utxo_pool.transaction do
      utxo_pool.roots.map {|txoid| utxo_pool[txoid]}
    end
  end
end
