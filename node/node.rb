require 'sinatra/base'
require 'sinatra/json'
require 'thin'
require 'json'
require 'pry'
require 'httparty'

require_relative '../lib/blockchain.rb'

class Odyn < Sinatra::Base
  attr_accessor :transactions

  configure do
    set server: "thin"
    set port: 9998
    set traps: false
    set logging: true
    # set quiet: true
    set bind: '0.0.0.0'
  end

  def initialize
    @blockchain = Blockchain.new
    @peers = register_node

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
    @peers << request.ip
    @peers = @peers.uniq

    return { nodes: @peers }.to_json
  end

  post '/transactions/new' do
    content_type :json
    Thread.new do
      broadcast_transaction(params[:sender], params[:recipient], params[:amount])
      Thread.current.kill
    end

    return {status: 200}.to_json
  end

  def broadcast_transaction(sender, recipient, amount)
    @peers.each do |peer|
      puts "Broadcasting transaction to peer at #{peer}"
      message_peer(peer, "/transactions/new", 'POST', { sender: sender, recipient: recipient, amount: amount})
    end
  end

  # Net::HTTP will raise an error if the connection is refused. Let's assume a nil return value means the connection was unsuccessful
  def message_peer(peer, path, method, params = nil)
    if method == 'GET'
      JSON.parse(Net::HTTP.get(peer.strip, path, 9999) ) rescue nil
    elsif method == 'POST' && params
      JSON.parse(Net::HTTP.new(peer.strip, 9999).post(path, params.to_json).body) rescue nil
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
        response = message_peer(host, "/register_node", 'GET')
        peers << host if response
        break if response
      end

      # If we were unable to connect to any of the nodes, start anyway
      # (this should almost never happen, except for the first node that is ever set up)
      peers.concat(response ? response['nodes'] : [])
    end
  end
end

Odyn.run!
