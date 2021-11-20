// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

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
        int number,
        string text,
        bool b
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
        emit MobileTaskRegistered(id, activeAuction, auctions[activeAuction].mobileKeys.length);
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
        emit ServerNodeRegistered(name, activeAuction, auctions[activeAuction].serverKeys.length);
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