--- Behaviac lib Component: node parser.
-- @module NodeParser.lua
-- @author n.lee
-- @copyright 2016
-- @license MIT/X11

local _M = {}

-- Localize
local pdir = (...):gsub('%.[^%.]+%.[^%.]+$', '') .. "."
local cwd = (...):gsub('%.[^%.]+$', '') .. "."

local enums = require(pdir .. "enums")
local common = require(pdir .. "common")
local ParamAdapter = require(cwd .. "ParamAdapter")
local PrototypeAdapter = require(cwd .. "PrototypeAdapter")

local EOperatorType             = enums.EOperatorType
local StringUtils               = common.StringUtils

function _M.parseMethod(methodInfo)
    if StringUtils.isNullOrEmpty(methodInfo) then
        return nil, false
    end

    local intanceName, className, methodName, paramStr = string.gmatch(methodInfo, "(.+)%.(.+)::(.+)%((.*)%)")()
    _G.BEHAVIAC_ASSERT(intanceName and className and methodName, "[_M.parseMethod()] " .. methodInfo)

    local method = ParamAdapter.new()
    method:buildMethod(intanceName, className, methodName, paramStr)
    return method, methodName
end

function _M.parseTaskPrototype(prototypeInfo)
    if StringUtils.isNullOrEmpty(prototypeInfo) then
        return nil, false
    end

    local prototypeName, paramStr = string.gmatch(prototypeInfo, "(.+%..+::.+)%((.*)%)")()
    _G.BEHAVIAC_ASSERT(prototypeName, "[_M.parseTaskPrototype()] " .. prototypeInfo)

    local prototype = PrototypeAdapter.new()
    prototype:buildTaskPrototype(prototypeName, paramStr)
    return prototype, prototypeName
end

function _M.parseProperty(propertyStr)
    if StringUtils.isNullOrEmpty(propertyStr) then
        return nil
    end

    local prop = ParamAdapter.new()
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

return _M