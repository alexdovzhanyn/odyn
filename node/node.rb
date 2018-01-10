require 'sinatra/base'
require 'sinatra/json'
require 'thin'
require 'json'
require 'pry'
require 'httparty'

require_relative '../lib/blockchain.rb'
require_relative '../wallet/wallet.rb'

class Odyn < Sinatra::Base
  attr_accessor :blockchain

  DEFAULT_PORT = 9999

  configure do
    set server: "webrick"
    set port: settings.port || DEFAULT_PORT
    set traps: false
    set logging: true # Should be set to nil for production
    # set quiet: true # Should be set to true for production
    set bind: '0.0.0.0'
  end

  def initialize
    @blockchain = Blockchain.new
    @ip = "#{get_current_ip}:#{settings.port || DEFAULT_PORT}"
    @peers = register_node
    @wallet = Wallet.new

    super
  end

  get '/transactions' do
    content_type :json
    @blockchain.unprocessed_transactions.to_json
  end

  get '/chain' do
    content_type :json
    @blockchain.chain.to_json
  end

  get '/register_node' do
    @peers << params[:ip_with_port]
    @peers.uniq!

    return { nodes: @peers.reject{|node| node == @ip || node == params[:ip_with_port]} }.to_json
  end

  post '/transactions/new' do
    content_type :json
    Thread.new do
      transaction = {
        id: params[:id],
        sender: params[:sender],
        recipient: params[:recipient],
        amount: params[:amount],
        timestamp: params[:timestamp],
        signature: params[:signature]
      }
      broadcast_transaction(transaction, params[:broadcasted_to] || [])
      Thread.current.kill
    end

    return {status: 200}.to_json
  end

  def broadcast_transaction(transaction, broadcasted_to)
    if @blockchain.valid_transaction? transaction
      puts "Transaction Valid"
      broadcasting_to = @peers.reject{ |node| broadcasted_to.include? node }

      broadcasting_to.each do |peer|
        puts "Broadcasting transaction to peer at #{peer}"
        message_peer(
          peer,
          "/transactions/new",
          'POST',
          {
            id: transaction[:id],
            sender: transaction[:sender],
            recipient: transaction[:recipient],
            amount: transaction[:amount],
            signature: transaction[:signature],
            timestamp: transaction[:timestamp],
            broadcasted_to: broadcasted_to.concat(broadcasting_to) << @ip
          }
        )
      end
    end
  end

  # Net::HTTP will raise an error if the connection is refused. Let's assume a nil return value means the connection was unsuccessful
  def message_peer(peer, path, method, params = nil)
    ip,port = peer.strip.split(':')

    if method == 'GET'
      JSON.parse(Net::HTTP.get(ip, path, port)) rescue nil
    elsif method == 'POST' && params
      JSON.parse(Net::HTTP.new(ip, port).post(path, parameterize(params)).body) rescue nil
    end
  end

  def register_node
    # The nodes.txt file is pre-seeded with some known nodes ipv4 addesses.
    # We load the file and try to register our new node with the existing ones.
    # Once we succeed with registering with one node, we are done. This node will
    # provide us with the ipv4 addresses of other nodes that have connected to it
    peers = []
    File.open('./node/nodes.txt', 'r') do |known_hosts|
      response = nil
      known_hosts.each do |host|
        response = message_peer(host.strip, "/register_node?ip_with_port=#{@ip}", 'GET')
        peers << host.strip if response
        break if response
      end

      # If we were unable to connect to any of the nodes, start anyway
      # (this should almost never happen, except for the first node that is ever set up)
      peers.concat(response ? response['nodes'].uniq : [])
    end
  end

  def get_current_ip
    Net::HTTP.get(URI("http://api.ipify.org"))
  end

  private #================================================================

  def parameterize(params)
    # Transforms a hash to a parameter string
    # E.x. {a: 'something', b: 'otherthing'} => 'a=something&b=otherthing'
    URI.escape(params.collect{|k,v| "#{k}=#{v}"}.join('&'))
  end
end
