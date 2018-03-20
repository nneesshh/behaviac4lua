--- Behaviac lib Component: common funcs.
-- @module common.lua
-- @author n.lee
-- @copyright 2016
-- @license MIT/X11

local _M = {}

-- Localize
local cwd = (...):gsub('%.[^%.]+$', '') .. "."

local lib_crc32 = require(cwd .. "external.CRC32")

--------------------------------------------------------------------------------
-- log
--------------------------------------------------------------------------------
_M.d_log = {}
function _M.d_log.must(formatStr, ...)
    print(string.format(formatStr, ...))
end

function _M.d_log.error(formatStr, ...)
    print(string.format(formatStr, ...))
end

local Logging                   = _M.d_log

--------------------------------------------------------------------------------
-- StringUtils
--------------------------------------------------------------------------------
_M.StringUtils = {}
function _M.StringUtils.isNullOrEmpty(str)
    return not str or str == ""
end

function _M.StringUtils.isValidString(str)
    return str and str ~= ""
end

function _M.StringUtils.compare(str1, str2, bIgnoreCase)
    bIgnoreCase = bIgnoreCase or false
    if bIgnoreCase then
        return string.lower(str1) == string.lower(str2)
    else
        return str1 == str2
    end
end

function _M.StringUtils.split(str, char)
    local ret = {}
    local e = 1
    local b = string.find(str, char, e)
    while b do
        table.insert(ret, string.sub(str, e, b - 1))
        e = b + 1
        b = string.find(str, char, e)
    end
    table.insert(ret, string.sub(str, e, -1))
    return ret
end

--------------------------------------------------------------------------------
-- CRC
--------------------------------------------------------------------------------
_M.CRC = {}
function _M.CRC.CalcCRC(idStr)
    return lib_crc32.Hash(idStr)
end

function _M.makeVariableId(idStr)
    return _M.CRC.CalcCRC(idStr)
end

--------------------------------------------------------------------------------
-- Basic type reader
--------------------------------------------------------------------------------
local basic_types_read_func_ = {
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

function _M.readBasicType(typeName, valueStr)
    local isArray = false
    if string.find(typeName, "vector<") then
        isArray = true
        typeName = string.gmatch(typeName, "vector<(.+)>")()
    end

    local f = basic_types_read_func_[typeName]
    if f then
        if isArray then
            Logging.error("[readBasicType()] array is not implemented yet!!!")
            return {}
        else
            return f(valueStr)
        end
    else
        Logging.error("[readBasicType()] can't find function(%s)!!!", typeName)
    end
end

function _M.getClock()
    return os.clock()
end

function _M.getFrames()
    return os.time()
end

function _M.getRandomValue(method, agent)
    if nil ~= method then
        return method:getValue(agent)
    end

    return math.random(10000)/10000
end

return _M