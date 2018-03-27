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

        local treeData, fileType = lib_loader.load(path)
        if not treeData then
            Logging.error("[_M:preloadBehaviorTree()] load file(%s) failed!!!", path)
            return
        end

        if lib_loader.FILE_TYPE_BSON_BYTES == fileType then 
            bt:loadBson(treeData, path)
        elseif lib_loader.FILE_TYPE_JSON == fileType or lib_loader.FILE_TYPE_LUA == fileType then
            bt:load(treeData, path)
        end
        _M.btCache[path] = bt
    end
    return bt
end

return _M