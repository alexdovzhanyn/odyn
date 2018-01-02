require 'sinatra'
require 'pry'

$transactions = []

post '/new-transaction' do
  transaction = {
    sender: params[:sender],
    receiver: params[:receiver],
    amount: params[:amount],
    timestamp: Time.now,
    id: SecureRandom.hex
  }

  broadcast_transaction(transaction)
  transaction.to_json
end

def broadcast_transaction

end
