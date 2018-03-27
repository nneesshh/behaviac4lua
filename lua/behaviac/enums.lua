--- Behaviac lib Component: constants and enums definition.
-- @module enums.lua
-- @author n.lee
-- @copyright 2016
-- @license MIT/X11

local _M = {}

-- status
_M.EBTStatus = {
    BT_INVALID = 0,     -- 
    BT_SUCCESS = 1,     -- 
    BT_FAILURE = 2,     -- 
    BT_RUNNING = 3,     -- 
}

_M.ENodePhase = {
    E_SUCCESS   = 0,    -- 
    E_FAILURE   = 1,    -- 
    E_BOTH      = 2,    -- success or failure ?
}

_M.EPreconditionPhase = {
    E_ENTER     = 0,
    E_UPDATE    = 1,
    E_BOTH      = 2,
}

_M.TriggerMode = {
    TM_Transfer = 1,
    TM_Return   = 2,
}

_M.EOperatorType = {
    E_INVALID       = 0,
    E_ASSIGN        = 1,    -- =
    E_ADD           = 2,    -- +
    E_SUB           = 3,    -- -
    E_MUL           = 4,    -- *
    E_DIV           = 5,    -- /
    E_EQUAL         = 6,    -- ==
    E_NOTEQUAL      = 7,    -- !=
    E_GREATER       = 8,    -- >
    E_LESS          = 9,    -- <
    E_GREATEREQUAL  = 10,   -- >=
    E_LESSEQUAL     = 11,   -- <=
}

-- keep this version equal to designers' NewVersion
_M.constSupportedVersion   = 5

-- 
_M.constInvalidChildIndex  = 0

_M.constBaseKeyStrDef = {
    kStrBehavior        = "behavior",
    kStrAgentType       = "agenttype",

    kStrId              = "id",
    kStrNode            = "node",
    kStrCustom          = "custom",

    kStrProperties      = "properties",
    kStrPars            = "pars",
    kStrAttachments     = "attachments",

    kStrClass           = "class",
    kStrName            = "name",
    kStrType            = "type",
    kStrValue           = "value",
    kEventParam         = "eventParam",

    kStrVersion         = "version",
    kStrPrecondition    = "precondition",
    kStrEffector        = "effector",
    kStrTransition      = "transition",

    kStrDomains         = "Domains",
    kStrDescriptorRefs  = "DescriptorRefs",
}

--
_M.constPropertyValueType = {
    default = 0,    -- 
    const   = 1,    -- const
    static  = 2,    -- static
}

_M.constBsonElementType = {
    BT_None = 0,
    BT_Double = 1,
    BT_String = 2,
    BT_Object = 3,
    BT_Array = 4,
    BT_Binary = 5,
    BT_Undefined = 6,
    BT_ObjectId = 7,
    BT_Boolean = 8,
    BT_DateTime = 9,
    BT_NULL = 10,
    BT_Regex = 11,
    BT_Reference = 12,
    BT_Code = 13,
    BT_Symbol = 14,
    BT_ScopedCode = 15,
    BT_Int32 = 16,
    BT_Timestamp = 17,
    BT_Int64 = 18,
    BT_Float = 19,
    BT_Element = 20,
    BT_Set = 21,
    BT_BehaviorElement = 22,
    BT_PropertiesElement = 23,
    BT_ParsElement = 24,
    BT_ParElement = 25,
    BT_NodeElement = 26,
    BT_AttachmentsElement = 27,
    BT_AttachmentElement = 28,
    BT_AgentsElement = 29,
    BT_AgentElement = 30,
    BT_PropertyElement = 31,
    BT_MethodsElement = 32,
    BT_MethodElement = 33,
    BT_Custom = 34,
    BT_ParameterElement = 35
}

return _M