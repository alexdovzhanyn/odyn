class WalletCli
  def initialize(blockchain)
    @title = "Odyn Core Wallet v0.0.1-alpha"
    @wallet = Wallet.new
    @blockchain = blockchain

    system("printf \"\033]0;#{@title}\007\"")
    puts "\e[32m#{@title}\e[0m"
    puts "Type 'help' for a list of commands.\n\n"

    run_wallet
  end

  def handle_command(command)
    case command
    when 'create transaction' then create_transaction
    when 'new keypair' then new_keypair
    when 'public keys' then public_keys
    when 'balance' then balance
    when 'help' then help
    when 'exit' then exit(0)
    else puts "Invalid command -- #{command}. Type 'help' for a list of commands."
    end

    puts "\n"
  end

  private

  def run_wallet
    loop do
      block_to_discard_at = @wallet.discard_at_which_block?(@wallet.primary_key_hex)
      if @blockchain.chain.last.index >= block_to_discard_at
        puts 'Rotating Keys...'
        @wallet.rotate_keys
      end
      print '> '

      command = gets.chomp.strip
      puts "\n"
      handle_command(command)
    end
  end

  def create_transaction
    balance

    print "Transaction amount: "
    amount = gets.chomp.strip.to_f

    until amount.is_a?(Numeric) && amount > 0
      puts "\e[31mInvalid transaction amount. Enter a number greater than 0\e[0m"
      print "Transaction amount: "
      amount = gets.chomp.strip.to_f
    end

    print "Recieving address: "
    address = gets.chomp.strip

    print "Mining fee: "
    fee = gets.chomp.strip.to_f

    print "Are you sure you want to send #{amount} to #{address}? (Total transaction cost: #{amount + fee}) [yN]: "
    confirm = gets.chomp.strip

    if confirm != 'y' && confirm != 'yes'
      puts "Transaction cancelled"
      return
    end

    puts "Creating transaction..."
    @wallet.transact(address, amount, fee)
  end

  def new_keypair
    @wallet.rotate_keys
    puts "New Primary Key: \e[32m#{@wallet.primary_key_hex}\e[0m"
    @wallet.keyring.each do |k, v|
      puts "Scheduled to discard: \e[31m#{k}\e[0m" unless k == @wallet.primary_key_hex
    end
  end

  def public_keys
    puts "Primary Key: \e[32m#{@wallet.primary_key_hex}\e[0m"
    @wallet.keyring.each do |k, v|
      puts "Scheduled to discard: \e[31m#{k}\e[0m" unless k == @wallet.primary_key_hex
    end
  end

  def balance
    puts "Total Odyn across all keys: #{@wallet.usable_balance}"
  end

  def help
    puts "COMMAND\t\t\tDESCRIPTION"
    puts "create transaction\tBegin creating a new transaction"
    puts "new keypair\t\tGenerate a new keypair (and discard any expired keys)"
    puts "public keys\t\tList public keys within wallet"
    puts "balance\t\t\tList wallet balance"
    puts "help\t\t\tShow this help screen"
    puts "exit\t\t\tExit the program"
  end
end
