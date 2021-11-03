// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract TodoList {
    uint public taskCount = 0;

    struct Task {
        uint id;
        string content;
        bool completed;
    }

    mapping(uint => Task) public tasks;

    constructor() public {
        createTask("check out default task");
    }

    event TaskCreated(
        uint id,
        string content,
        bool completed,
        uint timestamp
    );

    event TaskCompleted(
        uint id,
        bool completed
    );

    function createTask(string memory _content) public {
        taskCount++;
        tasks[taskCount] = Task(taskCount,_content,false);
        emit TaskCreated(taskCount, _content, false, block.timestamp);
        // for (uint i = 0; i < taskCount * 1000; i ++) {
        //     uint t = i * i;
        //     t = t + t;
        // }

    }

    function completeTask(uint _id) public {
        Task memory _task = tasks[_id];
        _task.completed = true;
        tasks[_id] = _task;
        emit TaskCompleted(_id, true);
    }
}