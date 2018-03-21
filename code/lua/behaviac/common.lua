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

function _M.StringUtils.trimEnclosedDoubleQuotes(str)
    if string.byte(str, 1, 1) == string.byte("\"") and string.byte(str, -1, -1) == string.byte("\"") then
        return string.sub(str, 2, -2)
    else
        return str
    end
end

function _M.StringUtils.trimEnclosedBrackets(str)
    if string.byte(str, 1, 1) == string.byte("{") and string.byte(str, -1, -1) == string.byte("}") then
        return string.sub(str, 2, -2)
    else
        return str
    end
end

function _M.StringUtils.skipPairedBrackets(str, startPos)
    if string.byte(str, startPos) == string.byte('{') then
        local depth = 0
        local posIt = startPos
        local strLen = string.len(str)

        while posIt <= strLen do
            if string.byte(str, posIt) == string.byte('{') then
                depth = depth + 1
            
            elseif string.byte(str, posIt) == string.byte('}') then
                depth = depth - 1
                if depth == 0 then
                    return posIt
                end
            end

            posIt = posIt + 1
        end
    end

    return 0
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

function _M.StringUtils.splitTokens(str)
    local ret = {}
    
    if string.byte(str, 1, 1) == string.byte("\"") then
        _G.BEHAVIAC_ASSERT(string.byte(str, -1, -1) == string.byte("\""), "splitTokens string.byte(str, -1, -1) == constCharByteDoubleQuote")
        table.insert(ret, str)
        return ret
    end

    -- //"int Self.AgentArrayAccessTest::ListInts[int Self.AgentArrayAccessTest::l_index]"
    local pB = 1
    local i = 1
    local bBeginIndex = false
	local strLen = string.len(str)

    while i < strLen do
        local bFound = false
        local c = string.byte(str, i)

        if c == string.byte(' ') and not bBeginIndex then
            bFound = true

        elseif c == string.byte('[') then
            bBeginIndex = true
            bFound = true

        elseif c == string.byte(']') then
            bBeginIndex = false
            bFound = true
        end

        if bFound then
            local strT = string.sub(str, pB, i - 1)
            --//Debug.Check(strT.length() > 0);
            _G.BEHAVIAC_ASSERT(string.len(strT) > 0)
            table.insert(ret, strT)

            pB = i + 1
        end

        i = i + 1
    end

    -- last one
    local strT = string.sub(str, pB, i)
    if string.len(strT) > 0 then
        table.insert(ret, strT)
    end

    return ret
end

-- //it returns true if 'str' starts with a count followed by ':'
-- //3:{....}
-- See: stringutils.h 
--      inline bool IsArrayString(const behaviac::string& str, size_t posStart, behaviac::string::size_type& posEnd)
function _M.StringUtils.checkArrayString(str, posStart, posEnd)
    local size = 0
    local elements = {}
    local eStart
    
    local strLen = string.len(str)

    --//begin of the count of an array?
    local mStart_, mEnd_, m_ = string.find(str, "(%d+):", posStart)
    if mStart_ == posStart then
        -- it is array
        size = tonumber(m_)

        --//transit_points = 3:{coordX = 0; coordY = 0; } | {coordX = 0; coordY = 0; } | {coordX = 0; coordY = 0; };
        --//skip array item which is possible a struct
        local depth = 0

        for posIt = mEnd_ + 1, strLen do
            local c1 = string.byte(str, posIt)
            if c1 == string.byte(';') and depth == 0 then
                --//the last ';'
                posEnd = posIt
                break
            elseif c1 == string.byte('{') then
                _G.BEHAVIAC_ASSERT(depth < 10)
                depth = depth + 1
                eStart = posIt
            elseif c1 == string.byte('}') then
                _G.BEHAVIAC_ASSERT(depth > 0)
                depth = depth - 1

                local e = string.sub(str, eStart, posIt)
                table.insert(elements, e)
            end
        end

        return true, posEnd, size > 0 and elements
    end

    return false, posEnd, size > 0 and elements
end

function _M.StringUtils.splitTokensForStruct(str)
	local ret = {}

	--//{color=0;id=;type={bLive=false;name=0;weight=0;};}
    --//the first char is '{'
    --//the last char is '}'
    local posCloseBrackets = _M.StringUtils.skipPairedBrackets(str, 1)
    _G.BEHAVIAC_ASSERT(posCloseBrackets > 0)

    --//{color=0;id=;type={bLive=false;name=0;weight=0;};}
    --//{color=0;id=;type={bLive=false;name=0;weight=0;};transit_points=3:{coordX=0;coordY=0;}|{coordX=0;coordY=0;}|{coordX=0;coordY=0;};}
    local posBegin = 2
    local posEnd = string.find(str, ';', posBegin)
    local isArray

    while posEnd do
        _G.BEHAVIAC_ASSERT(string.byte(str, posEnd) == string.byte(';'))

        --//the last one might be empty
        if posEnd > posBegin then
            local posEqual = string.find(str, '=', posBegin)
            _G.BEHAVIAC_ASSERT(posEqual > posBegin)

            local memmberName = string.sub(str, posBegin, posEqual - 1)
            local memmberValue

            local c = string.byte(str, posEqual + 1)
            if c ~= string.byte('{') then
                --//to check if it is an array
                isArray, posEnd = _M.StringUtils.checkArrayString(str, posEqual + 1, posEnd)
                memmberValue = string.sub(str, posEqual + 1, posEnd - 1)
            else
                local posCloseBrackets_ = _M.StringUtils.skipPairedBrackets(str, posEqual + 1)
                memmberValue = string.sub(str, posEqual + 1, posCloseBrackets_)

                posEnd = posCloseBrackets_ + 1
            end

            table.insert(ret, { memmberName, memmberValue })
        end

        --//skip ';'
        posBegin = posEnd + 1

        --//{color=0;id=;type={bLive=false;name=0;weight=0;};transit_points=3:{coordX=0;coordY=0;}|{coordX=0;coordY=0;}|{coordX=0;coordY=0;};}
        posEnd = string.find(str, ';', posBegin)

        if not posEnd or posEnd >= posCloseBrackets then
            break
        end
    end

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
-- Application about
--------------------------------------------------------------------------------
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