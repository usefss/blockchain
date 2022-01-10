#! /bin/bash
solcjs contracts/AuctionManager.sol --bin --abi --optimize -o output/
mv output/contracts_AuctionManager_sol_AuctionManager.abi output/AuctionManager.abi
mv output/contracts_AuctionManager_sol_AuctionManager.bin output/AuctionManager.bin