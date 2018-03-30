--- Behaviac lib Component: behavior tree factory.
-- @module BehaviorTreeFactory.lua
-- @author n.lee
-- @copyright 2016
-- @license MIT/X11

local _M = {}

-- Localize
local pdir = (...):gsub('%.[^%.]+%.[^%.]+$', '') .. "."
local cwd = (...):gsub('%.[^%.]+$', '') .. "."

local common = require(ppdir .. "common")
local lib_loader = require(cwd .. "loader")

local Logging = common.d_log

_M.btCache = {} 

function _M.preloadBehaviorTree(pathBase)
    local NodeFactory = require(cwd .. "NodeFactory")
    local bt = nil
    if _M.btCache[pathBase] then
        bt = _M.btCache[pathBase]
    else
        local treeData, fileType = lib_loader.load(pathBase)
        if not treeData then
            Logging.error("[_M:preloadBehaviorTree()] load file(%s) failed!!!", pathBase)
            return
        end

        local BehaviorTree = NodeFactory.BehaviorTree
        bt = BehaviorTree.new()

        if lib_loader.FILE_TYPE_BSON_BYTES == fileType then 
            bt:loadBson(treeData, pathBase)
        elseif lib_loader.FILE_TYPE_JSON == fileType or lib_loader.FILE_TYPE_LUA == fileType then
            bt:load(treeData, pathBase)
        end
        _M.btCache[pathBase] = bt
    end
    return bt
end

function _M.loadBehaviorTree(path)
    local treeData = nil
    local extensionName, fileType, loadFunc, pathBase = lib_loader.testFileType(path)
    if extensionName then
        treeData = loadFunc(path)
    else
        pathBase = path
        treeData, fileType = lib_loader.load(pathBase)
    end

    if not treeData then
        Logging.error("[_M:preloadBehaviorTree()] load file(%s) failed!!!", path)
        return
    end

    local NodeFactory = require(cwd .. "NodeFactory")
    local BehaviorTree = NodeFactory.BehaviorTree
    local bt = BehaviorTree.new()

    if lib_loader.FILE_TYPE_BSON_BYTES == fileType then 
        bt:loadBson(treeData, pathBase)
    elseif lib_loader.FILE_TYPE_JSON == fileType or lib_loader.FILE_TYPE_LUA == fileType then
        bt:load(treeData, pathBase)
    end

    --
    _M.btCache[pathBase] = bt
    return bt
end

return _M