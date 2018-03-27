--- Behaviac lib Component: agent meta.
-- @module AgentMeta.lua
-- @author n.lee
-- @copyright 2016
-- @license MIT/X11

local _M = {
    _agentMetas = {},
    _agentInstances = {},
    _agentEnums = {},

    _behaviorTreeFolder = "./lua/data/"
}

-- Localize
local pdir = (...):gsub('%.[^%.]+%.[^%.]+$', '') .. "."
local cwd = (...):gsub('%.[^%.]+$', '') .. "."
local lib_loader = require(pdir .. "parser.loader")

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

function _M.registerEnumType(enumTypeName, enumType)
    _M._agentEnums[enumTypeName] = enumType
end

function _M.getEnum(enumTypeName, enumName)
    local enumType = _M._agentEnums[enumTypeName]
    if not enumType then
        print(enumTypeName .. " error: enum meta not found!!!")
    elseif not enumType[enumName] then
        print(enumTypeName .. "." .. enumName .. " error: enum name not found!!!")
    end
    return enumType and enumType[enumName] or 0
end

function _M.setBehaviorTreeFolder(folderName)
    if string.byte(folderName, -1, -1) ~= string.byte("/") then
        folderName = folderName .. "/"
    end

    _M._behaviorTreeFolder = folderName
end

function _M.getBehaviorTreePath(treeName)
    local baseName = lib_loader.getBehaviorTreeBaseName(treeName)
    return _M._behaviorTreeFolder .. baseName
end

return _M