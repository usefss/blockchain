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

    }

    struct MobileTask {
        uint id;

        uint cpuLength;
        uint nwLength;
        uint pesNumber;
        uint outputSize;
    }

    struct Auction {
        uint startTime; // init with block.timestamp

        uint lastMobileNode; // init with 0
        uint lastServerNode; // init with 0

        uint[] mobileKeys;
        mapping(uint => MobileTask) mobileTasks;

        string[] serverKeys;
        mapping(string => ServerNode) serverNodes;
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
        uint id, uint cpuLength, uint nwLength, uint pesNumber, uint outputSize
    ) public {
        // we does not check if this task is already registered in active autcion
        requestAuction();
        auctions[activeAuction].mobileTasks[id] = MobileTask(
            id, cpuLength, nwLength, pesNumber, outputSize
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
        uint joinDelay
    ) public {
        // we does not check if this name already is registered in this auction
        requestAuction();
        auctions[activeAuction].serverNodes[name] = ServerNode(
            name, busyPower, downBw, idlePower, level,
            mips, ram, ratePerMips, upLinkLatency, areaId,
            joinDelay
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