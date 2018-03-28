--- Behaviac lib Component: bson node loader.
-- @module BsonNodeLoader.lua
-- @author n.lee
-- @copyright 2016
-- @license MIT/X11

local _M = {}

-- Localize
local pdir = (...):gsub('%.[^%.]+%.[^%.]+$', '') .. "."
local cwd = (...):gsub('%.[^%.]+$', '') .. "."
local enums = require(pdir .. "enums")
local common = require(pdir .. "common")

local ConstValueReader = require(pdir .. "parser.ConstValueReader")
local bson = require(pdir .. "external.bson")

local EBTStatus                 = enums.EBTStatus
local ENodePhase                = enums.ENodePhase
local EPreconditionPhase        = enums.EPreconditionPhase
local TriggerMode               = enums.TriggerMode
local EOperatorType             = enums.EOperatorType

local constSupportedVersion     = enums.constSupportedVersion
local constInvalidChildIndex    = enums.constInvalidChildIndex
local constBaseKeyStrDef        = enums.constBaseKeyStrDef
local constPropertyValueType    = enums.constPropertyValueType
local constBsonElementType      = enums.constBsonElementType

local Logging                   = common.d_log
local StringUtils               = common.StringUtils

--------------------------------------------------------------------------------
-- Initialize
------------------------------------------------------------------------------

-- See: behaviortree.cpp 
--      void BehaviorNode::load_properties(int version, const char* agentType, BsonDeserizer& d)
function _M.loadProperties(selfNode, version, agentType, bsonTreeData, startPos)
    local docLen, nextPos = bson.readInt32(bsonTreeData, startPos)
    local etype
    etype, nextPos = bson.readByte(bsonTreeData, nextPos)

    local properties = {}
    local propertyName, propertyValue
    while constBsonElementType.BT_String == etype do
        propertyName, nextPos = bson.readString(bsonTreeData, nextPos)
        propertyValue, nextPos = bson.readString(bsonTreeData, nextPos)

        table.insert(properties, { propertyName, propertyValue })
        etype, nextPos = bson.readByte(bsonTreeData, nextPos)
    end

    if #properties > 0 then
        selfNode:onLoading(version, agentType, properties)
    end
    return nextPos
end

function _M.loadChildren(selfNode, version, agentType, bsonTreeData, startPos)
    local docLen, nextPos = bson.readInt32(bsonTreeData, startPos)
    local pChildNode
    pChildNode, nextPos = _M.loadNode(agentType, bsonTreeData, nextPos, version)
    _G.BEHAVIAC_ASSERT(pChildNode)
    selfNode:addChild(pChildNode)
    selfNode.m_bHasEvents = selfNode.m_bHasEvents or pChildNode.m_bHasEvents
    return nextPos
end

-- See: behaviortree.cpp 
--      void BehaviorNode::load_pars(int version, const char* agentType, BsonDeserizer& d)
function _M.loadPars(selfNode, version, agentType, bsonTreeData, startPos)
    local docLen, nextPos = bson.readInt32(bsonTreeData, startPos)
    local etype
    etype, nextPos = bson.readByte(bsonTreeData, nextPos)

    while constBsonElementType.BT_ParElement == etype do
        nextPos = _M.loadLocal(selfNode, version, agentType, bsonTreeData, nextPos)

        etype, nextPos = bson.readByte(bsonTreeData, nextPos)
    end

    return nextPos
 end      

-- See: behaviortree.cpp 
--      void BehaviorNode::load_custom(int version, const char* agentType, BsonDeserizer& d)
function _M.loadCustom(selfNode, version, agentType, bsonTreeData, nextPos)
    local docLen, nextPos = bson.readInt32(bsonTreeData, startPos)
    local etype
    etype, nextPos = bson.readByte(bsonTreeData, nextPos)
    _G.BEHAVIAC_ASSERT(constBsonElementType.BT_NodeElement == etype)

    docLen, nextPos = bson.readInt32(bsonTreeData, nextPos)

    local pChildNode, nextPos = _M.loadNode(agentType, bsonTreeData, nextPos, version)
    selfNode.m_customCondition = pChildNode

    etype, nextPos = bson.readByte(bsonTreeData, nextPos)
    return nextPos
end

-- See: behavior_tree.cpp
--      void BehaviorNode::load_attachments(int version, const char*  agentType, BsonDeserizer& d, bool bIsTransition)
function _M.loadAttachments(selfNode, version, agentType, bsonTreeData, startPos, isTransition)
    local docLen, nextPos = bson.readInt32(bsonTreeData, startPos)
    local etype
    etype, nextPos = bson.readByte(bsonTreeData, nextPos)

    while constBsonElementType.BT_AttachmentElement == etype do
        docLen, nextPos = bson.readInt32(bsonTreeData, nextPos)

        if isTransition then
            selfNode.m_loadAttachment = true
            nextPos = _M.loadPropertiesParsAttachmentsChildren(selfNode, version, agentType, bsonTreeData, nextPos, false)
            selfNode.m_loadAttachment = false
        else
            local attachClassName
            attachClassName, nextPos = bson.readString(bsonTreeData, nextPos)

             -- create node
            local NodeFactory = require(cwd .. "NodeFactory")
            local pAttachment = NodeFactory[attachClassName].new()
            if pAttachment then
                pAttachment:setClassNameString(attachClassName)

                local idStr
                idStr, nextPos = bson.readString(bsonTreeData, nextPos)
                pAttachment:setId(tonumber(idStr))

                local bIsPrecondition, bIsEffector, bAttachmentIsTransition
                bIsPrecondition, nextPos = bson.readBool(bsonTreeData, nextPos)
                bIsEffector, nextPos = bson.readBool(bsonTreeData, nextPos)
                bAttachmentIsTransition, nextPos = bson.readBool(bsonTreeData, nextPos)

                nextPos = _M.loadPropertiesParsAttachmentsChildren(pAttachment, version, agentType, bsonTreeData, nextPos, bAttachmentIsTransition)
                selfNode:attach(pAttachment, bIsPrecondition, bIsEffector, bAttachmentIsTransition)
                selfNode.m_bHasEvents = selfNode.m_bHasEvents or pAttachment.m_bHasEvents
            end
        end

        --
        etype, nextPos = bson.readByte(bsonTreeData, nextPos)
    end
    return nextPos
end

-- See: behaviortree.cpp 
--      void BehaviorNode::load_properties_pars_attachments_children(int version, const char*  agentType, BsonDeserizer& d, bool bIsTransition)
function _M.loadPropertiesParsAttachmentsChildren(selfNode, version, agentType, bsonTreeData, startPos, isTransition)
    selfNode:setAgentType(agentType)

    local etype, nextPos = bson.readByte(bsonTreeData, startPos)
    while constBsonElementType.BT_None ~= etype do
        --
        if constBsonElementType.BT_PropertiesElement == etype then
            nextPos = _M.loadProperties(selfNode, version, agentType, bsonTreeData, nextPos)
        elseif constBsonElementType.BT_ParsElement == etype then
            nextPos = _M.loadPars(selfNode, version, agentType, bsonTreeData, nextPos)
        elseif constBsonElementType.BT_AttachmentsElement == etype then
            nextPos = _M.loadAttachments(selfNode, version, agentType, bsonTreeData, nextPos, isTransition)
        elseif constBsonElementType.BT_Custom == etype then
            nextPos = _M.loadCustom(selfNode, version, agentType, bsonTreeData, nextPos)
        elseif constBsonElementType.BT_NodeElement == etype then
            nextPos = _M.loadChildren(selfNode, version, agentType, bsonTreeData, nextPos)
        else
            _G.BEHAVIAC_ASSERT(false)
        end

        --
        etype, nextPos = bson.readByte(bsonTreeData, nextPos)
    end
    return nextPos
end

-- See: behaviortree.cpp 
--      BehaviorNode* BehaviorNode::load(const char*  agentType, BsonDeserizer& d, int version)
function _M.loadNode(agentType, bsonTreeData, startPos, version)
    local nodeClassName, nextPos = bson.readString(bsonTreeData, startPos)
    -- create node
    local NodeFactory = require(cwd .. "NodeFactory")
    local newNode = NodeFactory[nodeClassName].new()
    if newNode then
        newNode:setClassNameString(nodeClassName)
        local idStr
        idStr, nextPos = bson.readString(bsonTreeData, nextPos)
        _G.BEHAVIAC_ASSERT(idStr, "node = %s no id", agentType)
        newNode:setId(tonumber(idStr))
        nextPos = _M.loadPropertiesParsAttachmentsChildren(newNode, version, agentType, bsonTreeData, nextPos, false)
    end
    return newNode, nextPos
end

-- See: behaviortree.cpp
--      void BehaviorTree::load_local(int version, const char* agentType, BsonDeserizer& d)
function _M.loadLocal(selfNode, version, agentType, bsonTreeData, startPos)
    local docLen, nextPos = bson.readInt32(bsonTreeData, startPos)

    local name, type, value
    name, nextPos = bson.readString(bsonTreeData, nextPos)
    type, nextPos = bson.readString(bsonTreeData, nextPos)
    value, nextPos = bson.readString(bsonTreeData, nextPos)

    _M.addLocal(selfNode, agentType, type, name, value)

    -- eat end of doc
    nextPos = nextPos + 1
    return nextPos
end

function _M.addLocal(selfNode, agentType, typeName, name, valueStr)
    table.insert(selfNode.m_localProps, { name, ConstValueReader.readAnyType(typeName, valueStr) })
end

function _M.addPar(selfNode, agentType, typeName, name, valueStr)
    _M.addLocal(selfNode, agentType, typeName, name, valueStr)
end

return _M