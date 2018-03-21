--- Behaviac lib Component: agent meta.
-- @module AgentMeta.lua
-- @author n.lee
-- @copyright 2016
-- @license MIT/X11

local _M = {
    _agentMetas = {},
    _agentInstances = {},
    
    _eventMethods = {},

    _behaviorTreeFolder = "./lua/data/"
}

-- Localize
local pdir = (...):gsub('%.[^%.]+%.[^%.]+$', '') .. "."
local cwd = (...):gsub('%.[^%.]+$', '') .. "."

function _M.registerMeta(metaClassName, meta)
    _M._agentMetas[metaClassName] = meta
end

function _M.getMeta(metaClassName)
    return _M._agentMetas[metaClassName]
end

function _M.registerInstance(instanceName, instance)
    _M._agentInstances[instanceName] = instance
end

function _M.getInstance(intanceName, className)
    local instance = _M._agentInstances[intanceName]
    if nil == instance then
        local meta = _M.getMeta(className)
        if nil ~= meta then
            instance = meta.new()
            _M. _agentInstances[intanceName] = instance
        else
            print(intanceName .. "." .. className .. " error: meta not found!!!")
        end
    end
    return instance
end

function _M.registerEventMethod(methodIdCrc32, method)
    _M._eventMethods[methodIdCrc32] = method
end

function _M.getEventMethod(methodIdCrc32)
    return _M._eventMethods[methodIdCrc32]
end

function _M.setBehaviorTreeFolder(folderName)
    if string.byte(folderName, -1, -1) ~= string.byte("/") then
        folderName = folderName .. "/"
    end

    _M._behaviorTreeFolder = folderName
end

function _M.getBehaviorTreePath(treeName)
    local ext = ".json"
    if string.sub(treeName, -5) ~= ext then
        return _M._behaviorTreeFolder .. treeName .. ext
    else
        return _M._behaviorTreeFolder .. treeName
    end
end

return _M