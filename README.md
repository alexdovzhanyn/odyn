[![Packagist](https://img.shields.io/badge/license-MIT-blue.svg)]()

# Odyn Blockchain
> A proof-of-work, anonymous blockchain written in ruby

This project aims to be a reference & full-fledged cryptocurrency/blockchain written in ruby. Eventually it would also serve as a building block for applications aiming to build their
platform on a blockchain/distributed ledger technology.

## Setup
For use-case-specific setup instructions, see <https://github.com/alexdovzhanyn/odyn/wiki/Development>. If you need further help or want to find out how to contribute,
join the [Gitter Channel](https://gitter.im/odyn-crypto/Lobby) and ask!

### OS X & Linux:

1. Download this repository
2. Make sure you have ruby 2.4.2 or higher installed on your system
3. Run `bundle install`
4. Update the nodes.txt file in the node/ folder to have the external ip of your router, along with the port that you plan on running the nodes on. It is a good idea to use one 2, with the same IP, but with 2 different ports (9999 and 9998)
5. Forward ports 9999 and 9998 on your router (this allows you to connect to other nodes)
6. Run `thor node_launcher:port PORT_NUMBER` to start the node

## Mining
After following the setup instructions above, you should be ready to start mining. Before you start, visit the [wallet section](#wallet) and generate an address. Once you have an
address, copy the **public key** into the config/miner.yml file, where there is a setting for the wallet address. After doing this, make sure to **forward port 3333 on your router**.
If you don't forward the port, your miner won't be able to connect to the Odyn network. After forwarding the appropriate ports, you can run the miner by running `ruby miner/miner.rb`.

When running the miner, it will catch up to the network by fetching blocks that have been mined in the past. This may take a while depending on how many blocks have been mined.
After the miner finds all blocks that are existing, it will begin mining, and you'll see the hashrate outputted in the terminal, along with other diagnostic/informational data.

## Wallet
The wallet allows you to interact with the odyn network from your command line. After following the [setup instructions](#setup) above, you'll be able to create your own wallet
address and start sending transactions or mining. The wallet is a full node, meaning it stores the entire blockchain locally and validates each block and transaction. This is the most
secure way to interact with the network, as you needn't have any trust in anyone else. There are currently no other implementations of the wallet, but if you'd like to create one
that interacts with the network, you're more than welcome to. In order to get the wallet to properly run and communicate with the network, you must **forward port 8998 on your router**.

Once you've forwarded the necessary ports, you'll be able to start up your wallet. In order to start the wallet, go to the root directory of the project and run `ruby
wallet/wallet_node.rb`. This will cause the wallet to connect to a node in the network and attempt to fetch blocks that have already been mined, in effort to catch up. Depending on
the amount of blocks that have been mined by the time you set up your wallet, it can take a while to catch up. The wallet will output a status indicating how many blocks behind you
are, along with which block it is fetching.

After fetching all the blocks, your wallet will be ready to take input from you. You can view the commands available by typing `help` into the console provided for you. Upon startup,
the wallet will generate a private key for you, which will be located in the wallet/keys directory. Each keyfile name is labeled by their _public key address_. The wallet features a
security mechanism which causes it to discard keys that are older than roughly 24 hours. This is to protect transactions from being tracked based on one of your keys. The way this
works is that 720 blocks from when a key is generated, the key will be scheduled for deletion. **If the key has any balance left tied to it, it will not be deleted.** This way miners
are able to mine to the same address, without needing to switch keys every 720 blocks.

## Release History

* 0.0.1 Alpha
    * Blockchain operational
    * Peer-to-peer communication implemented
    * Mining to a wallet is possible
    * Wallets created
    * Transactions can be created and stored within the Blockchain
    * Nodes verify blocks and transactions as they come in
    * Implemented wallet key rotation algorithm v1 (ensures anonymity and non-trackability within the blockchain)
    * Nodes can catch up with blocks they've missed while offline
    * TODO: Handle forking. Forks will cause permanently different chains in the current release

## Meta

Like the project? Buy us some coffee!

Bitcoin: 1Lqw6hcM3qsEqMp3eQvLeohHxd796yfGj4

Ethereum: 0x81bb057f535b4ba77c95cdbbbf715cfddd605269

Distributed under the MIT license. See ``LICENSE`` for more information.

## Contributing

1. Fork it (<https://github.com/alexdovzhanyn/odyn/fork>)
2. Create your feature branch (`git checkout -b feature/master`)
3. Commit your changes (`git commit -am 'Add some fooBar'`)
4. Push to the branch (`git push origin feature/master`)
5. Create a new Pull Request
