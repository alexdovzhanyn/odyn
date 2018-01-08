require 'sinatra/base'
require 'sinatra/json'
require 'thin'
require 'json'
require 'pry'
require 'httparty'

require_relative '../lib/blockchain.rb'

class Odyn < Sinatra::Base
  attr_accessor :transactions

  DEFAULT_PORT = 9999
  @port = DEFAULT_PORT
  
  configure do
    set server: "thin"
    set port: @port
    set traps: false
    set logging: true # Should be set to nil for production
    # set quiet: true # Should be set to true for production
    set bind: '0.0.0.0'
  end

  def initialize
    @blockchain = Blockchain.new
    @ip = "#{get_current_ip}:#{@port}"
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
    @peers << params[:ip_with_port]
    @peers.uniq!

    return { nodes: @peers.reject{|node| node == @ip || node == params[:ip_with_port]} }.to_json
  end

  post '/transactions/new' do
    content_type :json
    Thread.new do
      broadcast_transaction(params[:sender], params[:recipient], params[:amount], params[:broadcasted_to] || [])
      Thread.current.kill
    end

    return {status: 200}.to_json
  end

  def broadcast_transaction(sender, recipient, amount, broadcasted_to)
    broadcasting_to = @peers.reject{ |node| broadcasted_to.include? node }

    broadcasting_to.each do |peer|
      puts "Broadcasting transaction to peer at #{peer}"
      message_peer(
        peer,
        "/transactions/new",
        'POST',
        {
          sender: sender,
          recipient: recipient,
          amount: amount,
          broadcasted_to: broadcasted_to.concat(broadcasting_to) << @ip
        }
      )
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
      peers.concat(response ? response['nodes'] : [])
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