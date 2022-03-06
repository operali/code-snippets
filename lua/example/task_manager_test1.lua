
--- author: operali 2022-03-06
--- desc: example of task_manager

local tmlib = require('lib.task_manager')

local wait = tmlib.wait
local tm = tmlib.getTaskManager()

function task1()
    local c = 0;
    while true do
        c = c+1
        if c > 5 then
            error("fail from task1")
        end
        wait(1)
        print('tick from task1')
    end
end

function task2()
    for i = 1, 5 do
        wait(0.5)
        print('tick from task2')
    end
end

function task()
    print('task start')
    tm.launch(task1, "task1")
    tm.launch(task2, "task2")
end

tm.launch(task, "task")

tm.start();
