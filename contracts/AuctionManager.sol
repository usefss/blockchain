// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
// import "hardhat/console.sol";

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

	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

    function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}
	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}
	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}
	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}
    function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}
	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}
    function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}
	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}
	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

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
    struct Auction {
        // uint startTime; // init with block.timestamp

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
        mapping(uint => bool) assingedTuplesMap;
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
    // mapping(uint => Auction) auctions;
    // uint private activeAuction = 0;
    // uint private lastCompleteAuction = 0;
    // uint private auctionLifeTime = 3000; // this is in seconds
    Auction activeAuction;
    // constructor() {
    //     // activeAuction = Auction(); 
    // }
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
        bool bbb
    );

    event MobileTaskRegistered(
        uint id,
        uint biddersCount
    );

    event ServerNodeRegistered(
        string name,
        uint biddersCount
    );

    function Test() public {
        log("hello ooooooooooooooo");
        log("hello ooooooooooooooo");
        log("hello ooooooooooooooo");
        log("hello ooooooooooooooo");
        log("hello ooooooooooooooo");
        emit DebugEvent("Hello World");
    }

    function registerMobileTask(
        uint id, uint cpuLength, uint nwLength, 
        // uint pesNumber,
         uint outputSize,
        uint deadline, uint offer, uint ueUpBW, uint xCoordinate, uint yCoordinate,
        uint ueTransmissionPower, uint ueIdlePower
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
        log("REGISTER TUPLE......");
        // requestAuction();
        activeAuction.mobileTasks[id] = MobileTask(
            id, cpuLength, nwLength, 
            // pesNumber, 
            outputSize, deadline,
            offer, ueUpBW, xCoordinate, yCoordinate, ueTransmissionPower,
            ueIdlePower
        );
        activeAuction.mobileKeys.push(id);
        createTuplePriorities(activeAuction.mobileTasks[id]);
        updateServerPriorities(activeAuction.mobileTasks[id]);
        updateTupleRequireMips(activeAuction.mobileTasks[id]);
        emit MobileTaskRegistered(id, activeAuction.mobileKeys.length);
    }

    function updateServerPriorities(MobileTask memory tuple) private  {
        /* 
            updates already exisiting server priority list with new tuple
            - create and add this tuple priority in each server's serverPriorities:
                - calculate cost for all server(i) -> tuple pairs and sort them in already existing \
                serverPriorities[i].

        */
        for (uint i = 0; i < activeAuction.serverKeys.length; i ++) {
            MobilePriorityBlock memory newPriorityBlock = MobilePriorityBlock(
                tuple.id,
                serverCost(activeAuction.serverNodes[activeAuction.serverKeys[i]], tuple)
            );
            addMobilePriorityBlockSorted(newPriorityBlock, activeAuction.serverKeys[i]);
            // console.log("update new priority block to server priorities: (serverName, tupleID, cost) ");
            // console.log(activeAuction.serverKeys[i], tuple.id, newPriorityBlock.cost);
        }
    }

    function createTuplePriorities(MobileTask memory tuple) private {
        /*
            creates tuple priority list for newly arrived task on each server
            - create and add this tuple priority for each server in mobilePriorities:
                - calculate cost for all tuple -> server(i) pairs and sort them in \
                mobilePriorities[id].
        */
        // console.log("creating tuple priorities for: ", tuple.id);
        for (uint i = 0; i < activeAuction.serverKeys.length; i ++) {
            ServerPriorityBlock memory newPriorityBlock = ServerPriorityBlock(
                activeAuction.serverKeys[i],
                tupleCost(tuple, activeAuction.serverNodes[activeAuction.serverKeys[i]])
            );
            addServerPriorityBlockSorted(newPriorityBlock, tuple.id);
            // console.log("pushed new priority block to tuple priorities: (serverName, tupleID, cost) ");
            // console.log(activeAuction.serverKeys[i], tuple.id, newPriorityBlock.cost);
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
        // requestAuction();
        activeAuction.serverNodes[name] = ServerNode(
            name, 0, 0, 0, 0,
            mips, 0, 0, 0, 0,
            0, xCoordinate, yCoordinate, offer
        );
        log("REGISTERING A SERVER");
        activeAuction.serverKeys.push(name);
        createServerPriorities(activeAuction.serverNodes[name]);
        activeAuction.serverQuta[name] = mips;
        updateTuplePriorities(activeAuction.serverNodes[name]);
        createTupleRequireMips(activeAuction.serverNodes[name]);
        emit ServerNodeRegistered(name, activeAuction.serverKeys.length);
    }

    function createTupleRequireMips(ServerNode memory server) private {
        for (uint i = 0; i < activeAuction.mobileKeys.length; i ++) {
            MobileTask memory tuple = activeAuction.mobileTasks[activeAuction.mobileKeys[i]];
            // tuple.requireMips += tupleCost(tuple, server);
            activeAuction.tupleRequireMips[server.name].tuples[tuple.id] = getTupleMipsOnServer(server, tuple);
            // console.log("add tuple req mips (serverName, tupleID, mips) :");
            // console.log(server.name, tuple.id, activeAuction.tupleRequireMips[server.name].tuples[tuple.id]);
        }
    }

    function updateTupleRequireMips(MobileTask memory tuple) private {
        for (uint i = 0; i < activeAuction.serverKeys.length; i ++) {
            ServerNode memory server = activeAuction.serverNodes[activeAuction.serverKeys[i]];
            activeAuction.tupleRequireMips[server.name].tuples[tuple.id] = getTupleMipsOnServer(server, tuple);
            // console.log("update tuple req mips (serverName, tupleID, mips) :");
            // console.log(server.name, tuple.id, activeAuction.tupleRequireMips[server.name].tuples[tuple.id]);
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
        // console.log("******* MIPS ON SERVER ******");
        // console.log(tuple.cpuLength, tuple.deadline);
        // console.log(t_ij_transmit);
        uint mps = tuple.cpuLength / (tuple.deadline - t_ij_transmit);
        // console.log(mps);
        return mps;
    }

    function createServerPriorities(ServerNode memory server) private {
        /* 
            does this step:
                for each tuple(i):
                    insert sorted in serverPriorities[server.name] MobilePriorityBlock(tuple(i).id, serverCost(server, tuple))
        */
        // list of priorities already exist for this server in Auction.serverPriorities[servername]
        for (uint i = 0; i < activeAuction.mobileKeys.length; i++) {
            // serverCost(server, activeAuction.mobileTasks[activeAuction.mobileKeys[i]]);
            MobilePriorityBlock memory newPriorityBlock = MobilePriorityBlock(
                activeAuction.mobileKeys[i],
                serverCost(server, activeAuction.mobileTasks[activeAuction.mobileKeys[i]])
            );
            addMobilePriorityBlockSorted(newPriorityBlock, server.name);
            // console.log("pushed new priority block to server priorities: (serverName, tupleID, cost) ");
            // console.log(server.name, newPriorityBlock.id, newPriorityBlock.cost);
        }
    }

    function addMobilePriorityBlockSorted(MobilePriorityBlock memory priorityBlock, string memory serverName) private {
        // this must add priorityBlock to Auction.serverPriorities in a sorted way later
        log("&&&&& adding new priority block for server: ", serverName);
        log("block INFO: ", priorityBlock.id, priorityBlock.cost);
        // 900 800 700
        activeAuction.serverPriorities[serverName].push(priorityBlock); // TODO
        if (activeAuction.serverPriorities[serverName].length == 1) {
            log("initial priority cost");
            return;
        }
        uint i = 0;
        for (i; i < activeAuction.serverPriorities[serverName].length - 1; i ++ ) {
            log("index of server priority: ", i, activeAuction.serverPriorities[serverName][i].cost);
            if (!(priorityBlock.cost < activeAuction.serverPriorities[serverName][i].cost)) {
                break;
            }
        }
        log("must insert at index: ", i);
        for (uint j = activeAuction.serverPriorities[serverName].length - 1; j > i; j --) {
            activeAuction.serverPriorities[serverName][j] = activeAuction.serverPriorities[serverName][j - 1];
        }
        activeAuction.serverPriorities[serverName][i] = priorityBlock;
    }

    function updateTuplePriorities(ServerNode memory server) private {
        /*
            does this step:
                for each tuple(i):
                    insert sorted in mobilePriorities(tuple(i).id) ServerPriorityBlock(server.name, tupleCost(tuple, server))
        */
        for (uint i = 0; i < activeAuction.mobileKeys.length; i ++) {
            ServerPriorityBlock memory newPriorityBlock = ServerPriorityBlock(
                server.name,
                tupleCost(activeAuction.mobileTasks[activeAuction.mobileKeys[i]], server)
            );
            addServerPriorityBlockSorted(newPriorityBlock, activeAuction.mobileKeys[i]);
            // console.log("update with new priority block to tuple priorities: (serverName, tupleID, cost) ");
            // console.log(server.name, activeAuction.mobileKeys[i], newPriorityBlock.cost);
        }
    }
    function addServerPriorityBlockSorted(ServerPriorityBlock memory priorityBlock, uint tupleID) private {
        // this must add priorityBlock to Auction.serverPriorities in a sorted way later
        log("&&&&& adding new priority block for tuple: ", tupleID);
        log("block INFO: ", priorityBlock.name, priorityBlock.cost);
        activeAuction.mobilePriorities[tupleID].push(priorityBlock); // TODO
        if (activeAuction.mobilePriorities[tupleID].length == 1) {
            log("initial priority cost");
            return;
        }
        // 100 200 400
        uint i = 0;
        for (i; i < activeAuction.mobilePriorities[tupleID].length - 1; i ++ ) {
            log("index of server priority: ", i, activeAuction.mobilePriorities[tupleID][i].cost);
            if (priorityBlock.cost < activeAuction.mobilePriorities[tupleID][i].cost) {
                break;
            }
        }
        // 100 200 400 ?
        log("must insert at index: ", i);
        for (uint j = activeAuction.mobilePriorities[tupleID].length - 1; j > i; j --) {
            activeAuction.mobilePriorities[tupleID][j] = activeAuction.mobilePriorities[tupleID][j - 1];
        }
        activeAuction.mobilePriorities[tupleID][i] = priorityBlock;
    }
    function tupleCost(MobileTask memory tuple, ServerNode memory server) private pure returns (uint) {
        /* 
            this value shows that how much a tuple likes to get picked by a server
            this is used in mobilePriorities
        */
        // console.log("********* tuple mips &&&&&&&&&&&&&&&&&&");
        // console.log(server.xCoordinate, server.yCoordinate);
        // console.log(tuple.xCoordinate, tuple.yCoordinate);
        // console.log(tuple.nwLength);
        // console.log(tuple.ueUpBW);
        // console.log(tuple.ueTransmissionPower);
        // console.log(tuple.cpuLength, server.mips);
        // console.log("***********************");
        // ((tuple.x - server.x) ** 2 + (tuple.y - server.y) ** 2) ** 0.5
        // bytes16 distX = ABDKMathQuad.fromInt(int256(tuple.xCoordinate) - int256(server.xCoordinate));
        // bytes16 distY =  ABDKMathQuad.fromInt(int256(tuple.yCoordinate) - int256(server.yCoordinate));
        // bytes16 distplus = ABDKMathQuad.add(
        //     ABDKMathQuad.mul(distX, distX), 
        //     ABDKMathQuad.mul(distY, distY)
        // );
        // bytes16 distplus2 = ABDKMathQuad.mul(distplus, distplus);
        // bytes16 distplus6 = ABDKMathQuad.mul(
        //     ABDKMathQuad.mul(
        //        distplus2, distplus2 
        //     ), 
        //     distplus2
        // );
        // distplus6 = ABDKMathQuad.fromInt(ABDKMathQuad.toInt(distplus6));
        int distplus6 = ((int256(tuple.xCoordinate) - int256(server.xCoordinate)) ** 2 
                                + (int256(tuple.yCoordinate) - int256(server.yCoordinate)) ** 2) ** 2;
        // // bytes16 distplus6 = ABDKMathQuad.fromInt(531441000000);
        // bytes16 loggvalue = ABDKMathQuad.log_2(ABDKMathQuad.add(
        //     ABDKMathQuad.fromInt(2),
        //     ABDKMathQuad.div(
        //         ABDKMathQuad.mul(
        //             ABDKMathQuad.fromInt(int256(tuple.ueTransmissionPower)),
        //             ABDKMathQuad.fromInt(500000000000)
        //         ),
        //         distplus6
        //     )
        // ));
        // uint256 logvint = uint256(ABDKMathQuad.toInt(loggvalue));
        uint logvint = log2(uint(1 + (500000000000 * int256(tuple.ueTransmissionPower)) / distplus6));
        // console.log(logvint);
        uint t_ij_transmit = (1000000 * tuple.nwLength) / (logvint * tuple.ueUpBW);
        // console.log(t_ij_transmit);
        // int256 t_ij_transmit = int256((1000*tuple.nwLength) / (logvint * tuple.ueUpBW));
        // int256 t_ij_transmit = ABDKMathQuad.toInt(ABDKMathQuad.div(
        //     ABDKMathQuad.fromInt(int256(tuple.nwLength * 1000)),
        //     ABDKMathQuad.mul(
        //         ABDKMathQuad.fromInt(int256(tuple.ueUpBW)), loggvalue
        //     )
        // ));
        // int256 t_ij_process = ABDKMathQuad.toInt(ABDKMathQuad.div(
        //     ABDKMathQuad.fromInt(int256(tuple.cpuLength * 1000)),
        //     ABDKMathQuad.fromInt(int256(server.mips))
        // ));
        uint t_ij_process = (1000000 * tuple.cpuLength) / server.mips;
        // console.log(t_ij_process);
        // bytes16 t_ij_offload = ABDKMathQuad.add(
        //     t_ij_transmit,
        //     t_ij_process
        // );
        uint t_ij_offload_norm = (t_ij_transmit + t_ij_process) / tuple.deadline;
        // console.log("offlloaddd : ", t_ij_offload_norm);
        uint e_ij_offload_norm = (t_ij_transmit * tuple.ueTransmissionPower * 100 
                            + t_ij_process * tuple.ueIdlePower) / 
                                        (tuple.deadline * (tuple.ueTransmissionPower * 100 + tuple.ueIdlePower));
        // console.log("energy offload: ", e_ij_offload_norm);
        // bytes16 ml = ABDKMathQuad.mul(
        //     t_ij_offload_norm, ABDKMathQuad.fromInt(1000)
        // );
        // int256 d = ABDKMathQuad.toInt(t_ij_offload_norm);
        //     ABDKMathQuad.mul(
        //         t_ij_offload_norm, ABDKMathQuad.fromInt(1000)
        //     )
        // )));
        // t_ij_transmit ==> input * 1000/(upload* 100 * log(1+((power*noisem1:A)/(distanceplus6:B))) ** 10)
        // n * log(x) ==> log x ** n??? 4 * log 2 ==> log 2 ** 4
        // 1 + a/b ==> (b+a)/b
        // log a/b ==> log a - log b
        // => log (A+B) - log B
        // t_ij_transmit ==> input / (upload * (log(power*noisem1 + distplus6) - log(distplus6)))
        // uint b = log2(34012224000000000002000000000000);
        uint pref = t_ij_offload_norm + e_ij_offload_norm + server.offer * 1000; // (server.offer/1000) * 1000000
        // console.log("server, tuple ID: ", server.name, tuple.id);
        // console.log("TUPLE PREFRENCE ON SERVER: ", pref);
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
        /*
            this value shows that how much the server likes to take the tuple
            this is used in serverPriorities
        */
        // int distplus2m1 = ((int256(tuple.xCoordinate) - int256(server.xCoordinate)) ** 2 
        //                 + (int256(tuple.yCoordinate) - int256(server.yCoordinate)) ** 2) ** 2;
        // return 1000000 + tuple.offer * 1000 + max * 2 / distplus2m1;
        int dist = ((int256(tuple.xCoordinate) - int256(server.xCoordinate)) ** 2 
                        + (int256(tuple.yCoordinate) - int256(server.yCoordinate)) ** 2);
        uint cost =  uint128(1000000 + tuple.offer * 1000 - 2357 * sqrt(uint(dist)));
        // 900 800 700 ...
        // console.log("***** SERVER COST ******");
        // console.log("SERver PREF: ", cost);
        return cost;
    }

    function auctionResultTuple(uint tupleID) public {
        /*
            this interface intends to return the response for the an auction
            inputs:     
                auction id
                ?
        */
        log("********************************* RESULT *******************");
        if (activeAuction.assingedTuplesMap[tupleID] == false) {
            log("calculating th result");
            calcAuctionResult(activeAuction, tupleID);
        } else {
            log("had result");
        }
        emit AuctionTupleResult(activeAuction.tupleResult[tupleID]);
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
            // log(auction.serverKeys[i] , tempServerQuta[auction.serverKeys[i]], auction.serverQuta[auction.serverKeys[i]]);
        }
        // uint tupleID = auction.mobileKeys[0]; // if not allocated
        //else break
        log("TEST");
        while (true) {
            log("tupleID: ", tupleID);
            while (true) {
                bool tupleNotAssigned = true;
                bool foundCircle = false;
                string memory circleStartServer = "";
                log("where it failds?");
                log(auction.serverKeys.length);
                log(auction.mobileKeys.length);
                for (uint i = 0; i < auction.serverKeys.length; i ++) {
                    // find the tuple => server? and then server? => tuple
                    log("before for loop tuple priorities ", tupleID, i);
                    log(auction.mobilePriorities[tupleID].length);
                    log(auction.mobilePriorities[tupleID][i].cost);
                    string memory serverName = auction.mobilePriorities[tupleID][i].name;
                    log("serverName: ", serverName);
                    uint tupleMips = auction.tupleRequireMips[serverName].tuples[tupleID];
                    log("req mips: ", tupleMips, tempServerQuta[serverName]);
                    if (tupleMips <= tempServerQuta[serverName]) { // servers does not exit the process at all!!! NOTE
                        // tuple is assinged to server
                        tempServerQuta[serverName] = tempServerQuta[serverName] - tupleMips;
                        log("new server quota after: ", tempServerQuta[serverName]);
                        tempTupleResult[tupleID] = serverName;
                        tupleNotAssigned = false;
                        // T0 => S1 => T?  => ... T =/ S T=>S=/T?
                        for (uint j = 0; j < auction.mobileKeys.length; j ++) { // No calc on if server is able to handle
                            // find the prefered tuple for server
                            // choose from not assinged tuples (real ones) Note
                            // 100 -> tuple
                            // server name_2 -> prefer tuple
                            // 0, ---- ?
                            // 0, 1, 2, 3, 
                            // 99 
                            uint perfTupleID = auction.serverPriorities[serverName][j].id;
                            if (activeAuction.assingedTuplesMap[perfTupleID] == false) {
                                auction.serverResult[serverName] = perfTupleID;
                                break;
                            }
                        }
                        log("trying to find circle");
                        string memory serverRounding = serverName;
                        while (true) {
                            // find out if a circle is created
                            // we check with old nodes NOTE
                            log("serverRounding: ", serverRounding);
                            if (auction.serverResult[serverRounding] != 0) {
                                log("tuple rounding: ", auction.serverResult[serverRounding]);
                                if (bytes(tempTupleResult[auction.serverResult[serverRounding]]).length > 0) {
                                    serverRounding = tempTupleResult[auction.serverResult[serverRounding]];
                                    log("compare", serverRounding, serverName);
                                    if (keccak256(abi.encodePacked((serverRounding))) == keccak256(abi.encodePacked((serverName)))) {
                                        log("was same");
                                        foundCircle = true;
                                        circleStartServer = serverName;
                                        break;
                                    }
                                } else break;
                            } else break;
                        }
                        log("foundCircle: ", foundCircle);
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
                    log("Assigning foundings here ==== ");
                    while (true) {
                        auction.tupleResult[tupleRoundingID] = tempTupleResult[tupleRoundingID];
                        auction.assingedTuples.push(tupleRoundingID);
                        auction.assingedTuplesMap[tupleRoundingID] = true;
                        log("ASSIGEND TUPLE: ", tupleRoundingID, auction.tupleResult[tupleRoundingID]);
                        uint tupleMips = auction.tupleRequireMips[tempTupleResult[tupleRoundingID]].tuples[tupleID];
                        auction.serverQuta[tempTupleResult[tupleRoundingID]] = auction.serverQuta[tempTupleResult[tupleRoundingID]] - tupleMips;
                        log("Temp Quta: ", tempTupleResult[tupleRoundingID], tempServerQuta[tempTupleResult[tupleRoundingID]]);
                        log("QUTA CHANGED: ", tupleMips, auction.serverQuta[tempTupleResult[tupleRoundingID]]);
                        if (keccak256(abi.encodePacked((tempTupleResult[tupleRoundingID]))) == keccak256(abi.encodePacked((circleStartServer)))) {
                            log("breaking the circle here");
                            break;
                        }
                        tupleRoundingID = auction.serverResult[tempTupleResult[tupleRoundingID]];
                    }
                    break;
                }
                if (tupleNotAssigned) {
                    // Tuple not assigned to any server
                    // Result T => !!
                    log(" TUPLE not assigned at all");
                    auction.assingedTuples.push(tupleID);
                    auction.assingedTuplesMap[tupleID] = true;
                    auction.tupleResult[tupleID] = "NOTFOUND";
                    break;
                }
                tupleID = auction.serverResult[tempTupleResult[tupleID]];
            }
            if (auction.assingedTuplesMap[initalTupleID]) {
                break;
            } else {
                log("INITIAL TUPLE WAS NOT ASSIGEND STARTING OVER");
                tupleID = initalTupleID;
            }
        }
    }

}