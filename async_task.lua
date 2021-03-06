---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by seancheey.
--- DateTime: 10/7/20 10:13 PM
---

--- @type MinHeap
local MinHeap = require("minheap")

--- @class AsyncTaskManager
--- @field taskQueue MinHeap
local AsyncTaskManager = {}

--- @return AsyncTaskManager
function AsyncTaskManager:new()
    local o = setmetatable({}, { __index = AsyncTaskManager })
    o.taskQueue = MinHeap.new()
    return o
end

--- @field taskFunction fun()
--- @field priority number optional, the low the priority = at more front of the task queue
function AsyncTaskManager:pushTask(taskFunction, priority)
    assert(type(taskFunction) == "function")
    self.taskQueue:push(priority or 1, taskFunction)
end

function AsyncTaskManager:removeAllTasks()
    while not self.taskQueue:isEmpty() do
        self.taskQueue:pop()
    end
end

function AsyncTaskManager:resolveTaskEveryNthTick(nthTick)
    script.on_nth_tick(nthTick, function()
        self:resolveOneTask();
    end)
end

function AsyncTaskManager:resolveOneTask()
    if not self.taskQueue:isEmpty() then
        local task = self.taskQueue:pop().val
        task()
    end
end

return AsyncTaskManager