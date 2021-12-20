const AuctionManager = artifacts.require('AuctionManager.sol')

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

tupleIds = []
tupleNum = 1
serverNum = 1

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
    })

    it('registers mobile task', async () => {
        for (i = 1; i < tupleNum + 1; i ++) {
            tupleIds.push(i)
            console.log('registering tuple: ' + i)
            result = await this.manager.registerMobileTask(
                i,
                i, // cpu length
                i, // nw length
                i, // pes number
                i, // output number
                i, // deadline
                i, //offer
                i, // ue up bw
            )
            // evnt = result.logs[0].args
            // assert.equal(i + 1, evnt.biddersCount.toNumber())
            // console.log('auction: ', evnt.auctionID.toNumber())
            // console.log('bidders: ', evnt.biddersCount.toNumber())
            console.log('gas: ', result.receipt.gasUsed)
        }
    })

    it('registers server nodes', async () => {
        serverName = 'name'
        for(i = 1; i < serverNum + 1; i ++ ) {
            _name = serverName + '_' + i
            console.log('registering server: ' + _name)
            result = await this.manager.registerServerNode(
                _name, i, // name, busy power
                i, i, // down bw, idle power
                i, i * 100, i, // level, mips, ram
                i, // rate per mips
                i, i, // up link latency, area id
                i, i, // join delay, x,
                i, i     // y, offer
            )
            // evnt = result.logs[0].args
            // assert.equal(i + 1, evnt.biddersCount.toNumber())
            // console.log('auction: ', evnt.auctionID.toNumber())
            // console.log('bidders: ', evnt.biddersCount.toNumber())
            console.log('gas: ', result.receipt.gasUsed)
        }
    })
    it('registers mobile task', async () => {
        for (i = tupleNum + 1; i < tupleNum + tupleNum; i ++) {
            tupleIds.push(i)
            console.log('registering tuple: ' + i)
            result = await this.manager.registerMobileTask(
                i,
                i, // cpu length
                i, // nw length
                i, // pes number
                i, // output number
                i, //deadline
                i, //offer
                i, // ue up bw
            )
            // evnt = result.logs[0].args
            // assert.equal(i + 1, evnt.biddersCount.toNumber())
            // console.log('auction: ', evnt.auctionID.toNumber())
            // console.log('bidders: ', evnt.biddersCount.toNumber())
            console.log('gas: ', result.receipt.gasUsed)
        }
    })
    it('registers server nodes', async () => {
        serverName = 'name'
        for(i = serverNum + 1; i < serverNum + serverNum; i ++ ) {
            _name = serverName + '_' + i
            console.log('registering server: ' + _name)
            result = await this.manager.registerServerNode(
                _name, i, // name, busy power
                i, i, // down bw, idle power
                i, i * 100, i, // level, mips, ram
                i, // rate per mips
                i, i, // up link latency, area id
                i, i, // join delay, x 
                i, i // y, offer
            )
            // evnt = result.logs[0].args
            // assert.equal(i + 1, evnt.biddersCount.toNumber())
            // console.log('auction: ', evnt.auctionID.toNumber())
            // console.log('bidders: ', evnt.biddersCount.toNumber())
            console.log('gas: ', result.receipt.gasUsed)
        }
    })

    it('auction result', async () => {
        for (j = 0; j < tupleIds.length; j ++) {
            console.log()
            console.log('FOUDING RESULT FOR TUPLE ID: ', tupleIds[j])
            result = await this.manager.auctionResultTuple(1, tupleIds[j])
            // for (i = 0; i < result.logs.length; i ++) {
            //     console.log(i)
            //     console.log(result.logs[i].args)
            // }
            console.log('gas: ', result.receipt.gasUsed)
        }

    })
})
