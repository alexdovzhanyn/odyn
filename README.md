[![Packagist](https://img.shields.io/badge/license-MIT-blue.svg)]()

# Odyn Blockchain
> A proof-of-work, anonymous blockchain written in ruby

This project aims to be a reference & full-fledged cryptocurrency/blockchain written in ruby. Eventually it would also serve as a building block for applications aiming to build their
platform on a blockchain/distributed ledger technology.

## Development setup
For use-case-specific setup instructions, see <https://github.com/alexdovzhanyn/odyn/wiki/Development>. If you need further help or want to find out how to contribute,
join the [Gitter Channel](https://gitter.im/odyn-crypto/Lobby) and ask!

### OS X & Linux:

1. Download this repository
2. Make sure you have ruby 2.4.2 or higher installed on your system
3. Run `bundle install`
4. Update the nodes.txt file in the node/ folder to have the external ip of your router, along with the port that you plan on running the nodes on. It is a good idea to use one 2, with the same IP, but with 2 different ports (9999 and 9998)
5. Forward ports 9999 and 9998 on your router (this allows you to connect to other nodes)
6. Run `thor node_launcher:port PORT_NUMBER` to start the node


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
