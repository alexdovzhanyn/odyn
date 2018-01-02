require_relative './listener.rb'
require_relative '../blockchain.rb'



blockchain = Blockchain.new
listener = Thread.new { Listener.run! }

trap("INT") {
  listener.kill
  Thread.current.kill
}

loop do
  if listener.thread_variable_get(:listener)
    transactions = listener.thread_variable_get(:listener).transactions.shift(5)

    if transactions.empty?
      sleep 2
    else
      puts "#{transactions.length} transactions found"
      blockchain.add_block(transactions)
    end
  end
end
