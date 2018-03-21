--- Behaviac lib Component: const value reader.
-- @module ConstValueReader.lua
-- @author n.lee
-- @copyright 2016
-- @license MIT/X11

local _M = {}

-- Localize
local pdir = (...):gsub('%.[^%.]+%.[^%.]+$', '') .. "."
local cwd = (...):gsub('%.[^%.]+$', '') .. "."

local enums = require(pdir .. "enums")
local common = require(pdir .. "common")
local AgentMeta = require(pdir .. "agent.AgentMeta")

local StringUtils               = common.StringUtils

--------------------------------------------------------------------------------
-- Basic type reader
--------------------------------------------------------------------------------
local basic_type_value_read_func_ = {
    ["bool"] = function(str) if str == "true" then return true else return false end end,
    ["Boolean"] = function(str) if str == "true" then return true else return false end end,
    ["byte"]    = tonumber,
    ["ubyte"]   = tonumber,
    ["Byte"]    = tonumber,
    ["char"]    = tonumber,
    ["Char"]    = tonumber,
    ["SByte"]   = tonumber,
    ["decimal"] = tonumber,
    ["Decimal"] = tonumber,
    ["double"]  = tonumber,
    ["Double"]  = tonumber,
    ["float"]   = tonumber,
    ["int"]     = tonumber,
    ["Int16"]   = tonumber,
    ["Int32"]   = tonumber,
    ["Int64"]   = tonumber,
    ["long"]    = tonumber,
    ["llong"]   = tonumber,
    ["sbyte"]   = tonumber,
    ["short"]   = tonumber,
    ["ushort"]  = tonumber,
    ["uint"]    = tonumber,
    ["UInt16"]  = tonumber,
    ["UInt32"]  = tonumber,
    ["UInt64"]  = tonumber,
    ["ulong"]   = tonumber,
    ["ullong"]  = tonumber,
    ["Single"]  = tonumber,
    ["number"]  = tonumber,
    ["table"]   = function(str) return load("return " .. str)() end,
    ["string"]  = function(str) return str end,
    ["String"]  = function(str) return str end,

    ["std::string"]             = function(str) return str end,
    ["char*"]                   = function(str) return str end,
    ["const char*"]             = function(str) return str end,
    ["behaviac::EBTStatus"]     = function(str) return EBTStatus[str] end,
}

function _M.readAnyType(typeName, valueStr)
    local isArray = false
    local isStruct = false

    if string.find(typeName, "vector<") then
        isArray = true
        typeName = string.gmatch(typeName, "vector<(.+)>")()
    end

    if isArray then
        Logging.error("[_M.readAnyType()] array is not implemented yet!!!")
        return nil, isArray, isStruct
    end

    local f = basic_type_value_read_func_[typeName]
    if f then
        return f(valueStr), isArray, isStruct
    else
        -- it must be struct
        isStruct = true
        return _M.readStruct(typeName, valueStr), isArray, isStruct
    end
end

function _M.readStruct(typeName, valueStr)
    local retStruct = {}
    local tokens = StringUtils.splitTokensForStruct(valueStr)
    for _, expression in ipairs(tokens) do
        local key = expression[1]
        local val = expression[2]
        local strLen = string.len(val)
        if strLen > 0 and string.byte(val, 1) == string.byte('{') then
            retStruct[key] = _M.readStruct(typeName, val)
        else
            local isArray, posEnd, elements = StringUtils.checkArrayString(val, 1, strLen)
            if isArray then
                local arrayT = {}
                for _, e in ipairs(elements) do
                    table.insert(arrayT, _M.readStruct(typeName, e))
                end
                retStruct[key] = arrayT
            else
                retStruct[key] = val
            end
        end
    end
    return retStruct
end

return _M