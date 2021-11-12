
const TodoList = artifacts.require('TodoList.sol')

contract('Todo list test', (accounts) => {
    before(async() => {
        this.todoList = await TodoList.deployed()
    })

    it('deployed successfully', async () => {
        address = await this.todoList.address
        assert.notEqual(address, 0x0)
        assert.notEqual(address, '')
        assert.notEqual(address, null)
        assert.notEqual(address, undefined)
    })

    it('list tasks', async () => {
        taskCount = await this.todoList.taskCount()
        task = await this.todoList.tasks(taskCount)
        assert.equal(task.id.toNumber(), taskCount.toNumber())
        assert.equal(task.completed, false)
    })

    it('create tasks', async () => {
        content = 'my new task'
        for (i = 0; i < 4; i ++) {
            _content = content + i
            result = await this.todoList.createTask(_content)
            evn = result.logs[0].args
            assert.equal(evn.content, _content)
            console.log(evn.timestamp.toNumber())
            console.log('gas used for create new task: ', result.receipt.gasUsed)
        }
    })

    it('finish task', async () => {
        taskCount = await this.todoList.taskCount()
        result = await this.todoList.completeTask(taskCount)
        evn = result.logs[0].args
        assert.equal(evn.completed, true)
        console.log('gas used for complete task: ', result.receipt.gasUsed)
    })

})