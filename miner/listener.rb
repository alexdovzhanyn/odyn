require 'sinatra/base'
require 'thin'

class Listener < Sinatra::Base
  attr_accessor :transactions

  configure do
    set server: "thin"
    set port: 9999
    set traps: false
    set logging: nil
    set quiet: true
  end

  def initialize
    @transactions = []
    Thread.current.thread_variable_set(:listener, self)

    super
  end

  post '/' do
    @transactions << {
      sender: params[:sender],
      receiver: params[:receiver],
      amount: params[:amount],
      time_created: Time.now,
      id: SecureRandom.hex
    }

    @transactions.to_json
  end
end
