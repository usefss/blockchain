// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
// import "hardhat/console.sol";

contract AuctionManager {
    struct ServerPriorityBlock {
        string name;
        uint64 cost;
    }

    struct MobilePriorityBlock {
        uint64 id;
        uint64 cost;
    }

    struct ServerNode {
        string name;

        uint64 mips;
        
        uint64 xCoordinate;
        uint64 yCoordinate;

        uint64 offer;
    }

    struct MobileTask {
        uint64 id;

        uint64 cpuLength;
        uint64 nwLength;
        uint64 outputSize;

        uint64 deadline;

        uint64 offer;

        uint64 ueUpBW;

        uint64 xCoordinate;
        uint64 yCoordinate;

        uint64 ueTransmissionPower;
        uint64 ueIdlePower;
    }

    struct TupleMappingMips {
        mapping(uint64 => uint64) tuples;
    }
    mapping(string => uint64) tempServerQuta;
    mapping(uint64 => string) tempTupleResult;

    string[] tempVisitedServers;
    uint64[] tempVisitedTuples;

    struct Auction {

        uint64[] assingedTuples;
        uint64[] mobileKeys;
        string[] serverKeys;
        mapping(uint64 => MobileTask) mobileTasks;
        mapping(uint64 => ServerPriorityBlock[]) mobilePriorities;

        mapping(string => ServerNode) serverNodes;
        mapping(string => MobilePriorityBlock[]) serverPriorities;
        mapping(string => uint64) serverQuta;
        
        mapping(string => TupleMappingMips) tupleRequireMips;
        
        mapping(uint64 => string) tupleResult;
        mapping(uint64 => bool) assingedTuplesMap;
        mapping(string => uint64) serverResult;
      
    }
    Auction activeAuction;
    // event AuctionTupleResult (
    //     string serverName
    // );
    // event MobileTaskRegistered(
    //     uint64 id,
    //     uint64 biddersCount
    // );

    // event ServerNodeRegistered(
    //     string name,
    //     uint64 biddersCount
    // );

    function registerMobileTask(
        uint64 id, uint64 cpuLength, uint64 nwLength, 
         uint64 outputSize,
        uint64 deadline, uint64 offer, uint64 ueUpBW, uint64 xCoordinate, uint64 yCoordinate,
        uint64 ueTransmissionPower, uint64 ueIdlePower
    ) public {
        activeAuction.mobileTasks[id] = MobileTask(
            id, cpuLength, nwLength, 
            outputSize, deadline,
            offer, ueUpBW, xCoordinate, yCoordinate, ueTransmissionPower,
            ueIdlePower
        );
        activeAuction.mobileKeys.push(id);
        // createTuplePriorities(activeAuction.mobileTasks[id]);
        // updateServerPriorities(activeAuction.mobileTasks[id]); NO
        // updateTupleRequireMips(activeAuction.mobileTasks[id]);  NO
        // emit MobileTaskRegistered(id, activeAuction.mobileKeys.length);
    }

    // function updateServerPriorities(uint64 id) public  {
    //     MobileTask memory tuple = activeAuction.mobileTasks[id];
    //     for (uint64 i = 0; i < activeAuction.serverKeys.length; i ++) {
    //         string memory serverName = activeAuction.serverKeys[i];
    //         MobilePriorityBlock memory newPriorityBlock = MobilePriorityBlock(
    //             tuple.id,
    //             serverCost(activeAuction.serverNodes[serverName], tuple)
    //         );
    //         addMobilePriorityBlockSorted(newPriorityBlock, serverName);
    //     }
    // }

    function createTuplePriorities(uint64 id) public {
        MobileTask memory tuple = activeAuction.mobileTasks[id];
        for (uint64 i = 0; i < activeAuction.serverKeys.length; i ++) {
            string memory serverName = activeAuction.serverKeys[i];
            ServerPriorityBlock memory newPriorityBlock = ServerPriorityBlock(
                serverName,
                tupleCost(tuple, activeAuction.serverNodes[serverName])
            );
            addServerPriorityBlockSorted(newPriorityBlock, tuple.id);
       }
    }

    function registerServerNode(
        string memory name, 
         uint64 mips,
        uint64 xCoordinate,
        uint64 yCoordinate , uint64 offer
    ) public {

        activeAuction.serverNodes[name] = ServerNode(
            name, mips,
            xCoordinate, yCoordinate, offer
        );
        activeAuction.serverKeys.push(name);
        // createServerPriorities(activeAuction.serverNodes[name]);
        activeAuction.serverQuta[name] = mips;
        // updateTuplePriorities(activeAuction.serverNodes[name]); NO
        // createTupleRequireMips(activeAuction.serverNodes[name]);
        // emit ServerNodeRegistered(name, activeAuction.serverKeys.length);
    }

    function createTupleRequireMips(string memory serverName) public {
        ServerNode memory server = activeAuction.serverNodes[serverName];
        for (uint64 i = 0; i < activeAuction.mobileKeys.length; i ++) {
            MobileTask memory tuple = activeAuction.mobileTasks[activeAuction.mobileKeys[i]];
            activeAuction.tupleRequireMips[server.name].tuples[tuple.id] = getTupleMipsOnServer(server, tuple);
        }
    }

    // function updateTupleRequireMips(uint64 id) public {
    //     MobileTask memory tuple = activeAuction.mobileTasks[id];
    //     for (uint64 i = 0; i < activeAuction.serverKeys.length; i ++) {
    //         ServerNode memory server = activeAuction.serverNodes[activeAuction.serverKeys[i]];
    //         activeAuction.tupleRequireMips[server.name].tuples[tuple.id] = getTupleMipsOnServer(server, tuple);
    //     }
    // }
    function log2(uint64 x) private pure returns (uint64 y){
        assembly {
            let arg := x
            x := sub(x,1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
            let m := mload(0x40)
            mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
            mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
            mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
            mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
            mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
            mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
            mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
            mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
            mstore(0x40, add(m, 0x100))
            let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let shift := 0x100000000000000000000000000000000000000000000000000000000000000
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m,sub(255,a))), shift)
            y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
        }  
    }
    function getTupleMipsOnServer(ServerNode memory server, MobileTask memory tuple) private pure returns (uint64) {
        int64 distplus6 = ((int64(tuple.xCoordinate) - int64(server.xCoordinate)) ** 2 
                        + (int64(tuple.yCoordinate) - int64(server.yCoordinate)) ** 2) ** 2;
        uint64 logvint = log2(uint64(1 + (500000000000 * int64(tuple.ueTransmissionPower)) / distplus6));
        uint64 t_ij_transmit = tuple.nwLength / (logvint * tuple.ueUpBW);
        uint64 mps = tuple.cpuLength / (tuple.deadline - t_ij_transmit);
        return mps;
    }

    function createServerPriorities(string memory serverName) public {
        ServerNode memory server = activeAuction.serverNodes[serverName];
        for (uint64 i = 0; i < activeAuction.mobileKeys.length; i++) {
            uint64 tupleID = activeAuction.mobileKeys[i];
            MobilePriorityBlock memory newPriorityBlock = MobilePriorityBlock(
                tupleID,
                serverCost(server, activeAuction.mobileTasks[tupleID])
            );
            addMobilePriorityBlockSorted(newPriorityBlock, server.name);
        }
    }

    function addMobilePriorityBlockSorted(MobilePriorityBlock memory priorityBlock, string memory serverName) private {
        // this must add priorityBlock to Auction.serverPriorities in a sorted way later
        // 900 800 700 200
        // 200
        activeAuction.serverPriorities[serverName].push(priorityBlock); // TODO
        if (activeAuction.serverPriorities[serverName].length == 1) {
            return;
        }
        uint64 i = 0;
        for (i; i < activeAuction.serverPriorities[serverName].length - 1; i ++ ) {
            if (!(priorityBlock.cost < activeAuction.serverPriorities[serverName][i].cost)) {
                break;
            }
        }
        for (uint256 j = activeAuction.serverPriorities[serverName].length - 1; j > i; j --) {
            activeAuction.serverPriorities[serverName][j] = activeAuction.serverPriorities[serverName][j - 1];
        }
        activeAuction.serverPriorities[serverName][i] = priorityBlock;
    }

    // function updateTuplePriorities(string memory serverName) public {
    //     ServerNode memory server = activeAuction.serverNodes[serverName];
    //     for (uint64 i = 0; i < activeAuction.mobileKeys.length; i ++) {
    //         uint64 tupleId = activeAuction.mobileKeys[i];
    //         ServerPriorityBlock memory newPriorityBlock = ServerPriorityBlock(
    //             server.name,
    //             tupleCost(activeAuction.mobileTasks[tupleId], server)
    //         );
    //         addServerPriorityBlockSorted(newPriorityBlock, tupleId);
    //     }
    // }
       function addServerPriorityBlockSorted(ServerPriorityBlock memory priorityBlock, uint64 tupleID) private {
        // this must add priorityBlock to Auction.serverPriorities in a sorted way later
        activeAuction.mobilePriorities[tupleID].push(priorityBlock); // TODO
        if (activeAuction.mobilePriorities[tupleID].length == 1) {
            return;
        }
        // 100 200 400
        uint64 i = 0;
        for (i; i < activeAuction.mobilePriorities[tupleID].length - 1; i ++ ) {
            if (priorityBlock.cost < activeAuction.mobilePriorities[tupleID][i].cost) {
                break;
            }
        }
        // 100 200 400 ?
        for (uint256 j = activeAuction.mobilePriorities[tupleID].length - 1; j > i; j --) {
            activeAuction.mobilePriorities[tupleID][j] = activeAuction.mobilePriorities[tupleID][j - 1];
        }
        activeAuction.mobilePriorities[tupleID][i] = priorityBlock;
    }
    function tupleCost(MobileTask memory tuple, ServerNode memory server) private pure returns (uint64) {
        int64 distplus6 = ((int64(tuple.xCoordinate) - int64(server.xCoordinate)) ** 2 
                                + (int64(tuple.yCoordinate) - int64(server.yCoordinate)) ** 2) ** 2;
        uint64 logvint = log2(uint64(1 + (500000000000 * int64(tuple.ueTransmissionPower)) / distplus6));
        uint64 t_ij_transmit = (1000000 * tuple.nwLength) / (logvint * tuple.ueUpBW);
       
        uint64 t_ij_process = (1000000 * tuple.cpuLength) / server.mips;
        uint64 t_ij_offload_norm = (t_ij_transmit + t_ij_process) / tuple.deadline;
        uint64 e_ij_offload_norm = (t_ij_transmit * tuple.ueTransmissionPower * 1000 
                            + t_ij_process * tuple.ueIdlePower) / 
                                        (tuple.deadline * (tuple.ueTransmissionPower * 1000 + tuple.ueIdlePower));
        uint64 pref = t_ij_offload_norm + e_ij_offload_norm + server.offer * 1000; // (server.offer/1000) * 1000000
        // sort 100 200 300 ...
        return pref;
    }
    function sqrt(uint64 x) private pure returns (uint64 y) {
        uint64 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    function serverCost(ServerNode memory server, MobileTask memory tuple) private pure returns (uint64) {

        int64 dist = ((int64(tuple.xCoordinate) - int64(server.xCoordinate)) ** 2 
                        + (int64(tuple.yCoordinate) - int64(server.yCoordinate)) ** 2);
        uint64 cost =  uint64(1000000 + tuple.offer * 1000 - 2357 * sqrt(uint64(dist)));
        return cost;
    }

    function auctionResultTuple(uint64 tupleID) public {

        if (activeAuction.assingedTuplesMap[tupleID] == false) {
            calcAuctionResult(tupleID);
        } else {
        }
        // emit AuctionTupleResult(activeAuction.tupleResult[tupleID]);
    }

    function calcAuctionResult(uint64 tupleID) private {
        uint64 initalTupleID = tupleID;
        for (uint64 i = 0; i < activeAuction.serverKeys.length; i ++) {
            tempServerQuta[activeAuction.serverKeys[i]] = activeAuction.serverQuta[activeAuction.serverKeys[i]];
        }
        while (true) {
            while (true) {
                bool tupleNotAssigned = true;
                bool foundCircle = false;
                string memory circleStartServer = "";
                for (uint64 i = 0; i < activeAuction.serverKeys.length; i ++) {
                    string memory serverName = activeAuction.mobilePriorities[tupleID][i].name;
                    uint64 tupleMips = activeAuction.tupleRequireMips[serverName].tuples[tupleID];
                    if (tupleMips <= tempServerQuta[serverName] && 
                        activeAuction.serverNodes[serverName].offer <= activeAuction.mobileTasks[tupleID].offer) { // servers does not exit the process at all!!! NOTE
                        tempServerQuta[serverName] = tempServerQuta[serverName] - tupleMips;
                        tempTupleResult[tupleID] = serverName;
                        tupleNotAssigned = false;
                        for (uint64 j = 0; j < activeAuction.mobileKeys.length; j ++) { // No calc on if server is able to handle
 
                            uint64 perfTupleID = activeAuction.serverPriorities[serverName][j].id;
                            if (activeAuction.assingedTuplesMap[perfTupleID] == false) {
                                activeAuction.serverResult[serverName] = perfTupleID;
                                break;
                            }
                        }
                        string memory serverRounding = serverName;
                        delete tempVisitedServers;
                        tempVisitedServers.push(serverRounding);
                        delete tempVisitedTuples;
                        while (true) {

                            if (activeAuction.serverResult[serverRounding] != 0) {
                                uint64 TupleRounding = activeAuction.serverResult[serverRounding];
                                for (uint64 ind1 = 0; ind1 < tempVisitedTuples.length; ind1 ++) {
                                    if (TupleRounding == tempVisitedTuples[ind1]) {
                                        foundCircle = true;
                                        circleStartServer = serverRounding;
                                        break;
                                    }
                                }
                                tempVisitedTuples.push(TupleRounding);

                                if (bytes(tempTupleResult[activeAuction.serverResult[serverRounding]]).length > 0) {
                                    serverRounding = tempTupleResult[activeAuction.serverResult[serverRounding]];
                                    for (uint64 ind1 = 0; ind1 < tempVisitedServers.length; ind1 ++) {
                                        if (keccak256(abi.encodePacked((serverRounding))) == keccak256(abi.encodePacked((tempVisitedServers[ind1])))) {
                                            foundCircle = true;
                                            circleStartServer = serverRounding;
                                            break;
                                        }
                                    }
                                    if (foundCircle) break;
                                    tempVisitedServers.push(serverRounding);
                                } else break;
                            } else break;
                        }
                        break;
                    }
                }
                if (foundCircle) {

                    uint64 tupleRoundingID = activeAuction.serverResult[circleStartServer];
                    while (true) {
                        activeAuction.tupleResult[tupleRoundingID] = tempTupleResult[tupleRoundingID];
                        activeAuction.assingedTuples.push(tupleRoundingID);
                        activeAuction.assingedTuplesMap[tupleRoundingID] = true;
                        uint64 tupleMips = activeAuction.tupleRequireMips[tempTupleResult[tupleRoundingID]].tuples[tupleID];
                        activeAuction.serverQuta[tempTupleResult[tupleRoundingID]] = activeAuction.serverQuta[tempTupleResult[tupleRoundingID]] - tupleMips;
                        if (keccak256(abi.encodePacked((tempTupleResult[tupleRoundingID]))) == keccak256(abi.encodePacked((circleStartServer)))) {
                            break;
                        }
                        tupleRoundingID = activeAuction.serverResult[tempTupleResult[tupleRoundingID]];
                    }
                    break;
                }
                if (tupleNotAssigned) {
                    activeAuction.assingedTuples.push(tupleID);
                    activeAuction.assingedTuplesMap[tupleID] = true;
                    activeAuction.tupleResult[tupleID] = "NOTFOUND";
                    break;
                }
                tupleID = activeAuction.serverResult[tempTupleResult[tupleID]];
            }
            if (activeAuction.assingedTuplesMap[initalTupleID]) {
                break;
            } else {
                tupleID = initalTupleID;
            }
        }
    }

}
