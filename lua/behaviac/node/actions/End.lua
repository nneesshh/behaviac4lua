--- Behaviac lib Component: end action node.
-- @module End.lua
-- @author n.lee
-- @copyright 2016
-- @license MIT/X11

-- Localize
local ppdir = (...):gsub('%.[^%.]+%.[^%.]+%.[^%.]+$', '') .. "."
local cwd = (...):gsub('%.[^%.]+$', '') .. "."
local enums = require(ppdir .. "enums")
local common = require(ppdir .. "common")

local EBTStatus                 = enums.EBTStatus
local ENodePhase                = enums.ENodePhase
local EPreconditionPhase        = enums.EPreconditionPhase
local TriggerMode               = enums.TriggerMode
local EOperatorType             = enums.EOperatorType

local constSupportedVersion     = enums.constSupportedVersion
local constInvalidChildIndex    = enums.constInvalidChildIndex
local constBaseKeyStrDef        = enums.constBaseKeyStrDef
local constPropertyValueType    = enums.constPropertyValueType

local Logging                   = common.d_log
local StringUtils               = common.StringUtils

-- Class
-- The behavior tree return success or failure.
local Leaf = require(ppdir .. "core.Leaf")
local Cls_End = class("End", Leaf)
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("End", Cls_End)
_G.BEHAVIAC_DECLARE_DYNAMIC_TYPE("End", "Leaf")
local _M = Cls_End

local NodeParser = require(ppdir .. "parser.NodeParser")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    _M.super.ctor(self)

    self.m_end_status_p   = false
    self.m_end_outside_p  = false
end

function _M:release()
    _M.super.release()
    
    self.m_end_status_p   = false
    self.m_end_outside_p  = false
end

function _M:onLoading(version, agentType, properties)
    _M.super.onLoading(self, version, agentType, properties)

    local nameStr, valueStr
    for _, p in ipairs(properties) do
        nameStr = p[1]
        valueStr = p[2]

        if nameStr == "EndStatus" then
            if StringUtils.isValidString(valueStr) then
                local pParenthesis = string.find(valueStr, '%(')

                if not pParenthesis then                    
                    self.m_end_status_p = NodeParser.parseProperty(valueStr)
                else
                    self.m_end_status_p = NodeParser.parseMethod(valueStr)
                end
            end
        elseif nameStr == "EndOutside" then
            self.m_end_outside_p = (valueStr == "true")
        end
    end
end

function _M:getStatus(agent, tick)
    if self.m_end_status_p then
        local status = self.m_end_status_p:getValue(agent, tick)
        -- _G.BEHAVIAC_ASSERT(status == EBTStatus.BT_SUCCESS or status == EBTStatus.BT_FAILURE, "[_M:getStatus()] status must be BT_SUCCESS BT_FAILURE")
        return status
    else
        return EBTStatus.BT_SUCCESS
    end
end

function _M:getEndOutside()
    return self.m_end_outside_p
end

function _M:isEnd()
    return true
end

--------------------------------------------------------------------------------
-- Blackboard:
--------------------------------------------------------------------------------

function _M:onEnter(agent, tick)
    return true
end

function _M:onExit(agent, tick, status)
end

function _M:update(agent, tick, childStatus)
    local root = nil

    local status = EBTStatus.BT_SUCCESS

    if self:getEndOutside() then
        root = self:getRoot()
    elseif agent then
        root = tick:getBt()
    end

    if root then
        status = self:getStatus(agent)
        root:setEndStatus(agent, status)
    end

    return status
end

return _M