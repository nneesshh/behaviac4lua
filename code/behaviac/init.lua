--- Behaviac Lib
-- @module lib_behaviac
-- @author n.lee
-- @copyright 2016
-- @license MIT/X11

local lib_behaviac = {
	_LICENSE     = "MIT/X11",
	_URL         = "http://",
	_VERSION     = "1.0.0.1",
	_DESCRIPTION = "Behaviac Lib...",
	cache        = {},
}

-- Localize
local cwd = (...):gsub('%.[^%.]+$', '') .. "."

require("utils.functions")
require(cwd .. "macros")

-- Module
local _M = lib_behaviac
_M.enums = require(cwd .. "enums")
_M.BaseAgent = require(cwd .. "agent.BaseAgent")
_M.AgentMeta = require(cwd .. "agent.AgentMeta")
_M.BehaviorTreeFactory = require(cwd .. "parser.BehaviorTreeFactory")
_M.NodeFactory = require(cwd .. "parser.NodeFactory")

return _M