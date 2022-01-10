# Startup the blockchain and deploy smart contract on develop blockchain

*  First setup the ganache local blockchain
``` 
npm install -g ganache

npm run ganache
```

* Or use hardhat node for debugging
```
npx hardhat node
```


* Setup truffle
```
npm install -g truffle

truffle compile

truffle migrate --reset

```
If you have problems with solidity compiler version for truffle, you can checkout [this](https://ethereum.stackexchange.com/questions/17551/how-to-upgrade-solidity-compiler-in-truffle/47244). 

* abi and bin
Generate abi and bin off contract with gen_bin.sh.

* Testing
```
truffle test
```

* Notes
Do not send tuple with id of 0, or server with name of ""