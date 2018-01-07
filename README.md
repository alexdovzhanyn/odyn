[![Packagist](https://img.shields.io/packagist/l/doctrine/orm.svg)]()

![Odyn Logo](https://ibin.co/3nLI0cTrzsSg.png)

# Odyn Blockchain
> A ruby implementation of proof-of-work blockchain technology

This project aims to be a reference & full-fledged cryptocurrency/blockchain written in ruby. Eventually it would also serve as a building block for applications aiming to build their
platform on a blockchain/distributed ledger technology.

## Development setup

Describe how to install all development dependencies and how to run an automated test-suite of some kind. Potentially do this for multiple platforms.

OS X & Linux:

1. Download this repository
2. Make sure you have ruby installed on your system
3. Run `bundle install`
4. Update the nodes.txt file in the node/ folder to have the external ip of your router, along with the port that you plan on running the nodes on. It is a good idea to use one 2, with the same IP, but with 2 different ports (9999 and 9998)
5. Forward ports 9999 and 9998 on your router (this allows you to connect to other nodes)
6. The entry to the blockchain is node/node.rb, run `ruby node/node.rb` to start the node

For use-case-specific setup instructions, see <https://github.com/alexdovzhanyn/odyn/wiki/Development>


## Release History

* 0.0.1
    * Begin setting up basic structure of

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
