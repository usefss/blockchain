const AuctionManager = artifacts.require('AuctionManager.sol')

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

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

    // it('test', async () => {
    //     await this.manager.requestAuction()
    //     await sleep(11000)
    //     res = await this.manager.isAuctionEnded(1)
    //     console.log(res.logs[0].args.text)
    //     console.log(res.logs[0].args.number.toNumber())

    // })

    it('registers mobile task', async () => {
        for (i = 0; i < 10; i ++) {
            result = await this.manager.registerMobileTask(
                i,
                i, // cpu length
                i, // nw length
                i, // pes number
                i, // output number
                i, //offer
            )
            evnt = result.logs[0].args
            assert.equal(i + 1, evnt.biddersCount.toNumber())
            console.log('auction: ', evnt.auctionID.toNumber())
            console.log('bidders: ', evnt.biddersCount.toNumber())
            console.log('gas: ', result.receipt.gasUsed)
        }
    })

    it('registers server nodes', async () => {
        serverName = 'name'
        for(i = 0; i < 10; i ++ ) {
            _name = serverName + '_' + i
            result = await this.manager.registerServerNode(
                _name + i, i, // name, busy power
                i, i, // down bw, idle power
                i, i, i, // level, mips, ram
                i, // rate per mips
                i, i, // up link latency, area id
                i, i // join delay, offer
            )
            evnt = result.logs[0].args
            assert.equal(i + 1, evnt.biddersCount.toNumber())
            console.log('auction: ', evnt.auctionID.toNumber())
            console.log('bidders: ', evnt.biddersCount.toNumber())
            console.log('gas: ', result.receipt.gasUsed)
        }
    })

    it('register after some time', async () => {
        await sleep(5000)
        result = await this.manager.registerMobileTask(
            669,
            669, // cpu length
            669, // nw length
            669, // pes number
            669, // output number
            669, // offer
        )
        evnt = result.logs[0].args
        assert.equal(1, evnt.biddersCount.toNumber())
        console.log('auction: ', evnt.auctionID.toNumber())
        console.log('bidders: ', evnt.biddersCount.toNumber())
        console.log('gas: ', result.receipt.gasUsed)
    })

})
