require 'openssl'
require 'base64'
require 'pry'

class Wallet
  attr_reader :keypair, :public_key_hex

  def initialize
    # Load an existing keypair or create one if none exist
    @keypair = load_ecdsa_keypair || generate_ecdsa_keypair
    @public_key_hex = @keypair.public_key.to_bn.to_s(16).downcase
  end

  def authorize_utxo(txoid)
    Base64.encode64(@keypair.dsa_sign_asn1(txoid)).gsub("\n", "")
  end

  private #===============================================================

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

end
