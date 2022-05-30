const AuctionManager = artifacts.require('AuctionManager.sol')

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

// tupleIds = []
// tupleNum = 30
// serverNum = 3

serverNumber = 5
tupleNumber = 10

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
    it('registers server nodes', async () => {
        serverName = 'name'
        for(j = 1; j < serverNumber + 1; j ++ ) {
            i = Math.floor(Math.random() * 11) + 10
            _name = serverName + '_' + j
            console.log('registering server: ' + _name)
            let stbalance = await web3.eth.getBalance(accounts[1], function(err, result) {
                if (err) {
                  console.log(err)
                } else {
                  console.log(web3.utils.fromWei(result, "ether") + " ETH")
                }
              })
            result = await this.manager.registerServerNode(
                _name, //name
                i * 10000, //mips
                 i * 10, // , x,
                i * 10, i     // y, offer
            )
            let endbalance = await web3.eth.getBalance(accounts[1])
            console.log("deeeeeeeeeeeeeeeeeeeeeeeeeeeee")
            console.log(typeof endbalance)
            console.log(await web3.eth.getTransactionReceipt(result.receipt.transactionHash))
            // console.log(stbalance.minus(endbalance))
            console.log(result)
            console.log(result.receipt)
            console.log('gas: ', result.receipt.gasUsed)
            console.log('block:::: ', result.receipt.blockNumber)
        }
    })
    it('registers mobile task', async () => {
        for (j = 1; j < tupleNumber + 1; j ++) {
            i = Math.floor(Math.random() * 11) + 10
            console.log('registering tuple: ' + j)
            result = await this.manager.registerMobileTask(
                j,
                i * 5000, // cpu length
                i * 1000, // nw length
                i, // output number
                i * 20, //deadline
                i, //offer
                i * 5000, // ue up bw
                i + 3, //x
                i + 15, //y
                i * 4, // ue trans powerr
                i, // ue idle power (1-10000)
            )
            console.log('gas: ', result.receipt.gasUsed)
            console.log('block:::: ', result.receipt.blockNumber)
        }
    })

    it('create tuple required mips', async () => {
        for (j = 1; j < tupleNumber + 1; j ++) {
            console.log('create req mips for tuple: ' + j)
            result = await this.manager.createTupleRequireMips(
                j,
            )
            console.log('gas: ', result.receipt.gasUsed)
            console.log('block:::: ', result.receipt.blockNumber)
        }
    })
    it('create tuple priorities', async () => {
        for (j = 1; j < tupleNumber + 1; j ++) {
            console.log('create priorities for tuple: ' + j)
            result = await this.manager.createTuplePriorities(
                j,
            )
            console.log('gas: ', result.receipt.gasUsed)
            console.log('block:::: ', result.receipt.blockNumber)
        }
    })
    it('create server priorities', async () => {
        serverName = 'name'
        for(j = 1; j < serverNumber + 1; j ++ ) {
            _name = serverName + '_' + j
            console.log('create server priority for: ' + _name)
            result = await this.manager.createServerPriorities(
                _name,
            )
            console.log('gas: ', result.receipt.gasUsed)
            console.log('block:::: ', result.receipt.blockNumber)
        }
    })
    it('auction result', async () => {
        for (j = 1; j < tupleNumber + 1; j ++) {
            console.log('FOUDING RESULT FOR TUPLE ID: ', j)
            result = await this.manager.auctionResultTuple(j)
            console.log('gas: ', result.receipt.gasUsed)
            console.log('block:::: ', result.receipt.blockNumber)
        }

    })
})
