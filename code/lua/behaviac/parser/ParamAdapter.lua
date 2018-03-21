--- Behaviac lib Component: param method and property wrapper.
-- @module ParamAdapter.lua
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

-- Class
local ParamAdapter = class("ParamAdapter")
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("ParamAdapter", ParamAdapter)
local _M = ParamAdapter

local AgentMeta = require(pdir .. "agent.AgentMeta")
local ConstValueReader = require(pdir .. "parser.ConstValueReader")

--------------------------------------------------------------------------------
-- const
--------------------------------------------------------------------------------
local ConstVar = {
    constCharByteDoubleQuote     = string.byte('\"'),
    constCharByteLeftBracket     = string.byte('['),
    constCharByteRightBracket    = string.byte(']'),
    constCharByteLeftBraces      = string.byte('{'),
    constCharByteComma           = string.byte(","),
    constCharByteColon           = string.byte(":"),
    constCharByteSemicolon       = string.byte(";"),
}

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
    self.realTypeIsArray = false
    self.realTypeIsStruct = false
    self.realTypeName = false
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

local function _compute(left, right, computeType)
    -- TODO left, right类型检查
    if type(left) ~= 'number' or type(right) ~= 'number' then
        _G.BEHAVIAC_ASSERT(false)
    else
        if computeType == EOperatorType.E_ADD then
            return left + right
        elseif computeType == EOperatorType.E_SUB then
            return left - right
        elseif computeType == EOperatorType.E_MUL then
            return left * right
        elseif computeType == EOperatorType.E_DIV then
            if right == 0 then
                print('_compute() error!!! Divide right is zero.')
                return left
            end
            return left / right
        end
    end
    _G.BEHAVIAC_ASSERT(false)
    return left
end

-- Compute(pAgent, pComputeNode->m_opr1, pComputeNode->m_opr2, pComputeNode->m_operator)
function _M:compute(agent, opr1, opr2, operator)
    local r1 = opr1:getValue(agent)
    local r2 = opr2:getValue(agent)
    if opr1.realTypeIsStruct or opr2.realTypeIsStruct then
        print("[_M:compute()] struct compute is not supported yet!!!", left, right)
        return
    end
    local result = _compute(r1, r2, operator)
    self.setValue(agent, result)
end

local function _compare(left, right, operatorType)
    if nil == left or nil == right then
        print("_compare() failed!!! Left or right operand is nil --", left, right)
        return false
    else
        if operatorType == EOperatorType.E_EQUAL then
            return left == right
        elseif operatorType == EOperatorType.E_NOTEQUAL then
            return left ~= right
        elseif operatorType == EOperatorType.E_GREATER then
            return left > right
        elseif operatorType == EOperatorType.E_GREATEREQUAL then
            return left >= right
        elseif operatorType == EOperatorType.E_LESS then
            return left < right
        elseif operatorType == EOperatorType.E_LESSEQUAL then
            return left <= right
        end
        print("_compare() failed!!! Unknown operator type --", operatorType)
        return false
    end
end

local function _compareStruct(left, right, operatorType)
    if nil == left or nil == right then
        print("_compareStruct() failed!!! Left or right operand is nil --", left, right)
        return false
    else
        if operatorType == EOperatorType.E_EQUAL then
            for k, v in pairs(left) do
                if v ~= right[k] then
                    return false
                end
            end
            return true
        end
        print("_compareStruct() failed!!! Unknown operator type --", operatorType)
        return false
    end
end

function _M:compare(agent, opr, operatorType)
    local l = self:getValue(agent)
    local r = opr:getValue(agent)
    if self.realTypeName == opr.realTypeName and (self.realTypeIsStruct or opr.realTypeIsStruct) then
        return _compareStruct(l, r, operatorType)
    else
        return _compare(l, r, operatorType)
    end
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
            local prop = ParamAdapter.new()
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

function _M:buildProperty(propertyStr)
    self.isMethod = false

    local tokens = StringUtils.splitTokens(propertyStr)
    if tokens[1] == "const" then
        -- const type bulabula
        _G.BEHAVIAC_ASSERT(#tokens == 3, "_M.parseProperty #tokens == 3")

        local typeName = tokens[2]
        local valueStr = tokens[3]
        local isArray = false
        local isStruct = false

        self.type  = constPropertyValueType.const
        self.value, isArray, isStruct = ConstValueReader.readAnyType(typeName, valueStr) 
        self.valueIsFunction = false
        self.realTypeIsArray = isArray
        self.realTypeIsStruct = isStruct
        self.realTypeName = typeName
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
        end

        self.valueIsFunction = true
        self.realTypeIsArray = false
        self.realTypeIsStruct = false
        self.realTypeName = typeName
    end

end

return _M