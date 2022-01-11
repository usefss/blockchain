const AuctionManager = artifacts.require('AuctionManager.sol')

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

tupleIds = []
tupleNum = 30
serverNum = 3

contract('Auction manager test', (accounts) => {
    before(async() => {
        this.manager = await AuctionManager.deployed()
    })

    it('deployed successfully', async () => {
        address = await this.manager.address
        assert.notEqual(address, 0x0)
        assert.notEqual(address, '')
        assert.notEqual(address, null)
        assert.notEqual(address, undefined)

        r = await this.manager.Test()
        console.log(r.logs[0])
        console.log(r.receipt.gasUsed)
    })
    it('registers server nodes', async () => {
        serverName = 'name'
        for(j = 1; j < serverNum + 1; j ++ ) {
            i = Math.floor(Math.random() * 11) + 10
            _name = serverName + '_' + j
            console.log('registering server: ' + _name)
            result = await this.manager.registerServerNode(
                _name, //name
                //  i, //  busy power
                // i, i, // down bw, idle power
                // i, //  level
                i * 10000, //mips
                //  i, //, ram
                // i, // rate per mips
                // i,//up link latency
                //  i, // , area id
                // i, // join delay
                 i * 10, // , x,
                i * 10, i     // y, offer
            )
            // evnt = result.logs[0].args
            // assert.equal(i + 1, evnt.biddersCount.toNumber())
            // console.log('auction: ', evnt.auctionID.toNumber())
            // console.log('bidders: ', evnt.biddersCount.toNumber())
            console.log('gas: ', result.receipt.gasUsed)
        }
    })
    it('registers mobile task', async () => {
        for (j = 1; j < tupleNum + 1; j ++) {
            i = Math.floor(Math.random() * 11) + 10
            console.log(j, i)
            tupleIds.push(j)
            console.log('registering tuple: ' + i)
            result = await this.manager.registerMobileTask(
                j,
                i * 5000, // cpu length
                i * 1000, // nw length
                // i, // pes number
                i, // output number
                i * 20, //deadline
                i, //offer
                i * 5000, // ue up bw
                i + 3, //x
                i + 15, //y
                i * 4, // ue trans powerr
                i, // ue idle power (1-10000)
            )
            // evnt = result.logs[0].args
            // assert.equal(i + 1, evnt.biddersCount.toNumber())
            // console.log('auction: ', evnt.auctionID.toNumber())
            // console.log('bidders: ', evnt.biddersCount.toNumber())
            console.log('gas: ', result.receipt.gasUsed)
            // console.log(result.logs.length)
            // console.log(result.logs[0])
        }
    })

    
    // it('registers mobile task', async () => {
    //     for (i = tupleNum + 1; i < tupleNum + tupleNum; i ++) {
    //         tupleIds.push(i)
    //         console.log('registering tuple: ' + i)
    //         result = await this.manager.registerMobileTask(
    //             i,
    //             i, // cpu length
    //             i * 1000, // nw length
    //             i, // pes number
    //             i, // output number
    //             i, //deadline
    //             i, //offer
    //             i * 5000, // ue up bw
    //             i, //x
    //             i, //y
    //             i * 4, // ue trans powerr
    //         )
    //         // evnt = result.logs[0].args
    //         // assert.equal(i + 1, evnt.biddersCount.toNumber())
    //         // console.log('auction: ', evnt.auctionID.toNumber())
    //         // console.log('bidders: ', evnt.biddersCount.toNumber())
    //         console.log('gas: ', result.receipt.gasUsed)
    //     }
    // })
    // it('registers server nodes', async () => {
    //     serverName = 'name'
    //     for(i = serverNum + 1; i < serverNum + serverNum; i ++ ) {
    //         _name = serverName + '_' + i
    //         console.log('registering server: ' + _name)
    //         result = await this.manager.registerServerNode(
    //             _name, i, // name, busy power
    //             i, i, // down bw, idle power
    //             // i, //  level
    //             i * 100, i, //, mips, ram
    //             // i, // rate per mips
    //             i,//up link latency
    //             //  i, // , area id
    //             // i, // join delay
    //             i, // , x,
    //             i, i     // y, offer
    //         )
    //         // evnt = result.logs[0].args
    //         // assert.equal(i + 1, evnt.biddersCount.toNumber())
    //         // console.log('auction: ', evnt.auctionID.toNumber())
    //         // console.log('bidders: ', evnt.biddersCount.toNumber())
    //         console.log('gas: ', result.receipt.gasUsed)
    //     }
    // })

    it('auction result', async () => {
        for (j = 0; j < tupleIds.length; j ++) {
            console.log()
            console.log('FOUDING RESULT FOR TUPLE ID: ', tupleIds[j])
            result = await this.manager.auctionResultTuple(tupleIds[j])
            // for (i = 0; i < result.logs.length; i ++) {
            //     console.log(i)
            //     console.log(result.logs[i].args)
            // }
            console.log('gas: ', result.receipt.gasUsed)
        }

    })
})
