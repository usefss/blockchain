// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

//TODO: use DDD names
contract Ttc {
    //TODO: use IteratableMap as library instead of adhoc implementation
    struct Buyer {
        uint256 value;
        uint256 ratio;
        uint256 index;
    }

    struct Seller {
        uint256 value;
        uint256 ratio;
        uint256 index;
    }

    mapping(address => Seller) public toSeller;
    mapping(address => Buyer) public toBuyer;

    Buyer[] public buyers;
    Seller[] public sellers;

    //FIXME: size of arrays
    uint256[10][10] public sellersPoints;
    uint256[10][10] public buyersPoints;

    error BidValueOrRatioIsZero();

    function bidBuyer(uint256 value, uint256 ratio) external {
        Buyer memory buyer = toBuyer[msg.sender];
        if (buyer.value == 0 || buyer.ratio == 0) {
            if (value == 0 || ratio == 0) {
                revert BidValueOrRatioIsZero();
            }
            buyer = Buyer(value, ratio, buyers.length);
            toBuyer[msg.sender] = buyer;
            buyers.push(buyer);
        }

        //FIXME: check points array axis
        for (uint256 j = 0; j < sellers.length; j++) {
            buyersPoints[j][buyer.index] = buyer.value * sellers[j].ratio;
        }

        for (uint256 j = 0; j < sellers.length; j++) {
            sellersPoints[buyer.index][j] = buyer.ratio * sellers[j].value;
        }
    }

    function bidSeller(uint256 value, uint256 ratio) external {
        Seller memory seller = toSeller[msg.sender];
        if (seller.value == 0 || seller.ratio == 0) {
            if (value == 0 || ratio == 0) {
                revert BidValueOrRatioIsZero();
            }
            seller = Seller(value, ratio, sellers.length);
            toSeller[msg.sender] = seller;
            sellers.push(seller);
        }

        //FIXME: check points array axis
        for (uint256 j = 0; j < buyers.length; j++) {
            sellersPoints[j][seller.index] = seller.value * buyers[j].ratio;
        }

        for (uint256 j = 0; j < buyers.length; j++) {
            buyersPoints[seller.index][j] = seller.ratio * buyers[j].value;
        }
    }
}
