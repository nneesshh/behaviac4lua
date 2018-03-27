--- Behaviac lib Component: node loader.
-- @module NodeLoader.lua
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

--------------------------------------------------------------------------------
-- Initialize
------------------------------------------------------------------------------

-- See: behaviortree.cpp 
--      void BehaviorNode::load_properties(int version, const char* agentType, BsonDeserizer& d)
function _M.loadProperties(selfNode, version, agentType, dataEntry)
    local thisEntry = dataEntry[constBaseKeyStrDef.kStrProperties]
    if not thisEntry then
        return
    end

    local properties = {}
    for _, oneProperty in ipairs(thisEntry) do
        table.insert(properties, oneProperty)
    end

    if #properties > 0 then
        selfNode:onLoading(version, agentType, properties)
    end
end

function _M.loadChildren(selfNode, version, agentType, dataEntry)
    local hasEvents = false
    local nodeEntry = nil
    local newNode = nil
    
    -- must be node or nodes
    nodeEntry = dataEntry[constBaseKeyStrDef.kStrNode]
    if nil ~= nodeEntry then
        newNode = _M.loadNode(agentType, nodeEntry, version)
        hasEvents = hasEvents or newNode.m_bHasEvents
        selfNode:addChild(newNode)
    elseif nil ~= dataEntry.children then
        -- children node
        for _, oneChild in ipairs(dataEntry.children) do
            nodeEntry = oneChild[constBaseKeyStrDef.kStrNode]
            newNode = _M.loadNode(agentType, nodeEntry, version)
            hasEvents = hasEvents or newNode.m_bHasEvents
            selfNode:addChild(newNode)
        end
    end

    --
    selfNode.m_bHasEvents = selfNode.m_bHasEvents or hasEvents
end

-- See: behaviortree.cpp 
--      void BehaviorNode::load_pars(int version, const char* agentType, BsonDeserizer& d)
function _M.loadPars(selfNode, version, agentType, dataEntry)
    local thisEntry = dataEntry[constBaseKeyStrDef.kStrPars]
    if not thisEntry then
        return
    end

    for _, oneParNode in ipairs(thisEntry) do
        _M.loadLocal(selfNode, version, agentType, oneParNode)
    end
 end      

-- See: behaviortree.cpp 
--      void BehaviorNode::load_custom(int version, const char* agentType, BsonDeserizer& d)
function _M.loadCustom(selfNode, version, agentType, dataEntry)
    local thisEntry = dataEntry[constBaseKeyStrDef.kStrCustom]
    if not thisEntry then
        return
    end

    local childNode = _M.loadNode(agentType, thisEntry, version)
    selfNode.m_customCondition = childNode
end

-- 
function _M.loadAttachmentTransitionEffectors(selfNode, version, agentType, dataEntry)
    selfNode.m_loadAttachment = true
    _M.loadPropertiesParsAttachmentsChildren(selfNode, version, agentType, dataEntry, false)
    selfNode.m_loadAttachment = false
end

-- See behaviortree.cpp
--     void BehaviorNode::load_attachments(int version, const char*  agentType, BsonDeserizer& d, bool bIsTransition)
function _M.loadAttachment(selfNode, version, agentType, hasEvents, dataEntry)
    local attachClassName = dataEntry[constBaseKeyStrDef.kStrClass]
    if not attachClassName then
        _M.loadAttachmentTransitionEffectors(selfNode, version, agentType, dataEntry)
        return true
    end

    -- create node
    local NodeFactory = require(cwd .. "NodeFactory")
    local attachmentNode = NodeFactory[attachClassName].new()
    if attachmentNode then
        attachmentNode:setClassNameString(attachClassName)
        local id = dataEntry[constBaseKeyStrDef.kStrId]
        attachmentNode:setId(tonumber(id))

        local bIsPrecondition = dataEntry[constBaseKeyStrDef.kStrPrecondition] or false
        local bIsEffector = dataEntry[constBaseKeyStrDef.kStrEffector] or false
        local bIsTransition = dataEntry[constBaseKeyStrDef.kStrTransition] or false

        _M.loadPropertiesParsAttachmentsChildren(attachmentNode, version, agentType, dataEntry, bIsTransition)
        selfNode:attach(attachmentNode, bIsPrecondition, bIsEffector, bIsTransition)
        hasEvents = hasEvents or attachmentNode:isEvent()
    else
        _G.BEHAVIAC_ASSERT(attachmentNode, "attachment node is nil")
    end
    return hasEvents
end

--
function _M.loadAttachments(selfNode, version, agentType, dataEntry, isTransition)
    local hasEvents = false
    local thisEntry = dataEntry[constBaseKeyStrDef.kStrAttachments]
    if not thisEntry then
        return
    end

    for _, oneAtachement in ipairs(thisEntry) do
        hasEvents = _M.loadAttachment(selfNode, version, agentType, hasEvents, oneAtachement)
    end
    selfNode.m_bHasEvents = selfNode.m_bHasEvents or hasEvents
end

-- See: behaviortree.cpp 
--      void BehaviorNode::load_properties_pars_attachments_children(int version, const char*  agentType, BsonDeserizer& d, bool bIsTransition)
function _M.loadPropertiesParsAttachmentsChildren(selfNode, version, agentType, dataEntry, isTransition)
    selfNode:setAgentType(agentType)

    --
    _M.loadPars(selfNode, version, agentType, dataEntry)
    -- NOTE: load property after loading par as property might reference par
    _M.loadProperties(selfNode, version, agentType, dataEntry)
    _M.loadAttachments(selfNode, version, agentType, dataEntry, isTransition)
    _M.loadCustom(selfNode, version, agentType, dataEntry)
    _M.loadChildren(selfNode, version, agentType, dataEntry)
end

-- See: behaviortree.cpp 
--      BehaviorNode* BehaviorNode::load(const char*  agentType, BsonDeserizer& d, int version)
function _M.loadNode(agentType, dataEntry, version)
    local nodeClassName = dataEntry[constBaseKeyStrDef.kStrClass]
    if nodeClassName then
        -- create node
        local NodeFactory = require(cwd .. "NodeFactory")
        local newNode = NodeFactory[nodeClassName].new()
        if newNode then
            newNode:setClassNameString(nodeClassName)
            local idStr = dataEntry[constBaseKeyStrDef.kStrId]
            _G.BEHAVIAC_ASSERT(idStr, "node = %s no id", agentType)
            newNode:setId(tonumber(idStr))
            _M.loadPropertiesParsAttachmentsChildren(newNode, version, agentType, dataEntry, false)
        end
        return newNode
    end

    return nil
end

function _M.loadLocal(selfNode, version, agentType, parNode)
    local name = parNode[constBaseKeyStrDef.kStrName]
    local type = parNode[constBaseKeyStrDef.kStrType]
    local value = parNode[constBaseKeyStrDef.kStrValue]

    _M.addLocal(selfNode, agentType, type, name, value)
end

function _M.addLocal(selfNode, agentType, typeName, name, valueStr)
    table.insert(selfNode.m_localProps, { name, ConstValueReader.readAnyType(typeName, valueStr) })
end

function _M.addPar(selfNode, agentType, typeName, name, valueStr)
    _M.addLocal(selfNode, agentType, typeName, name, valueStr)
end

return _M