// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Ttc {
    //TODO: use IteratableMap as library instead of adhoc implementation
    struct Tuple {
        uint256 value;
        uint256 ratio;
        uint256 mips;
        uint256 index;
    }

    struct Server {
        uint256 value;
        uint256 ratio;
        uint256 capacity;
        uint256 index;
    }

    mapping(address => Server) public toServer;
    mapping(address => Tuple) public toTuple;

    Tuple[] public tuples;
    Server[] public servers;

    //FIXME: size of arrays
    uint256[10][10] public serversPoints;
    uint256[10][10] public tuplesPoints;

    error BidValueOrRatioIsZero();

    function bidTuple(
        uint256 value,
        uint256 ratio,
        uint256 mips
    ) external {
        Tuple memory tuple = toTuple[msg.sender];
        if (tuple.value == 0 || tuple.ratio == 0) {
            if (value == 0 || ratio == 0) {
                revert BidValueOrRatioIsZero();
            }
            tuple = Tuple(value, ratio, mips, tuples.length);
            toTuple[msg.sender] = tuple;
            tuples.push(tuple);
        }

        //FIXME: check points array axis
        for (uint256 j = 0; j < servers.length; j++) {
            tuplesPoints[j][tuple.index] = tuple.value * servers[j].ratio;
        }

        for (uint256 j = 0; j < servers.length; j++) {
            serversPoints[tuple.index][j] = tuple.ratio * servers[j].value;
        }
    }

    function bidServer(
        uint256 value,
        uint256 ratio,
        uint256 capacity
    ) external {
        Server memory server = toServer[msg.sender];
        if (server.value == 0 || server.ratio == 0) {
            if (value == 0 || ratio == 0) {
                revert BidValueOrRatioIsZero();
            }
            server = Server(value, ratio, capacity, servers.length);
            toServer[msg.sender] = server;
            servers.push(server);
        }

        //FIXME: check points array axis
        for (uint256 j = 0; j < tuples.length; j++) {
            serversPoints[j][server.index] = server.value * tuples[j].ratio;
        }

        for (uint256 j = 0; j < tuples.length; j++) {
            tuplesPoints[server.index][j] = server.ratio * tuples[j].value;
        }
    }
}
