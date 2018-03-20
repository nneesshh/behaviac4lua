--- Behaviac lib Component: node parser.
-- @module NodeParser.lua
-- @author n.lee
-- @copyright 2016
-- @license MIT/X11

local _M = {}

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

local NodeParam = require(cwd .. "NodeParam")

function _M.parseMethod(methodInfo)
    if StringUtils.isNullOrEmpty(methodInfo) then
        return nil, false
    end

    -- self:funtionName(params)
    -- _G:fff.fff()
    -- local intanceName, methodName, paramStr = string.gmatch(methodInfo, "(.+):(.+)%((.+)%)")()
    -- REDO:  Self.CBTPlayer::MoveAhead(0)
    local intanceName, className, methodName, paramStr = string.gmatch(methodInfo, "(.+)%.(.+)::(.+)%((.*)%)")()
    _G.BEHAVIAC_ASSERT(intanceName and className and methodName, "_M.parseMethod " .. methodInfo)
    -- print('>>>>>>>>parseMethod', intanceName, methodName, paramStr)
    local method = NodeParam.new()
    method:buildMethod(intanceName, className, methodName, paramStr)
    return method, methodName
end

function _M.parseProperty(propertyStr)
    if StringUtils.isNullOrEmpty(propertyStr) then
        return nil
    end

    local prop = NodeParam.new()
    prop:buildProperty(propertyStr)
    return prop
end

function _M.parseMethodOutMethodName(methodInfo)
    return _M.parseMethod(methodInfo)
end

local operator_type_parser_ = {
    ["Invalid"] = EOperatorType.E_INVALID,
    ["Assign"] = EOperatorType.E_ASSIGN,
    ["Add"] = EOperatorType.E_ADD,
    ["Sub"] = EOperatorType.E_SUB,
    ["Mul"] = EOperatorType.E_MUL,
    ["Div"] = EOperatorType.E_DIV,
    ["Equal"] = EOperatorType.E_EQUAL,
    ["NotEqual"] = EOperatorType.E_NOTEQUAL,
    ["Greater"] = EOperatorType.E_GREATER,
    ["Less"] = EOperatorType.E_LESS,
    ["GreaterEqual"] = EOperatorType.E_GREATEREQUAL,
    ["LessEqual"] = EOperatorType.E_LESSEQUAL,
}
function _M.parseOperatorType(operatorTypeStr)
    return operator_type_parser_[operatorTypeStr]
end

function _M.compare(left, right, operatorType)
    if nil == left or nil == right then
        print("_M.compare() failed, left or right operand is nil --", left, right)
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
        print("_M.compare() failed, unknown operator type --", operatorType)
        return false
    end
end

function _M.compute(left, right, computeType)
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
                print('error!!! _M.compute Divide right is zero.')
                return left
            end
            return left / right
        end
    end
    _G.BEHAVIAC_ASSERT(false)
    return left
end

return _M