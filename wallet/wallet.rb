require_relative '../config/initializer.rb'

class Wallet
  attr_reader :keypair, :public_key_hex

  def initialize
    Dir.mkdir('wallet/keys') unless Dir.exist?('wallet/keys')
    # Load an existing keypair or create one if none exist
    @keypair = load_ecdsa_keypair || generate_ecdsa_keypair
    @public_key_hex = @keypair.public_key.to_bn.to_s(16).downcase
    @ledger = Ledger.new
    @broadcaster_node = find_broadcaster_node
  end

  def transact(address, amount, mining_fee)
    usable_utxos = find_owned_utxos.sort{|a, z| a[:amount] <=> z[:amount]}

    inputs = []
    index = 0
    until inputs.reduce(0) { |sum, input| sum + input[:amount] } >= amount + mining_fee
      utxo = usable_utxos[index]
      utxo[:signature] = authorize_utxo(utxo[:txoid])
      inputs << utxo
    end

    change = inputs.reduce(0) { |sum, input| sum + input[:amount] } - amount - mining_fee

    designations = [
      {address: address, amount: amount},
      {address: public_key_hex, amount: change}
    ]

    tx = Base64.encode64(YAML::dump(Transaction.new(designations, inputs)))

    broadcast_ip, broadcast_port = @broadcaster_node.split(':')
    Net::HTTP.new(broadcast_ip, broadcast_port).post("/transactions/new", parameterize({transaction: tx})).body
  end

  def usable_balance
    find_owned_utxos.reduce(0) { |sum, input| sum + input[:amount] }
  end

  private #===============================================================

  def find_owned_utxos
    @ledger.all_utxos.select {|utxo| utxo[:address] == @public_key_hex}
  end

  def authorize_utxo(txoid)
    Base64.encode64(@keypair.dsa_sign_asn1(txoid)).gsub("\n", "")
  end

  def load_ecdsa_keypair
    unless Dir.entries("wallet/keys").include? "odyn_private.pem"
      return false
    end

    OpenSSL::PKey::EC.new(File.read("wallet/keys/odyn_private.pem"))
  end

  def generate_ecdsa_keypair
    keypair = OpenSSL::PKey::EC.new("secp256k1").generate_key

    open('wallet/keys/odyn_private.pem', 'w') do |private_key_file|
      private_key_file.write keypair.to_pem
    end

    return keypair
  end

  def find_broadcaster_node
    File.open('./node/nodes.txt', 'r') do |known_hosts|
      peers = []
      response = nil
      known_hosts.each do |host|
        ip, port = host.strip.split(':')
        response = JSON.parse(Net::HTTP.get(ip, '/nodes', port)) rescue nil
        peers << host.strip if response
        break if response
      end

      peers.concat(response['nodes'] || []).sample if response
    end
  end
end
