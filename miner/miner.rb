require_relative '../node/node.rb'

blockchain = Blockchain.new
listener = Thread.new do
  class MinerNode < Odyn
    class << self
      attr_reader :listener
    end

    def initialize
      Thread.current.thread_variable_set(:node, self)

      super
    end

    run!
  end
end

trap("INT") {
  listener.kill
  Thread.current.kill
}

loop do
  if listener.thread_variable_get(:node)&.blockchain
    transactions = listener.thread_variable_get(:node).blockchain.unprocessed_transactions.shift(5)

    if transactions.empty?
      sleep 2
    else
      puts "#{transactions.length} transactions found"
      blockchain.add_block(transactions)
    end
  end
end
