require_relative '../config/initializer.rb'

class Wallet
  attr_reader :keyring, :primary_key_hex

  def initialize
    Dir.mkdir('wallet/keys') unless Dir.exist?('wallet/keys')
    @keydata = PStore.new('wallet/keys/keydat.pstore')
    @ledger = Ledger.new
    # Load an existing keypair or create one if none exist
    @keyring = load_ecdsa_keypair || generate_ecdsa_keypair
    get_latest_key

    @broadcaster_node = find_broadcaster_node
  end

  def transact(address, amount, mining_fee)
    if usable_balance < amount + mining_fee
      puts "\e[31mTransaction amount exceeds wallet balance\e[0m"
      return
    end

    usable_utxos = find_owned_utxos.sort{|a, z| a[:amount] <=> z[:amount]}

    inputs = []
    index = 0
    until inputs.reduce(0) { |sum, input| sum + input[:amount] } >= amount + mining_fee
      utxo = usable_utxos[index]
      utxo[:signature] = authorize_utxo(utxo)
      inputs << utxo
      index += 1
    end

    change = inputs.reduce(0) { |sum, input| sum + input[:amount] } - amount - mining_fee

    designations = [{address: address, amount: amount}]

    designations << {address: primary_key_hex, amount: change} if change > 0

    tx = Base64.encode64(YAML::dump(Transaction.new(designations, inputs)))

    if @broadcaster_node
      broadcast_ip, broadcast_port = @broadcaster_node.split(':')
      JSON.parse(Net::HTTP.new(broadcast_ip, broadcast_port).post("/transactions/new", parameterize({transaction: tx})).body)
    end
  end

  def usable_balance
    find_owned_utxos.reduce(0) { |sum, input| sum + input[:amount] }
  end

  def rotate_keys
    keyring.keys.each do |key|
      if !find_utxos_for_pubkey(key).any?
        discard_ecdsa_keypair(key)
      end
    end

    @keyring = @keyring.merge(generate_ecdsa_keypair)
    get_latest_key
  end

  def discard_at_which_block?(pubkey)
    @keydata.transaction do
      @keydata[pubkey][:block_created] + 2
    end
  end

  private #===============================================================

  def find_owned_utxos
    @ledger.all_utxos.select {|utxo| @keyring.keys.include? utxo[:address]}
  end

  def find_utxos_for_pubkey(key)
    @ledger.all_utxos.select {|utxo| utxo[:address] == key}
  end

  def authorize_utxo(utxo)
    Base64.encode64(@keyring[utxo[:address]].dsa_sign_asn1(utxo[:txoid])).gsub("\n", "")
  end

  def load_ecdsa_keypair
    return false if Dir.empty?('wallet/keys')

    key_arr = Dir['wallet/keys/*.pem'].map do |key|
      key_from_file = OpenSSL::PKey::EC.new(File.read(key))
      { key_from_file.public_key.to_bn.to_s(16).downcase =>  key_from_file }
    end

    key_arr.reduce({}, :merge)
  end

  def generate_ecdsa_keypair
    key= OpenSSL::PKey::EC.new("secp256k1").generate_key

    open("wallet/keys/#{hex_public_key(key)}.pem", 'w') do |private_key_file|
      private_key_file.write key.to_pem
    end

    generate_key_data(key)

    return { hex_public_key(key) => key }
  end

  def discard_ecdsa_keypair(pubkey)
    @keydata.transaction do
      @keydata.delete pubkey
      File.delete("wallet/keys/#{pubkey}.pem")
      @keyring.delete pubkey
      @keydata.commit
    end
  end

  def generate_key_data(key)
    @keydata.transaction do
      @keydata[hex_public_key(key)] = {block_created: @ledger.latest_blocks(1).last.index}
      @keydata.commit
    end
  end

  def get_latest_key
    @keydata.transaction do
      @primary_key_hex = @keydata.roots.max{|k| @keydata[k][:block_created]}
    end
  end

  def hex_public_key(key)
    key.public_key.to_bn.to_s(16).downcase
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
