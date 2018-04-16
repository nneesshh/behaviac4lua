--- Behaviac lib Component: prototype wrapper.
-- @module PrototypeAdapter.lua
-- @author n.lee
-- @copyright 2016
-- @license MIT/X11

-- Localize
local pdir = (...):gsub('%.[^%.]+%.[^%.]+$', '') .. "."
local cwd = (...):gsub('%.[^%.]+$', '') .. "."

local enums = require(pdir .. "enums")

-- Class
local PrototypeAdapter = class("PrototypeAdapter")
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("PrototypeAdapter", PrototypeAdapter)
local _M = PrototypeAdapter

local ParamAdapter = require(cwd .. "ParamAdapter")

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    self.prototypeName    = false
    self.paramProperties  = {}
end

function _M:setTaskParams(agent, tick, subTreeTick)
    local params = {}
    for i, paramProp in ipairs(self.paramProperties) do
        local paramName = enums.BEHAVIAC_LOCAL_TASK_PARAM_PRE .. tostring(i - 1)
        table.insert(params, { paramName, paramProp:getValue(agent, tick) })
    end
    if not subTreeTick then
      print("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
      assert(false)
    end
    return subTreeTick:addLocalVariables(params)
end

function _M:buildTaskPrototype(prototypeName, paramStr)
    self.prototypeName    = prototypeName
    self.paramProperties  = ParamAdapter.s_createParamProperties(paramStr)
end

return _M