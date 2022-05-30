// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
// import "hardhat/console.sol";

contract AuctionManager {
    struct ServerPriorityBlock {
        string name;
        uint cost;
    }

    struct MobilePriorityBlock {
        uint id;
        uint cost;
    }

    struct ServerNode {
        string name;

        // uint busyPower; // float
        // uint downBw;
        // uint idlePower; // float
        // uint level;
        uint mips;
        // uint ram;
        // uint ratePerMips; // float
        // uint upLinkLatency;
        // uint areaId;
        // uint joinDelay;
        
        uint xCoordinate;
        uint yCoordinate;

        uint offer;
    }

    struct MobileTask {
        uint id;

        uint cpuLength;
        uint nwLength;
        // uint pesNumber;
        uint outputSize;

        uint deadline;

        uint offer;

        uint ueUpBW;

        uint xCoordinate;
        uint yCoordinate;

        uint ueTransmissionPower;
        uint ueIdlePower;
    }

    struct TupleMappingMips {
        mapping(uint => uint) tuples;
    }
    mapping(string => uint) tempServerQuta;
    mapping(uint => string) tempTupleResult;

    string[] tempVisitedServers;
    uint[] tempVisitedTuples;

    struct Auction {

        uint[] assingedTuples;
        uint[] mobileKeys;
        string[] serverKeys;
        mapping(uint => MobileTask) mobileTasks;
        mapping(uint => ServerPriorityBlock[]) mobilePriorities;

        mapping(string => ServerNode) serverNodes;
        mapping(string => MobilePriorityBlock[]) serverPriorities;
        mapping(string => uint) serverQuta;
        
        mapping(string => TupleMappingMips) tupleRequireMips;
        
        mapping(uint => string) tupleResult;
        mapping(uint => bool) assingedTuplesMap;
        mapping(string => uint) serverResult;
      
    }
    Auction activeAuction;
    event AuctionTupleResult (
        string serverName
    );
    event MobileTaskRegistered(
        uint id,
        uint biddersCount
    );

    event ServerNodeRegistered(
        string name,
        uint biddersCount
    );

    function registerMobileTask(
        uint id, uint cpuLength, uint nwLength, 
         uint outputSize,
        uint deadline, uint offer, uint ueUpBW, uint xCoordinate, uint yCoordinate,
        uint ueTransmissionPower, uint ueIdlePower
    ) public {
        activeAuction.mobileTasks[id] = MobileTask(
            id, cpuLength, nwLength, 
            outputSize, deadline,
            offer, ueUpBW, xCoordinate, yCoordinate, ueTransmissionPower,
            ueIdlePower
        );
        activeAuction.mobileKeys.push(id);
        // createTuplePriorities(activeAuction.mobileTasks[id]);
        // updateServerPriorities(activeAuction.mobileTasks[id]);
        // updateTupleRequireMips(activeAuction.mobileTasks[id]);
        // emit MobileTaskRegistered(id, activeAuction.mobileKeys.length);
    }

    function updateServerPriorities(uint id) public  {
        MobileTask memory tuple = activeAuction.mobileTasks[id];
        for (uint i = 0; i < activeAuction.serverKeys.length; i ++) {
            string memory serverName = activeAuction.serverKeys[i];
            MobilePriorityBlock memory newPriorityBlock = MobilePriorityBlock(
                tuple.id,
                serverCost(activeAuction.serverNodes[serverName], tuple)
            );
            addMobilePriorityBlockSorted(newPriorityBlock, serverName);
        }
    }

    function createTuplePriorities(uint id) public {
        MobileTask memory tuple = activeAuction.mobileTasks[id];
        for (uint i = 0; i < activeAuction.serverKeys.length; i ++) {
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
        // uint busyPower, // float
        // uint downBw, uint idlePower, // float
        // uint level,
         uint mips,
        //   uint ram,
        // uint ratePerMips, // float
        // uint upLinkLatency,
        //  uint areaId
        // uint joinDelay,
        uint xCoordinate,
        uint yCoordinate , uint offer
    ) public {

        activeAuction.serverNodes[name] = ServerNode(
            name,
            //  0, 0, 0, 0,
            mips,
            //  0, 0, 0, 0,
            // 0,
             xCoordinate, yCoordinate, offer
        );
        activeAuction.serverKeys.push(name);
        // createServerPriorities(activeAuction.serverNodes[name]);
        activeAuction.serverQuta[name] = mips;
        // updateTuplePriorities(activeAuction.serverNodes[name]);
        // createTupleRequireMips(activeAuction.serverNodes[name]);
        emit ServerNodeRegistered(name, activeAuction.serverKeys.length);
    }

    function createTupleRequireMips(ServerNode memory server) private {
        for (uint i = 0; i < activeAuction.mobileKeys.length; i ++) {
            MobileTask memory tuple = activeAuction.mobileTasks[activeAuction.mobileKeys[i]];
            activeAuction.tupleRequireMips[server.name].tuples[tuple.id] = getTupleMipsOnServer(server, tuple);
        }
    }

    function updateTupleRequireMips(uint id) public {
        MobileTask memory tuple = activeAuction.mobileTasks[id];
        for (uint i = 0; i < activeAuction.serverKeys.length; i ++) {
            ServerNode memory server = activeAuction.serverNodes[activeAuction.serverKeys[i]];
            activeAuction.tupleRequireMips[server.name].tuples[tuple.id] = getTupleMipsOnServer(server, tuple);
        }
    }
    function log2(uint x) private pure returns (uint y){
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
    function getTupleMipsOnServer(ServerNode memory server, MobileTask memory tuple) private pure returns (uint) {
        int distplus6 = ((int256(tuple.xCoordinate) - int256(server.xCoordinate)) ** 2 
                        + (int256(tuple.yCoordinate) - int256(server.yCoordinate)) ** 2) ** 2;
        uint logvint = log2(uint(1 + (500000000000 * int256(tuple.ueTransmissionPower)) / distplus6));
        uint t_ij_transmit = tuple.nwLength / (logvint * tuple.ueUpBW);
        uint mps = tuple.cpuLength / (tuple.deadline - t_ij_transmit);
        return mps;
    }

    function createServerPriorities(ServerNode memory server) private {
        for (uint i = 0; i < activeAuction.mobileKeys.length; i++) {
            uint tupleID = activeAuction.mobileKeys[i];
            MobilePriorityBlock memory newPriorityBlock = MobilePriorityBlock(
                tupleID,
                serverCost(server, activeAuction.mobileTasks[tupleID])
            );
            addMobilePriorityBlockSorted(newPriorityBlock, server.name);
        }
    }

    function addMobilePriorityBlockSorted(MobilePriorityBlock memory priorityBlock, string memory serverName) private {
        activeAuction.serverPriorities[serverName].push(priorityBlock); // TODO
        MobilePriorityBlock[] memory serverPriorities = activeAuction.serverPriorities[serverName];
        if (serverPriorities.length == 1) {
            return;
        }
        uint i = 0;
        for (i; i < serverPriorities.length - 1; i ++ ) {
            if (!(priorityBlock.cost < serverPriorities[i].cost)) {
                break;
            }
        }
        for (uint j = serverPriorities.length - 1; j > i; j --) {
            activeAuction.serverPriorities[serverName][j] = serverPriorities[j - 1];
        }
        activeAuction.serverPriorities[serverName][i] = priorityBlock;
    }

    function updateTuplePriorities(ServerNode memory server) private {
        for (uint i = 0; i < activeAuction.mobileKeys.length; i ++) {
            uint tupleId = activeAuction.mobileKeys[i];
            ServerPriorityBlock memory newPriorityBlock = ServerPriorityBlock(
                server.name,
                tupleCost(activeAuction.mobileTasks[tupleId], server)
            );
            addServerPriorityBlockSorted(newPriorityBlock, tupleId);
        }
    }
    function addServerPriorityBlockSorted(ServerPriorityBlock memory priorityBlock, uint tupleID) private {
        ServerPriorityBlock[] memory moiblePriorities = activeAuction.mobilePriorities[tupleID];
        activeAuction.mobilePriorities[tupleID].push(priorityBlock); // TODO
        if (moiblePriorities.length == 1) {
            return;
        }
        uint i = 0;
        for (i; i < moiblePriorities.length - 1; i ++ ) {
            if (priorityBlock.cost < moiblePriorities[i].cost) {
                break;
            }
        }
        for (uint j = moiblePriorities.length - 1; j > i; j --) {
            activeAuction.mobilePriorities[tupleID][j] = moiblePriorities[j - 1];
        }
        activeAuction.mobilePriorities[tupleID][i] = priorityBlock;
    }
    function tupleCost(MobileTask memory tuple, ServerNode memory server) private pure returns (uint) {
        int distplus6 = ((int256(tuple.xCoordinate) - int256(server.xCoordinate)) ** 2 
                                + (int256(tuple.yCoordinate) - int256(server.yCoordinate)) ** 2) ** 2;
        uint logvint = log2(uint(1 + (500000000000 * int256(tuple.ueTransmissionPower)) / distplus6));
        uint t_ij_transmit = (1000000 * tuple.nwLength) / (logvint * tuple.ueUpBW);
        uint t_ij_process = (1000000 * tuple.cpuLength) / server.mips;
        uint t_ij_offload_norm = (t_ij_transmit + t_ij_process) / tuple.deadline;
        uint e_ij_offload_norm = (t_ij_transmit * tuple.ueTransmissionPower * 1000 
                            + t_ij_process * tuple.ueIdlePower) / 
                                        (tuple.deadline * (tuple.ueTransmissionPower * 1000 + tuple.ueIdlePower));
        uint pref = t_ij_offload_norm + e_ij_offload_norm + server.offer * 1000; // (server.offer/1000) * 1000000
        // sort 100 200 300 ...
        return pref;
    }
    function sqrt(uint x) private pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    function serverCost(ServerNode memory server, MobileTask memory tuple) private pure returns (uint) {

        int dist = ((int256(tuple.xCoordinate) - int256(server.xCoordinate)) ** 2 
                        + (int256(tuple.yCoordinate) - int256(server.yCoordinate)) ** 2);
        uint cost =  uint128(1000000 + tuple.offer * 1000 - 2357 * sqrt(uint(dist)));
        return cost;
    }

    function auctionResultTuple(uint tupleID) public {

        if (activeAuction.assingedTuplesMap[tupleID] == false) {
            calcAuctionResult(tupleID);
        } else {
        }
        emit AuctionTupleResult(activeAuction.tupleResult[tupleID]);
    }

    function calcAuctionResult(uint tupleID) private {
        uint initalTupleID = tupleID;
        for (uint i = 0; i < activeAuction.serverKeys.length; i ++) {
            tempServerQuta[activeAuction.serverKeys[i]] = activeAuction.serverQuta[activeAuction.serverKeys[i]];
        }
        while (true) {
            while (true) {
                bool tupleNotAssigned = true;
                bool foundCircle = false;
                string memory circleStartServer = "";
                for (uint i = 0; i < activeAuction.serverKeys.length; i ++) {
                    string memory serverName = activeAuction.mobilePriorities[tupleID][i].name;
                    uint tupleMips = activeAuction.tupleRequireMips[serverName].tuples[tupleID];
                    if (tupleMips <= tempServerQuta[serverName] && 
                        activeAuction.serverNodes[serverName].offer <= activeAuction.mobileTasks[tupleID].offer) { // servers does not exit the process at all!!! NOTE
                        tempServerQuta[serverName] = tempServerQuta[serverName] - tupleMips;
                        tempTupleResult[tupleID] = serverName;
                        tupleNotAssigned = false;
                        for (uint j = 0; j < activeAuction.mobileKeys.length; j ++) { // No calc on if server is able to handle
 
                            uint perfTupleID = activeAuction.serverPriorities[serverName][j].id;
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
                                uint TupleRounding = activeAuction.serverResult[serverRounding];
                                for (uint ind1 = 0; ind1 < tempVisitedTuples.length; ind1 ++) {
                                    if (TupleRounding == tempVisitedTuples[ind1]) {
                                        foundCircle = true;
                                        circleStartServer = serverRounding;
                                        break;
                                    }
                                }
                                tempVisitedTuples.push(TupleRounding);

                                if (bytes(tempTupleResult[activeAuction.serverResult[serverRounding]]).length > 0) {
                                    serverRounding = tempTupleResult[activeAuction.serverResult[serverRounding]];
                                    for (uint ind1 = 0; ind1 < tempVisitedServers.length; ind1 ++) {
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

                    uint tupleRoundingID = activeAuction.serverResult[circleStartServer];
                    while (true) {
                        activeAuction.tupleResult[tupleRoundingID] = tempTupleResult[tupleRoundingID];
                        activeAuction.assingedTuples.push(tupleRoundingID);
                        activeAuction.assingedTuplesMap[tupleRoundingID] = true;
                        uint tupleMips = activeAuction.tupleRequireMips[tempTupleResult[tupleRoundingID]].tuples[tupleID];
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
