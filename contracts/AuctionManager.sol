// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "hardhat/console.sol";

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
        
        uint offer;
    }

    struct MobileTask {
        uint id;

        uint cpuLength;
        uint nwLength;
        uint pesNumber;
        uint outputSize;

        uint offer;
    }

    struct TupleMappingMips {
        mapping(uint => uint) tuples;
    }

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
    uint private auctionLifeTime = 5; // this is in seconds

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
        uint offer
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
        requestAuction();
        auctions[activeAuction].mobileTasks[id] = MobileTask(
            id, cpuLength, nwLength, pesNumber, outputSize, offer
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
        }
    }

    function createTuplePriorities(MobileTask memory tuple) private {
        /*
            creates tuple priority list for newly arrived task on each server
            - create and add this tuple priority for each server in mobilePriorities:
                - calculate cost for all tuple -> server(i) pairs and sort them in \
                mobilePriorities[id].
        */
        for (uint i = 0; i < auctions[activeAuction].serverKeys.length; i ++) {
            ServerPriorityBlock memory newPriorityBlock = ServerPriorityBlock(
                auctions[activeAuction].serverKeys[i],
                tupleCost(tuple, auctions[activeAuction].serverNodes[auctions[activeAuction].serverKeys[i]])
            );
            addServerPriorityBlockSorted(newPriorityBlock, tuple.id);
       }
    }

    function registerServerNode(
        string memory name, uint busyPower, // float
        uint downBw, uint idlePower, // float
        uint level, uint mips, uint ram,
        uint ratePerMips, // float
        uint upLinkLatency, uint areaId,
        uint joinDelay, uint offer
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
            name, busyPower, downBw, idlePower, level,
            mips, ram, ratePerMips, upLinkLatency, areaId,
            joinDelay, offer
        );
        auctions[activeAuction].serverKeys.push(name);
        createServerPriorities(auctions[activeAuction].serverNodes[name]);
        auctions[activeAuction].serverQuta[name] = mips;
        console.log("server priority");
        // console.log(auctions[activeAuction].serverPriorities[name][0].id);
        createTupleRequireMips(auctions[activeAuction].serverNodes[name]);
        console.log("fails here?");
        updateTuplePriorities(auctions[activeAuction].serverNodes[name]);
        // console.log(auctions[activeAuction].mobilePriorities[1][0].name);
        emit ServerNodeRegistered(name, activeAuction, auctions[activeAuction].serverKeys.length);
    }

    function createTupleRequireMips(ServerNode memory server) private {
        for (uint i = 0; i < auctions[activeAuction].mobileKeys.length; i ++) {
            MobileTask memory tuple = auctions[activeAuction].mobileTasks[auctions[activeAuction].mobileKeys[i]];
            // tuple.requireMips += tupleCost(tuple, server);
            auctions[activeAuction].tupleRequireMips[server.name].tuples[tuple.id] = getTupleMipsOnServer(server, tuple);
        }
    }

    function updateTupleRequireMips(MobileTask memory tuple) private {
        for (uint i = 0; i < auctions[activeAuction].serverKeys.length; i ++) {
            ServerNode memory server = auctions[activeAuction].serverNodes[auctions[activeAuction].serverKeys[i]];
            auctions[activeAuction].tupleRequireMips[server.name].tuples[tuple.id] = getTupleMipsOnServer(server, tuple);
        }
    }

    function getTupleMipsOnServer(ServerNode memory server, MobileTask memory tuple) pure private returns (uint) {
        return server.mips; // TODO
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
        mapping(uint => string) storage tempTupleResult = auction.tupleResult;
        mapping(string => uint) storage tempServerQuta = auction.serverQuta;
        // uint tupleID = auction.mobileKeys[0]; // if not allocated
        //else break

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
                    console.log("before for loop tuple priorities");
                    string memory serverName = auction.mobilePriorities[tupleID][i].name;
                    console.log("serverName: ", serverName);
                    uint tupleMips = auction.tupleRequireMips[serverName].tuples[tupleID];
                    if (tupleMips <= tempServerQuta[serverName]) { // servers does not exit the process at all!!! NOTE
                        // tuple is assinged to server
                        tempServerQuta[serverName] = tempServerQuta[serverName] - tupleMips;
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
                    while (true) {
                        auction.tupleResult[tupleRoundingID] = tempTupleResult[tupleRoundingID];
                        auction.assingedTuples.push(tupleRoundingID);
                        uint tupleMips = auction.tupleRequireMips[tempTupleResult[tupleRoundingID]].tuples[tupleID];
                        auction.serverQuta[tempTupleResult[tupleRoundingID]] = auction.serverQuta[tempTupleResult[tupleRoundingID]] - tupleMips;
                        if (keccak256(abi.encodePacked((tempTupleResult[tupleRoundingID]))) == keccak256(abi.encodePacked((circleStartServer)))) {
                            break;
                        }
                        tupleRoundingID = auction.serverResult[tempTupleResult[tupleRoundingID]];
                    }
                    break;
                }
                if (tupleNotAssigned) {
                    // Tuple not assigned to any server
                    // Result T => !!
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