// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "hardhat/console.sol";
import "../abdk-libraries-solidity/ABDKMath64x64.sol";
import "../abdk-libraries-solidity/ABDKMathQuad.sol";
// import "prb-math/contracts/PRBMathSD59x18.sol";
import "prb-math/contracts/PRBMathSD59x18Typed.sol";

contract AuctionManager {
    /*
        this contract will handle holding auctions

            we need an auction to be started at a specific time, e.g., 12:00, and end in a 
            specific time, e.g., 13:00, this auction can be interacted with these actions:
                - register a new server node in the auction
                - register a new task into the auction
                - get the result of auction
            
            we are going to implement multiple auctions in different time in only one 
            contract because deploying a new contract for each auction charges at least
            20$ for the person starting the event, therefore we will use an acution counter
            with multiple 2D arrays and mappings to hold data about the auctions.
            storage schema:

            auction {
                id
                start time ## ** we use unix timestamps 
                list of server nodes
                list of mobile nodes
            }
            auctions => a list of auctions
            current auction id
            last completed auction id
            auctionLifeTime 

            we must calculate the result of auction with every change in the state because 
            doing it at the end of auction is 1. not possible because maybe no one calls
            the contract, 2. not possible because the last person calling the contract will
            be heavilly gased.
    */
    
    // using PRBMathSD59x18 for uint256;
    using PRBMathSD59x18Typed for PRBMath.SD59x18;
    
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

        uint busyPower; // float
        uint downBw;
        uint idlePower; // float
        uint level;
        uint mips;
        uint ram;
        uint ratePerMips; // float
        uint upLinkLatency;
        uint areaId;
        uint joinDelay;
        
        uint xCoordinate;
        uint yCoordinate;

        uint offer;
    }

    struct MobileTask {
        uint id;

        uint cpuLength;
        uint nwLength;
        uint pesNumber;
        uint outputSize;

        uint deadline;

        uint offer;

        uint ueUpBW;

        uint xCoordinate;
        uint yCoordinate;

        uint ueTransmissionPower;

    }

    struct TupleMappingMips {
        mapping(uint => uint) tuples;
    }
    mapping(string => uint) tempServerQuta;
    mapping(uint => string) tempTupleResult;
    struct Auction {
        uint startTime; // init with block.timestamp

        uint lastMobileNode; // init with 0
        uint lastServerNode; // init with 0

        uint[] mobileKeys;
        mapping(uint => MobileTask) mobileTasks;
        mapping(uint => ServerPriorityBlock[]) mobilePriorities;

        string[] serverKeys;
        mapping(string => ServerNode) serverNodes;
        mapping(string => MobilePriorityBlock[]) serverPriorities;
        mapping(string => uint) serverQuta;
        
        mapping(string => TupleMappingMips) tupleRequireMips;
        
        mapping(uint => string) tupleResult;
        uint[] assingedTuples;
        mapping(string => uint) serverResult;
        /*
            When a new server registers:
                save the info in serverKeys and serverNodes
                there are some tuples in the auction:
                    we need to create a priority list for this new server \
                    and add each of them in it, e.g:
                        NewServerPriority => [{t1, 100}, {t4, 50}, {t2, 100}]
                    and after that we need to add this new server \
                    to every tuple's priority list, e.g:
                        before: 
                            T1Priority => {{s1, 100}, {s2, 80}}
                            T2Priority => {{s2, 100}, {s1, 80}}
                            T4Priority => {{s1, 20}, {s2, 10}}
                        after:
                            T1Priority => {{s1, 100}, {s2, 80}, {new_s, 70}}
                            T2Priority => {{s2, 100}, {s1, 80}, {new_s, 70}}
                            T4Priority => {{new_s, 70}, {s1, 20}, {s2, 10}}
                    first of all for storing these kind of information we need \
                    a data structure like this:
                        {
                            "string": [{"name": "string", "priority": int}, ...],
                            "string": [{"name": "string", "priority": int}, ...]
                        }
                        mapping(key => Struct[])
                    read about workflow in each server and node registeration process
                
        */
    }
    mapping(uint => Auction) auctions;
    uint private activeAuction = 0;
    // uint private lastCompleteAuction = 0;
    uint private auctionLifeTime = 30; // this is in seconds

    event DebugEvent(
        string text
    );
    event AuctionTupleResult (
        string serverName
    );
    event DebugUint(
        uint number
    );

    event DebugBool(
        bool boolean
    );

    event MobileTaskRegistered(
        uint id,
        uint auctionID,
        uint biddersCount
    );

    event ServerNodeRegistered(
        string name,
        uint auctionID,
        uint biddersCount
    );

    function registerMobileTask(
        uint id, uint cpuLength, uint nwLength, uint pesNumber, uint outputSize,
        uint deadline, uint offer, uint ueUpBW, uint xCoordinate, uint yCoordinate,
        uint ueTransmissionPower
    ) public {
        // we does not check if this task is already registered in active autcion
        /*
            - check if current auction is still valid otherwise creates a new auction
            - add tuple meta data into the mobileTasks
            - add the key of that tuple to mobileKeys to be accessable
                this means that in the mappig you can not access to the keys and values
                for getting the values you need to first obtain the keys from mobileKeys
            - create and add this tuple priority for each server in mobilePriorities:
                - calculate cost for all tuple -> server(i) pairs and sort them in \
                mobilePriorities[id].
                    How to sort?? we new that from iteration zero we have how many 
                    pairs there are in this array, so here is an example:
                        for server in servers:
                            iteration zero:
                                mobilePriorities[id][0] = ServerPriorityBlock(server.name, tupleCost(tuple, server))
                            next:
                                for pair in mobilePriorities:
                                    # consider this we must sort in descending
                                    if tupleCost(tuple, server) > pair.cost:
                                        insert ServerPriorityBlock(server.name, tupleCost(tuple, server)) into index 0
                                        How to insert?? we have an array of structs, e.g:
                                            [struct(str, uint), struct(str, uint), ]
                                        we can make a temporary variable and shift all of the indexes, a traditional
                                        way a little complex and cpu busy, \
                                        or we can use a linked list, complex solution
                                    else:
                                        mobilePriorities[id][1] = ServerPriorityBlock(server.name, tupleCost(tuple, server))
                            next:
                                ...
            - create and add this tuple priority in each server's serverPriorities:
                - calculate cost for all server(i) -> tuple pairs and sort them in already existing \
                serverPriorities[i], e.g:
                    for key in serverKeys:
                        cost = serverCost(server(key), tuple)
                        for pair in serverPriorities[key]:
                            if cost < pair.cost:
                                insert MobilePriorityBlock(id, cost) before
                                break
            - emit success to client 
        */
        console.log("REGISTER TUPLE......");
        requestAuction();
        auctions[activeAuction].mobileTasks[id] = MobileTask(
            id, cpuLength, nwLength, pesNumber, outputSize, deadline,
            offer, ueUpBW, xCoordinate, yCoordinate, ueTransmissionPower
        );
        auctions[activeAuction].mobileKeys.push(id);
        createTuplePriorities(auctions[activeAuction].mobileTasks[id]);
        updateServerPriorities(auctions[activeAuction].mobileTasks[id]);
        updateTupleRequireMips(auctions[activeAuction].mobileTasks[id]);
        emit MobileTaskRegistered(id, activeAuction, auctions[activeAuction].mobileKeys.length);
    }

    function updateServerPriorities(MobileTask memory tuple) private  {
        /* 
            updates already exisiting server priority list with new tuple
            - create and add this tuple priority in each server's serverPriorities:
                - calculate cost for all server(i) -> tuple pairs and sort them in already existing \
                serverPriorities[i].

        */
        for (uint i = 0; i < auctions[activeAuction].serverKeys.length; i ++) {
            MobilePriorityBlock memory newPriorityBlock = MobilePriorityBlock(
                tuple.id,
                serverCost(auctions[activeAuction].serverNodes[auctions[activeAuction].serverKeys[i]], tuple)
            );
            addMobilePriorityBlockSorted(newPriorityBlock, auctions[activeAuction].serverKeys[i]);
            console.log("update new priority block to server priorities: (serverName, tupleID, cost) ");
            console.log(auctions[activeAuction].serverKeys[i], tuple.id, newPriorityBlock.cost);
        }
    }

    function createTuplePriorities(MobileTask memory tuple) private {
        /*
            creates tuple priority list for newly arrived task on each server
            - create and add this tuple priority for each server in mobilePriorities:
                - calculate cost for all tuple -> server(i) pairs and sort them in \
                mobilePriorities[id].
        */
        console.log("creating tuple priorities for: ", tuple.id);
        for (uint i = 0; i < auctions[activeAuction].serverKeys.length; i ++) {
            ServerPriorityBlock memory newPriorityBlock = ServerPriorityBlock(
                auctions[activeAuction].serverKeys[i],
                tupleCost(tuple, auctions[activeAuction].serverNodes[auctions[activeAuction].serverKeys[i]])
            );
            addServerPriorityBlockSorted(newPriorityBlock, tuple.id);
            console.log("pushed new priority block to tuple priorities: (serverName, tupleID, cost) ");
            console.log(auctions[activeAuction].serverKeys[i], tuple.id, newPriorityBlock.cost);
       }
    }

    function registerServerNode(
        string memory name, uint busyPower, // float
        uint downBw, uint idlePower, // float
        // uint level,
         uint mips, uint ram,
        // uint ratePerMips, // float
        uint upLinkLatency,
        //  uint areaId
        // uint joinDelay,
        uint xCoordinate,
        uint yCoordinate , uint offer
    ) public {
        // we does not check if this name already is registered in this auction
        /*
            - check if there is an ongoing auction, otherwise create a new
            - add server metadata in serverNodes
            - add server name in serverKeys for accessablility sake
            - create the serverPriority for already exisiting tuples in the auction:
                for each tuple(i):
                    insert sorted in serverPriorities[server.name] MobilePriorityBlock(tuple(i).id, serverCost(server, tuple))
            - update serverPriority for already exisiting tuples:
                for each tuple(i):
                    insert sorted in mobilePriorities(tuple(i).id) ServerPriorityBlock(server.name, tupleCost(tuple, server))
            - emit success to user
        */
        requestAuction();
        auctions[activeAuction].serverNodes[name] = ServerNode(
            name, busyPower, downBw, idlePower, 0,
            mips, ram, 0, upLinkLatency, 0,
            0, xCoordinate, yCoordinate, offer
        );
        console.log("REGISTERING A SERVER");
        auctions[activeAuction].serverKeys.push(name);
        createServerPriorities(auctions[activeAuction].serverNodes[name]);
        auctions[activeAuction].serverQuta[name] = mips;
        updateTuplePriorities(auctions[activeAuction].serverNodes[name]);
        // console.log(auctions[activeAuction].serverPriorities[name][0].id);
        createTupleRequireMips(auctions[activeAuction].serverNodes[name]);
        // console.log(auctions[activeAuction].mobilePriorities[1][0].name);
        emit ServerNodeRegistered(name, activeAuction, auctions[activeAuction].serverKeys.length);
    }

    function createTupleRequireMips(ServerNode memory server) private {
        for (uint i = 0; i < auctions[activeAuction].mobileKeys.length; i ++) {
            MobileTask memory tuple = auctions[activeAuction].mobileTasks[auctions[activeAuction].mobileKeys[i]];
            // tuple.requireMips += tupleCost(tuple, server);
            auctions[activeAuction].tupleRequireMips[server.name].tuples[tuple.id] = getTupleMipsOnServer(server, tuple);
            console.log("add tuple req mips (serverName, tupleID, mips) :");
            console.log(server.name, tuple.id, auctions[activeAuction].tupleRequireMips[server.name].tuples[tuple.id]);
        }
    }

    function updateTupleRequireMips(MobileTask memory tuple) private {
        for (uint i = 0; i < auctions[activeAuction].serverKeys.length; i ++) {
            ServerNode memory server = auctions[activeAuction].serverNodes[auctions[activeAuction].serverKeys[i]];
            auctions[activeAuction].tupleRequireMips[server.name].tuples[tuple.id] = getTupleMipsOnServer(server, tuple);
            console.log("update tuple req mips (serverName, tupleID, mips) :");
            console.log(server.name, tuple.id, auctions[activeAuction].tupleRequireMips[server.name].tuples[tuple.id]);
        }
    }
    function log2(uint x) private returns (uint y){
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
    function getTupleMipsOnServer(ServerNode memory server, MobileTask memory tuple) private returns (uint) {
        console.log("********* tuple mips &&&&&&&&&&&&&&&&&&");
        console.log(server.xCoordinate, server.yCoordinate);
        console.log(tuple.xCoordinate, tuple.yCoordinate);
        console.log(tuple.nwLength);
        console.log(tuple.ueUpBW);
        console.log(tuple.ueTransmissionPower);
        console.log("***********************");
        // ((tuple.x - server.x) ** 2 + (tuple.y - server.y) ** 2) ** 0.5
        bytes16 distX = ABDKMathQuad.fromInt(int256(tuple.xCoordinate) - int256(server.xCoordinate));
        bytes16 distY =  ABDKMathQuad.fromInt(int256(tuple.yCoordinate) - int256(server.yCoordinate));
        bytes16 distplus = ABDKMathQuad.add(
            ABDKMathQuad.mul(distX, distX), 
            ABDKMathQuad.mul(distY, distY)
        );
        bytes16 distplus2 = ABDKMathQuad.mul(distplus, distplus);
        bytes16 distplus6 = ABDKMathQuad.mul(
            ABDKMathQuad.mul(
               distplus2, distplus2 
            ), 
            distplus2
        );
        bytes16 noisePowerm1 = ABDKMathQuad.fromInt(5 * 10 ** 11);
        bytes16 loggvalue = ABDKMathQuad.log_2(ABDKMathQuad.add(
            ABDKMathQuad.fromInt(1),
            ABDKMathQuad.div(
                ABDKMathQuad.mul(
                    ABDKMathQuad.fromInt(int256(tuple.ueTransmissionPower)),
                    noisePowerm1
                ),
                distplus6
            )
        ));
        bytes16 t_ij_transmit = ABDKMathQuad.div(
            ABDKMathQuad.fromInt(int256(tuple.nwLength)),
            ABDKMathQuad.mul(
                ABDKMathQuad.fromInt(int256(tuple.ueUpBW)), loggvalue
            )
        );
        console.log(uint256(ABDKMathQuad.toInt(
            ABDKMathQuad.mul(
                t_ij_transmit, ABDKMathQuad.fromInt(1000)
            )
        )));
        // t_ij_transmit ==> input/(upload*log(1+((power*noisem1)/(distanceplus6))))
        return 666;
    }

    function createServerPriorities(ServerNode memory server) private {
        /* 
            does this step:
                for each tuple(i):
                    insert sorted in serverPriorities[server.name] MobilePriorityBlock(tuple(i).id, serverCost(server, tuple))
        */
        // list of priorities already exist for this server in Auction.serverPriorities[servername]
        for (uint i = 0; i < auctions[activeAuction].mobileKeys.length; i++) {
            // serverCost(server, auctions[activeAuction].mobileTasks[auctions[activeAuction].mobileKeys[i]]);
            MobilePriorityBlock memory newPriorityBlock = MobilePriorityBlock(
                auctions[activeAuction].mobileKeys[i],
                serverCost(server, auctions[activeAuction].mobileTasks[auctions[activeAuction].mobileKeys[i]])
            );
            addMobilePriorityBlockSorted(newPriorityBlock, server.name);
            console.log("pushed new priority block to server priorities: (serverName, tupleID, cost) ");
            console.log(server.name, newPriorityBlock.id, newPriorityBlock.cost);
        }
    }

    function addMobilePriorityBlockSorted(MobilePriorityBlock memory priorityBlock, string memory serverName) private {
        // this must add priorityBlock to Auction.serverPriorities in a sorted way later
        auctions[activeAuction].serverPriorities[serverName].push(priorityBlock); // TODO
    }

    function updateTuplePriorities(ServerNode memory server) private {
        /*
            does this step:
                for each tuple(i):
                    insert sorted in mobilePriorities(tuple(i).id) ServerPriorityBlock(server.name, tupleCost(tuple, server))
        */
        for (uint i = 0; i < auctions[activeAuction].mobileKeys.length; i ++) {
            ServerPriorityBlock memory newPriorityBlock = ServerPriorityBlock(
                server.name,
                tupleCost(auctions[activeAuction].mobileTasks[auctions[activeAuction].mobileKeys[i]], server)
            );
            addServerPriorityBlockSorted(newPriorityBlock, auctions[activeAuction].mobileKeys[i]);
            console.log("update with new priority block to tuple priorities: (serverName, tupleID, cost) ");
            console.log(server.name, auctions[activeAuction].mobileKeys[i], newPriorityBlock.cost);
        }
    }
    function addServerPriorityBlockSorted(ServerPriorityBlock memory priorityBlock, uint tupleID) private {
        // this must add priorityBlock to Auction.serverPriorities in a sorted way later
        auctions[activeAuction].mobilePriorities[tupleID].push(priorityBlock); // TODO
    }
    function tupleCost(MobileTask memory tuple, ServerNode memory server) private pure returns (uint) {
        /* 
            this value shows that how much a tuple likes to get picked by a server
            this is used in mobilePriorities
        */
        return 1000000 - server.offer; // TODO
    }

    function serverCost(ServerNode memory server, MobileTask memory tuple) private pure returns (uint) {
        /*
            this value shows that how much the server likes to take the tuple
            this is used in serverPriorities
        */
        return tuple.offer * tuple.nwLength; // TODO
    }

    function auctionResultTuple(uint auctionID, uint tupleID) public {
        /*
            this interface intends to return the response for the an auction
            inputs:     
                auction id
                ?
        */
        bool tupleWasAssigned = false;
        emit DebugEvent("starting to process");
        for (uint k = 0; k < auctions[auctionID].assingedTuples.length; k ++) {
            if (auctions[auctionID].assingedTuples[k] == tupleID) {
                tupleWasAssigned = true;
            }
        }
        emit DebugBool(tupleWasAssigned);
        if (tupleWasAssigned == false) {
            emit DebugEvent("tuple was not assigned");
            calcAuctionResult(auctions[auctionID], tupleID);
        } else {
            emit DebugEvent("tuple was assigned");
        }
        emit AuctionTupleResult(auctions[auctionID].tupleResult[tupleID]);
    }

    function calcAuctionResult(Auction storage auction, uint tupleID) private {
        /*
            we have tuple priorities:
                mobilePriorities[tuple.id][from 0 to length of servers]
            we have server priorities:
                serverPriorities[server.name][from 0 to length of tuples]
            we have tuple required mips:
                tupleRequireMips[server.name].tuples[tuple.id]
            we have server quta:
                serverQuta[server.name]
        */
        uint initalTupleID = tupleID;
        for (uint i = 0; i < auction.serverKeys.length; i ++) {
            tempServerQuta[auction.serverKeys[i]] = auction.serverQuta[auction.serverKeys[i]];
            console.log(auction.serverKeys[i] , tempServerQuta[auction.serverKeys[i]], auction.serverQuta[auction.serverKeys[i]]);
        }
        // uint tupleID = auction.mobileKeys[0]; // if not allocated
        //else break
        console.log("TEST");
        while (true) {
            console.log("tupleID: ", tupleID);
            while (true) {
                bool tupleNotAssigned = true;
                bool foundCircle = false;
                string memory circleStartServer = "";
                console.log("where it failds?");
                console.log(auction.serverKeys.length);
                console.log(auction.mobileKeys.length);
                for (uint i = 0; i < auction.serverKeys.length; i ++) {
                    // find the tuple => server? and then server? => tuple
                    console.log("before for loop tuple priorities ", tupleID, i);
                    console.log(auction.mobilePriorities[tupleID].length);
                    console.log(auction.mobilePriorities[tupleID][i].cost);
                    string memory serverName = auction.mobilePriorities[tupleID][i].name;
                    console.log("serverName: ", serverName);
                    uint tupleMips = auction.tupleRequireMips[serverName].tuples[tupleID];
                    console.log("req mips: ", tupleMips, tempServerQuta[serverName]);
                    if (tupleMips <= tempServerQuta[serverName]) { // servers does not exit the process at all!!! NOTE
                        // tuple is assinged to server
                        tempServerQuta[serverName] = tempServerQuta[serverName] - tupleMips;
                        console.log("new server quota after: ", tempServerQuta[serverName]);
                        tempTupleResult[tupleID] = serverName;
                        tupleNotAssigned = false;
                        // T0 => S1 => T?  => ... T =/ S T=>S=/T?
                        for (uint j = 0; j < auction.mobileKeys.length; j ++) { // No calc on if server is able to handle
                            // find the prefered tuple for server
                            // choose from not assinged tuples (real ones) Note
                            uint perfTupleID = auction.serverPriorities[serverName][j].id;
                            bool perfTupleWasAssigned = false;
                            for (uint k = 0; k < auction.assingedTuples.length; k ++) {
                                if (auction.assingedTuples[k] == perfTupleID) {
                                    perfTupleWasAssigned = true;
                                }
                            }
                            if (perfTupleWasAssigned == false) {
                                auction.serverResult[serverName] = perfTupleID;
                                break;
                            }
                        }
                        console.log("trying to find circle");
                        string memory serverRounding = serverName;
                        while (true) {
                            // find out if a circle is created
                            // we check with old nodes NOTE
                            console.log("serverRounding: ", serverRounding);
                            if (auction.serverResult[serverRounding] != 0) {
                                console.log("tuple rounding: ", auction.serverResult[serverRounding]);
                                if (bytes(tempTupleResult[auction.serverResult[serverRounding]]).length > 0) {
                                    serverRounding = tempTupleResult[auction.serverResult[serverRounding]];
                                    console.log("compare", serverRounding, serverName);
                                    if (keccak256(abi.encodePacked((serverRounding))) == keccak256(abi.encodePacked((serverName)))) {
                                        console.log("was same");
                                        foundCircle = true;
                                        circleStartServer = serverName;
                                        break;
                                    }
                                } else break;
                            } else break;
                        }
                        console.log("foundCircle: ", foundCircle);
                        break;
                    }
                }
                if (foundCircle) {
                    // T1 -> S2 -> T0 -> S4 -> T15 -> S2:circleStartServer -> T0
                    // T1 -> S2 -> T?
                    // .
                    // .
                    // T1 -> S? RESULT 50%
                    // T20 21... 
                    // T1 -> S2 -> T0 -> S4 -> T15 -> S4:circleStartServer -> T15 
                    // add new results to actual results
                    uint tupleRoundingID = auction.serverResult[circleStartServer];
                    console.log("Assigning foundings here ==== ");
                    while (true) {
                        auction.tupleResult[tupleRoundingID] = tempTupleResult[tupleRoundingID];
                        auction.assingedTuples.push(tupleRoundingID);
                        console.log("ASSIGEND TUPLE: ", tupleRoundingID, auction.tupleResult[tupleRoundingID]);
                        uint tupleMips = auction.tupleRequireMips[tempTupleResult[tupleRoundingID]].tuples[tupleID];
                        auction.serverQuta[tempTupleResult[tupleRoundingID]] = auction.serverQuta[tempTupleResult[tupleRoundingID]] - tupleMips;
                        console.log("Temp Quta: ", tempTupleResult[tupleRoundingID], tempServerQuta[tempTupleResult[tupleRoundingID]]);
                        console.log("QUTA CHANGED: ", tupleMips, auction.serverQuta[tempTupleResult[tupleRoundingID]]);
                        if (keccak256(abi.encodePacked((tempTupleResult[tupleRoundingID]))) == keccak256(abi.encodePacked((circleStartServer)))) {
                            console.log("breaking the circle here");
                            break;
                        }
                        tupleRoundingID = auction.serverResult[tempTupleResult[tupleRoundingID]];
                    }
                    break;
                }
                if (tupleNotAssigned) {
                    // Tuple not assigned to any server
                    // Result T => !!
                    console.log(" TUPLE not assigned at all");
                    auction.assingedTuples.push(tupleID);
                    break;
                }
                tupleID = auction.serverResult[tempTupleResult[tupleID]];
            }
            bool initialTupleWasAssigned = false;
            for (uint k = 0; k < auction.assingedTuples.length; k ++) {
                if (auction.assingedTuples[k] == initalTupleID) {
                    initialTupleWasAssigned = true;
                }
            }
            if (initialTupleWasAssigned) {
                break;
            } else {
                console.log("INITIAL TUPLE WAS NOT ASSIGEND STARTING OVER");
                tupleID = initalTupleID;
            }
        }
    }

    function requestAuction() private {
        /*
            this method is called whenever a server or a task is sended,
            it will check if we do not have an active auction and start a 
            new one if neccessarry
        */
        if (activeAuction == 0 || isAuctionEnded(activeAuction)) {
            initAuction();
        }
    }

    function initAuction() private {
        // neven call this when we have a active auction
        activeAuction ++;
        Auction storage newAuction = auctions[activeAuction];
        newAuction.startTime = block.timestamp;
    }

    function isAuctionEnded(uint index) private view returns (bool) {
        // dont call when acitveAuction == 0
        uint auctionStartTime = auctions[index].startTime;
        if (block.timestamp > (auctionStartTime + auctionLifeTime)) {
            return true;
        } else {
            return false;
        }
    }
}