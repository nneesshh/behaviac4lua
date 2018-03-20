--- Behaviac lib Component: node param wrapper.
-- @module NodeParam.lua
-- @author n.lee
-- @copyright 2016
-- @license MIT/X11

-- Localize
local pdir = (...):gsub('%.[^%.]+%.[^%.]+$', '') .. "."
local cwd = (...):gsub('%.[^%.]+$', '') .. "."
local unpack = unpack or table.unpack

local enums = require(pdir .. "enums")
local common = require(pdir .. "common")

local EBTStatus                 = enums.EBTStatus
local ENodePhase                = enums.ENodePhase
local EPreconditionPhase        = enums.EPreconditionPhase
local TriggerMode               = enums.TriggerMode
local EOperatorType             = enums.EOperatorType

local constSupportedVersion     = enums.constSupportedVersion
local constInvalidChildIndex    = enums.constInvalidChildIndex
local constBaseKeyStrDef        = enums.constBaseKeyStrDef
local constPropertyValueType    = enums.constPropertyValueType

local Logging                   = common.d_log
local StringUtils               = common.StringUtils

local AgentMeta = require(pdir .. "agent.AgentMeta")

local ConstVar = {
    constCharByteDoubleQuote     = string.byte('\"'),
    constCharByteLeftBracket     = string.byte('['),
    constCharByteRightBracket    = string.byte(']'),
    constCharByteLeftBraces      = string.byte('{'),
    constCharByteComma           = string.byte(","),
}

-- Class
local NodeParam = class("NodeParam")
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("NodeParam", NodeParam)
local _M = NodeParam

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor()
    self.isMethod = false

    self.intanceName = false
    self.className = false
    self.paramName = false

    self.type = constPropertyValueType.default
    self.value = false
    self.setValue = false
    self.valueIsFunction = false
    self.params = {}
end

local function unpackParams(agent, params)
    -- agent is unused
    local retValues = {}
    for _, paramProp in ipairs(params) do
        table.insert(retValues, paramProp.value(agent))
    end
    return unpack(retValues)
end

function _M:run(agent)
    if self.isMethod and self.valueIsFunction then
        self.value(agent, unpackParams(agent, self.params))
    end
end

function _M:setValueCast(agent, opr, cast)
    -- cast is unused
    local r = opr:getValue(agent)
    self.setValue(agent, r)
end

function _M:getValue(agent)
    if not self.valueIsFunction then
        return self.value
    end
    if self.params then
        return self.value(agent, unpackParams(agent, self.params))
    else
        return self.value(agent)
    end
end

function _M:getValueFrom(agent, method)
    local fp = method:getValue(agent)
    if not self.valueIsFunction then
        return self.value
    end
    if self.params then
        return self.value(agent, fp, unpackParams(agent, self.params))
    else
        return self.value(agent, fp)
    end
end

-- Compute(pAgent, pComputeNode->m_opr1, pComputeNode->m_opr2, pComputeNode->m_operator)
function _M:compute(agent, opr1, opr2, operator)
    local r1 = opr1:getValue(agent)
    local r2 = opr2:getValue(agent)
    local result = _M.compute(r1, r2, operator)
    self.setValue(agent, result)
end

function _M:compare(agent, opr, operatorType)
    local l = self:getValue(agent)
    local r = opr:getValue(agent)
    return _M.compare(l, r, operatorType)
end

function _M:setTaskParams(agent, treeTask)
    print("_M:setTaskParams(agent, treeTask)")
end

local function parseForParams(paramStr)
    local params = {}
    
    local startIndex = 1
    local endIndex = #paramStr
    local quoteDepth = 0

    for i = startIndex, endIndex do
        local b = string.byte(paramStr, i)
        if ConstVar.constCharByteDoubleQuote == b then
            quoteDepth = (quoteDepth + 1) % 2
        elseif 0 == quoteDepth and ConstVar.constCharByteComma == b then
            local s = string.trim(string.sub(paramStr, startIndex, i - 1))
            table.insert(params, s)
            startIndex = i + 1
        end
    end

    -- the last param
    if endIndex > startIndex then
        local s = string.trim(string.sub(paramStr, startIndex, endIndex))
        table.insert(params, s)
    end

    -- load properties from params
    local retProperties = {}
    if #params > 0 then
        for _, propStr in ipairs(params) do
            local prop = NodeParam.new()
            prop:buildProperty(propStr)
            table.insert(retProperties, prop)
        end
    end
    return retProperties
end

function _M:buildMethod(intanceName, className, methodName, paramStr)
    self.isMethod     = true

    self.intanceName  = intanceName
    self.paramName    = methodName
    self.params       = parseForParams(paramStr)

    local function methodIsNotImplementedYetError()
        print(intanceName .. "." .. className .. "::" .. methodName .. " --> error: method is not implemented yet!!!")
    end

    local function metaNotFoundError()
        print(intanceName .. "." .. className .. " --> error: meta not found!!!")
    end

    if string.lower(intanceName) == "self" then
        self.value = function(agent, ...)
            agent[methodName] = agent[methodName] or methodIsNotImplementedYetError
            return agent[methodName](agent, ...)
        end
        self.valueIsFunction = true
    else
        self.value = function(agent, ...)
            local other = AgentMeta.getInstance(intanceName, className)
            local otherMethod = nil
            if nil ~= other then
                otherMethod = other[methodName] or methodIsNotImplementedYetError
            else
                otherMethod = metaNotFoundError
            end
            return otherMethod(agent, ...)
        end
        self.valueIsFunction = true
    end

end

local function splitTokens(str)
    local ret = {}
    if string.byte(str, 1, 1) == ConstVar.constCharByteDoubleQuote then
        _G.BEHAVIAC_ASSERT(string.byte(str, -1, -1) == ConstVar.constCharByteDoubleQuote, "splitTokens string.byte(str, -1, -1) == constCharByteDoubleQuote")
        table.insert(ret, str)
        return ret
    end
    
    local p = StringUtils.split(str, ' ')
    local len = #p

    if string.byte(p[len], -1, -1) == ConstVar.constCharByteRightBracket then
        local b = string.find(p[len], '%[')
        _G.BEHAVIAC_ASSERT(b, "splitTokens string.find(p[len], '%[')")
        p[len] = string.sub(v, 1, b-1)
        p[len+1] = string.sub(v, b+1, -1)
    end
    return p
end

function _M:buildProperty(propertyStr)
    self.isMethod     = false

    local tokens = splitTokens(propertyStr)
    if tokens[1] == "const" then
        _G.BEHAVIAC_ASSERT(#tokens == 3, "_M.parseProperty #tokens == 3")
        self.type  = constPropertyValueType.const
        self.value = common.readBasicType(tokens[2], tokens[3]) 
        self.valueIsFunction = false
    else
        local propStr       = ""
        local typeName      = ""
        local indexPropStr  = ""
        if tokens[1] == "static" then
            -- static number/table/str Self.m_s_float_type_0
            -- static number/table/str _G.xxx.yyy
            _G.BEHAVIAC_ASSERT(#tokens == 3 or #tokens == 4, "_M.parseProperty static #tokens ~= 3, 4")
            typeName = tokens[2]
            propStr  = tokens[3]
            self.type  = constPropertyValueType.static

            -- array index
            if #tokens >= 4 then
                indexPropStr = tokens[4]
            end
        else
            -- number/table/str Self.m_s_float_type_0
            -- number/table/str _G.xxx.yyy
            _G.BEHAVIAC_ASSERT(#tokens == 2 or #tokens == 3, "_M.parseProperty non-static #tokens ~= 2, 3")
            typeName   = tokens[1]
            propStr    = tokens[2]
            self.type  = constPropertyValueType.default

            -- array index
            if #tokens >= 3 then
                indexPropStr = tokens[3]
            end
        end
        
        local indexMember = 0

        --//if (!StringUtils::IsNullOrEmpty(indexPropStr))
        if #indexPropStr > 0 then
            indexMember = tonumber(indexPropStr)
        end
        
        local intanceName, className, propertyName = string.gmatch(propStr, "(.+)%.(.+)::(.+)")()
        if string.lower(intanceName) == "self" then
            _G.BEHAVIAC_ASSERT(propertyName, "_M.parseProperty() property name can't be nil")
            self.value = function(agent)
                local val = agent[propertyName]
                if val then
                    return val
                else
                    return agent:getLocalVariable(propertyName)
                end
            end
            self.setValue = function(agent, value)
                agent[propertyName] = value
            end
            self.valueIsFunction = true
        else
            self.value = function(agent)
                local other = AgentMeta.getInstance(intanceName, className)
                return other and other[propertyName]
            end
            self.setValue = function(agent, value)
                local other = AgentMeta.getInstance(intanceName, className)
                if nil ~= other then
                    other[propertyName] = value
                end
            end
            self.valueIsFunction = true
        end
    end

end

return _M