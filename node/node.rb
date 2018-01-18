require_relative '../config/initializer.rb'

class Odyn < Sinatra::Base
  attr_accessor :blockchain

  CONFIG = Config.settings[:node]

  configure do
    set server: "thin"
    set port: settings.port || CONFIG['default_port']
    set traps: false
    set logging: CONFIG['logging']
    set quiet: CONFIG['quiet']
    set bind: CONFIG['internal_ip']
  end

  def initialize
    @blockchain = Blockchain.new
    @ip = "#{get_current_ip}:#{settings.port || CONFIG['default_port']}"
    @blockchain.add_observer(self, :broadcast_block) # Using the observer pattern, subscribe to updates from the chain
    @peers = register_node
    @wallet = Wallet.new
    super
  end

  get '/transactions' do
    content_type :json
    @blockchain.transaction_pool.to_json
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
    async do
      broadcast_transaction(params[:transaction], params[:broadcasted_to] || [])
    end

    return {status: 200}.to_json
  end

  post '/block/new' do
    content_type :json
    async do
      broadcast_block(params[:block], params[:broadcasted_to] || [])
    end

    return {status: 200}.to_json
  end

  def broadcast_transaction(transaction, broadcasted_to)
    transaction_object = YAML::load(Base64.decode64(transaction))
    broadcasted_to = JSON.parse(broadcasted_to) if broadcasted_to.instance_of? String

    if Validator.valid_transaction?(transaction_object, @blockchain.ledger)
      @blockchain.transaction_pool << transaction_object
      broadcasting_to = @peers.reject{ |node| broadcasted_to.include? node }

      broadcasting_to.each do |peer|
        puts "Broadcasting transaction to peer at #{peer}"
        message_peer(
          peer,
          "/transactions/new",
          'POST',
          {
            transaction: transaction,
            broadcasted_to: broadcasted_to.concat(broadcasting_to) << @ip
          }
        )
      end
    end
  end

  def broadcast_block(block, broadcasted_to = [])
    deserialized_block = YAML::load(Base64.decode64(block))
    broadcasted_to = JSON.parse(broadcasted_to) if broadcasted_to.instance_of? String

    if Validator.valid_block?(deserialized_block, @blockchain.ledger)
      @blockchain.append_verified_block(deserialized_block)
      @blockchain.update_utxo_pool(deserialized_block)

      broadcasting_to = @peers.reject{ |node| broadcasted_to.include? node }

      broadcasting_to.each do |peer|
        puts "\e[32mBroadcasting transaction to peer at #{peer}\e[0m"
        message_peer(
          peer,
          "/block/new",
          'POST',
          {
            block: block,
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
    # Internal is only used when developing/testing with multiple nodes on the same
    # machine. This removes the need for port forwarding.
    if CONFIG['network_type'] == 'internal'
      CONFIG['internal_ip']
    else
      Net::HTTP.get(URI("http://api.ipify.org"))
    end
  end

  private #================================================================

  def parameterize(params)
    # Transforms a hash to a parameter string
    # E.x. {a: 'something', b: 'otherthing'} => 'a=something&b=otherthing'
    URI.escape(params.collect{|k,v| "#{k}=#{v}"}.join('&'))
  end
end
