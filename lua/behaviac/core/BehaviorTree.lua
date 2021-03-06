--- Behaviac lib Component: behavior tree.
-- @module BehaviorTree.lua
-- @author n.lee
-- @copyright 2016
-- @license MIT/X11

-- Localize
local pdir = (...):gsub('%.[^%.]+%.[^%.]+$', '') .. "."
local cwd = (...):gsub('%.[^%.]+$', '') .. "."
local enums = require(pdir .. "enums")
local common = require(pdir .. "common")

local EBTStatus                 = enums.EBTStatus
local ENodePhase                = enums.ENodePhase
local EPreconditionPhase        = enums.EPreconditionPhase
local TriggerMode               = enums.TriggerMode
local EOperatorType             = enums.EOperatorType

local constSupportedVersion     = enums.constSupportedVersion
local constInvalidChildIndex    = enums.constInvalidChildIndex
local constBaseKeyStrDef        = enums.constBaseKeyStrDef
local constPropertyValueType    = enums.constPropertyValueType
local constBsonElementType      = enums.constBsonElementType

local Logging                   = common.d_log
local StringUtils               = common.StringUtils

-- Class
local SingleChild = require(cwd .. "SingleChild")
local BehaviorTree = class("BehaviorTree", SingleChild)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("BehaviorTree", BehaviorTree)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("BehaviorTree", "SingleChild")
local _M = BehaviorTree

local NodeParser = require(pdir .. "parser.NodeParser")
local NodeLoader = require(pdir .. "parser.NodeLoader")

local AgentMeta = require(pdir .. "agent.AgentMeta")
local bson = require(pdir .. "external.bson")
local BsonNodeLoader = require(pdir .. "parser.BsonNodeLoader")

local debugger = require(pdir .. "debugger")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)
    
    self.m_name          = ""
    self.m_relativePath  = ""
    self.m_domains       = ""
    self.m_bIsFSM        = false
    self.m_localProps    = {}
end

function _M:release()
    _M.super.release(self)
end

function _M:onLoading(version, agentType, properties)
    _M.super.onLoading(self, version, agentType, properties)

    local nameStr, valueStr
    for _, p in ipairs(properties) do
        nameStr = p[1]
        valueStr = p[2]

        if nameStr == constBaseKeyStrDef.kStrDomains then
            self.m_domains = valueStr
        elseif nameStr == constBaseKeyStrDef.kStrDescriptorRefs then
            -- do nothing
        else
            -- do nothing
        end
    end
end

function _M:getName()
    return self.m_name
end

function _M:setName(name)
    self.m_name = name
end

function _M:getRelativePath()
    return self.m_relativePath
end

function _M:setRelativePath(path)
    self.m_relativePath = path
end

function _M:getDomains()
    return self.m_domains
end

function _M:setDomains(domains)
    self.m_domains = domains
end

function _M:isFSM()
    return self.m_bIsFSM
end

function _M:loadBson(bsonTreeData, behaviorTreePath)
    -- behavior node
    local etype, nextPos = bson.readByte(bsonTreeData, 1)
    if constBsonElementType.BT_BehaviorElement ~= etype then
        Logging.error("[_M:loadBson()] file(%s) is invalid!!!", behaviorTreePath)
        return
    end

    local docLen, name, agentType, bFsm, version
    docLen, nextPos = bson.readInt32(bsonTreeData, nextPos)
    name, nextPos = bson.readString(bsonTreeData, nextPos)
    agentType, nextPos = bson.readString(bsonTreeData, nextPos)
    bFsm, nextPos = bson.readBool(bsonTreeData, nextPos)
    version, nextPos = bson.readString(bsonTreeData, nextPos)

    behaviorTreePath = behaviorTreePath or AgentMeta.getBehaviorTreePath(name)

    self:setName(name)
    self:setRelativePath(behaviorTreePath)
    self:setClassNameString("BehaviorTree")
    self:setId(-1)

    self.m_bIsFSM = bFsm

    --
    nextPos = BsonNodeLoader.loadPropertiesParsAttachmentsChildren(self, version, agentType, bsonTreeData, nextPos, false)
    return true
end

function _M:load(treeData, behaviorTreePath)
    -- behavior node
    local behaviorEntry = treeData[constBaseKeyStrDef.kStrBehavior]
    if not behaviorEntry then
        Logging.error("[_M:load()] file(%s) is invalid!!!", behaviorTreePath)
        return
    end

    local name = behaviorEntry[constBaseKeyStrDef.kStrName]
    local agentType = behaviorEntry[constBaseKeyStrDef.kStrAgentType]
    local version = tonumber(behaviorEntry[constBaseKeyStrDef.kStrVersion]) or 0

    behaviorTreePath = behaviorTreePath or AgentMeta.getBehaviorTreePath(name)

    self:setName(name)
    self:setRelativePath(behaviorTreePath)
    self:setClassNameString("BehaviorTree")
    self:setId(-1)

    if behaviorEntry["fsm"] == "true" then
        self.m_bIsFSM = true
    end

    --
    NodeLoader.loadPropertiesParsAttachmentsChildren(self, version, agentType, behaviorEntry)
    return true
end

function _M:isManagingChildrenAsSubTrees()
    return true
end

function _M:isBehaviorTree()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:init(tick)
    _M.super.init(self, tick)

    self:instantiatePars(tick)
end

-- for debugger
local function _onEnterDebug(node, agent, tick)
    debugger.lib.logJumpTree(agent, node:getName())
    return true
end

local function _onEnter(node, agent, tick)
    return true
end

-- for debugger
local function _onExitDebug(node, agent, tick, status)
    debugger.lib.logReturnTree(agent, node:getName())
    return _M.super.onExit(node, agent, status)
end

local function _onExit(node, agent, tick, status)
    return _M.super.onExit(node, agent, status)
end

-- impl: [ onEnter, onExit ]
if debugger.enable_debugger then
    _M.onEnter = _onEnterDebug
    _M.onExit = _onExitDebug
else
    _M.onEnter = _onEnter
    _M.onExit = _onExit
end

function _M:updateCurrent(agent, tick, childStatus)
    _G.BEHAVIAC_ASSERT(self:isBehaviorTree(), "[_M:updateCurrent()] isBehaviorTree failed")
    if self:isFSM() then
        return self:update(agent, tick, childStatus)
    else
        return _M.super.updateCurrent(self, agent, tick, childStatus)
    end
end

function _M:update(agent, tick, childStatus)
    _G.BEHAVIAC_ASSERT(self.m_root, "[_M:update()] self.m_root is false")

    if childStatus ~= EBTStatus.BT_RUNNING then
        return childStatus
    end

    local status = EBTStatus.BT_INVALID
    self:setEndStatus(tick, EBTStatus.BT_INVALID)

    status = _M.super.update(self, agent, tick, childStatus)
    _G.BEHAVIAC_ASSERT(status ~= EBTStatus.BT_INVALID, "[_M:update()] status == EBTStatus.BT_INVALID")
    
    -- When the End node takes effect, it always returns BT_RUNNING
    -- and m_endStatus should always be BT_SUCCESS or BT_FAILURE
    local endStatus = self:getEndStatus(tick)
    if status == EBTStatus.BT_RUNNING and endStatus ~= EBTStatus.BT_INVALID then
        tick:endDo(self, agent, endStatus)
        return endStatus
    end

    return status
end

function _M:resume(agent, tick, status)
    return _M.super.resumeBranch(self, agent, tick, status)
end

function _M:instantiatePars(tick)
    if #self.m_localProps > 0 then
        tick:addLocalVariables(self.m_localProps)
    end
end

function _M:setEndStatus(tick, status)
    tick:setNodeMem("endStatus", status, self)
end

function _M:getEndStatus(tick)
    return tick:getNodeMem("endStatus", self)
end

return _M