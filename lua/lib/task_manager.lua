
--- author: operali 2022-03-06
--- desc: implement of mulitiple asyn tasks executor 


---@class Task
---@field name string @ task name
---@field thread Thread @ task coroutine
---@field async AsyncAction
--- 
---@class TaskManager
---@field _waits Task[]
---@field _readys Task[]
---@field launch fun(task:any)
---@field update fun():boolean
---@field start fun()
---
---@class AsyncAction
---@field __async boolean
---@field respond fun(requestVal):any
---@field isReady fun():boolean
---@field requestVal any
---@field respondVal any
---
---@type TaskManager
local _gTaskManager = nil

---@return TaskManager
local function getTaskManager()
    if _gTaskManager ~= nil then return _gTaskManager; end

    _gTaskManager = {}
    _gTaskManager._waits = {}
    _gTaskManager._readys = {}
    function _gTaskManager.launch(action, name)
        ---@type Task
        local task = {}
        task.name = name or "unknown"
        task.thread = coroutine.create(action)
        table.insert(_gTaskManager._waits, task);
    end
    function _gTaskManager.start()
        while true do if _gTaskManager.update() then break end end
    end
    function _gTaskManager.update()
        local waits = _gTaskManager._waits;
        _gTaskManager._waits = {}
        
        for _, task in ipairs(waits) do
            if not task.async then
                table.insert(_gTaskManager._readys, task);
            elseif task.async.isReady() then
                table.insert(_gTaskManager._readys, task);
            else
                -- those no finished
                table.insert(_gTaskManager._waits, task);
            end
        end

        local readys = _gTaskManager._readys;
        _gTaskManager._readys = {}

        for _, task in ipairs(readys) do
            local rsp = nil;
            if task.async then rsp = task.async.respondVal; end
            local succ, ret = coroutine.resume(task.thread, rsp);
            local st = coroutine.status(task.thread)
            if succ then
                if st == 'dead' then
                    print('-----------finish task: ' .. task.name)
                else
                    if ret and ret['__async'] == true then
                        task.async = ret;
                        table.insert(_gTaskManager._waits, task);
                    else
                        task.async = nil;
                        table.insert(_gTaskManager._waits, task);
                    end
                end
            else
                print('-----------fail to finish task: ' .. task.name .. '\n' .. ret)
            end
        end
        -- there are no more tasks in waiting or running list
        if #_gTaskManager._waits == 0 and #_gTaskManager._readys == 0 then
            print('-----------all task are finished')
            return true;
        end
        return false;
    end

    return _gTaskManager;
end

---@param last number
---@return AsyncAction
local function wait(last)
    ---@type AsyncAction
    local waitAction = {}
    waitAction.__async = true;
    local now = os.clock();
    local till = now + last
    waitAction.isReady = function()
        local now = os.clock();
        if till <= now then return true; end
        return false
    end
    coroutine.yield(waitAction)
end

return {
    wait = wait,
    getTaskManager = getTaskManager
}
