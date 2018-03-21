--- Behaviac lib Component: behavior tree factory.
-- @module BehaviorTreeFactory.lua
-- @author n.lee
-- @copyright 2016
-- @license MIT/X11

local _M = {}

-- Localize
local pdir = (...):gsub('%.[^%.]+%.[^%.]+$', '') .. "."
local cwd = (...):gsub('%.[^%.]+$', '') .. "."

local lib_loader = require(cwd .. "loader")

_M.btCache = {} 

function _M.preloadBehaviorTree(path)
    local NodeFactory = require(cwd .. "NodeFactory")
    local bt = nil
    if _M.btCache[path] then
        bt = _M.btCache[path]
    else
        local BehaviorTree = NodeFactory.BehaviorTree
        bt = BehaviorTree.new()

        local treeData = lib_loader.load(path)
        if not treeData then
            Logging.error("[_M:preloadBehaviorTree()] load file(%s) failed!!!", path)
            return
        end

        bt:load(treeData, path)
        _M.btCache[path] = bt
    end
    return bt
end

return _M