
local b = require "behaviac"
--local p = require "presstest"
--local msg_dispatcher = require ("presstest.MessageDispatcher")
--local pressTestManager = require ("presstest.PressTestManager")--p.PressTestManager
local EBTStatus = b.enums.EBTStatus
local AgentMeta = b.AgentMeta

local MyRobotClass = class("Robot", b.BaseAgent)

function MyRobotClass:ctor(unit)
    dump(unit, "unit")
    MyRobotClass.super.ctor(self)
    self.unit = unit
end

function MyRobotClass:doLogin()
    print("Do Login ...")
    msg_dispatcher.registerMessageCb()
    pressTestManager.startTest(1)--(testNumMax)
    return EBTStatus.BT_RUNNING
end

function MyRobotClass:doFarm()
    print("Do Farm ...")
    --msg_dispatcher.sendUserDungeonService(self.unit, {cmd = 1, dungeon_id = 0})
    --msg_dispatcher.sendUserNavigationService(self.unit, {cmd = 1})
    return EBTStatus.BT_SUCCESS
    -- return p.MessageDispatcher.state
end

function MyRobotClass:doNext()
    print("Do Next ...")
    return EBTStatus.BT_SUCCESS
end

function MyRobotClass:doLinger()
    return EBTStatus.BT_RUNNING
end

function MyRobotClass:SayHello(msg)
    print("SayHello: ")
    print(msg)
end

function MyRobotClass:Say(msg)
    print("Say: ")
    print(msg)
end

function MyRobotClass:getDungeonPreTask()
    return 123456
end

function MyRobotClass:doTask(taskId)
    print(taskId)
    return EBTStatus.BT_SUCCESS
end

function MyRobotClass:doLogPlayerInfo(param1, param2)
    print(param1)
    print(param2)
    return EBTStatus.BT_SUCCESS
end

assert(nil == _M)
----------------------------------------------------------------
local myRobot = MyRobotClass.new()
AgentMeta.setBehaviorTreeFolder("./lua/data/")
--local path = AgentMeta.getBehaviorTreePath("PressTest")
local path = AgentMeta.getBehaviorTreePath("LoopBT")
--local path = AgentMeta.getBehaviorTreePath("SelectBT")
--local path = AgentMeta.getBehaviorTreePath("SequenceBT")
--local path = AgentMeta.getBehaviorTreePath("InstanceBT")
--local path = AgentMeta.getBehaviorTreePath("ParentBT")
local path_main = AgentMeta.getBehaviorTreePath("maintree")
local path_sub = AgentMeta.getBehaviorTreePath("subtree")
local path_maintree_task = AgentMeta.getBehaviorTreePath("maintree_task")
local path_subtree_task = AgentMeta.getBehaviorTreePath("subtree_task")

local path_LoopBattleBT = AgentMeta.getBehaviorTreePath("LoopBattleBT")
myRobot:btSetCurrent(path_LoopBattleBT)

local loopCount = 3
for i= 1, loopCount do
    print('-----------------------start-----------------------', i)
    myRobot:btExec()
    print('end', '----------------------------------------------', i)
end

print('---- ---- fire event... ---- ----')
myRobot:fireEvent("event_task", 2)
--myRobot:btExec()