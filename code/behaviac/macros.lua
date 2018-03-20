--- Behaviac lib Component: global macros.
-- @module macros.lua
-- @author n.lee
-- @copyright 2016
-- @license MIT/X11

NODE_FACTORY = {}

-- Localize
local cwd = (...):gsub('%.[^%.]+$', '') .. "."
local common = require(cwd .. "common")

local Logging                   = common.d_log

--------------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------
function REGISTER_NODE_CTOR(nodeName, ctor)
    assert(type(nodeName) == "string", string.format("REGISTER_NODE_CTOR param nodeName is not string (%s)", type(nodeName)))
    assert(type(ctor) == "function", string.format("REGISTER_NODE_CTOR param fun is not function (%s)", type(ctor)))

    if NODE_FACTORY[nodeName] then
        Logging.error("REGISTER_NODE_CTOR: error -- node(%s) duplicated!!!", nodeName)
        return
    end

    NODE_FACTORY[nodeName] = ctor
end

function REGISTER_NODE_CLASS(nodeName, nodeClass)
    assert(type(nodeName) == "string", string.format("REGISTER_NODE_CLASS param nodeName is not string (%s)", type(nodeName)))
    assert(type(nodeClass) == "table", string.format("REGISTER_NODE_CLASS param nodeClass is not table (%s)", type(nodeClass)))
    assert(type(nodeClass.new) == "function", string.format("REGISTER_NODE_CLASS param nodeClass has not new function"))

    if NODE_FACTORY[nodeName] then
        Logging.error("REGISTER_NODE_CLASS: error -- node(%s) duplicated!!!", nodeName)
        return
    end

    NODE_FACTORY[nodeName] = nodeClass.new
end

function FACTORY_CREATE_NODE(nodeName)
    if not NODE_FACTORY[nodeName] then
        Logging.error("FACTORY_CREATE_NODE: error -- node(%s) does not exist!!!", nodeName)
        return nil
    else
        return NODE_FACTORY[nodeName]()
    end
end

FATHER_CLASS_INFO = {}
BEHAVIAC_DYNAMIC_TYPES = {}
STATIC_BEHAVIAC_HierarchyLevels = setmetatable({}, {__index = function() return 0 end})

--------------------------------------------------------------------------------
-- log
--------------------------------------------------------------------------------
function ADD_BEHAVIAC_DYNAMIC_TYPE(className, classDeclare)
    if BEHAVIAC_DYNAMIC_TYPES[className] and BEHAVIAC_DYNAMIC_TYPES[className] ~= classDeclare then
        assert(false, "ADD_BEHAVIAC_DYNAMIC_TYPE had add different TYPE " .. className)
        return
    end
    classDeclare.__name = className
    classDeclare.getName = function(self) return self.__name or "no name" end
    BEHAVIAC_DYNAMIC_TYPES[className] = classDeclare
    REGISTER_NODE_CLASS(className, classDeclare)
end

function BEHAVIAC_INTERNAL_DECLARE_DYNAMIC_TYPE_COMPOSER(className)
    assert(BEHAVIAC_DYNAMIC_TYPES[className], string.format("BEHAVIAC_INTERNAL_DECLARE_DYNAMIC_TYPE_COMPOSER %s must be call ADD_BEHAVIAC_DYNAMIC_TYPE", className))

    BEHAVIAC_DYNAMIC_TYPES[className].sm_HierarchyLevel = 0
    BEHAVIAC_DYNAMIC_TYPES[className].getClassTypeName = function (self)
        return className
    end
end

function BEHAVIAC_INTERNAL_DECLARE_DYNAMIC_PUBLIC_METHODES(nodeClassName, fatherClassName)
    assert(BEHAVIAC_DYNAMIC_TYPES[nodeClassName], string.format("BEHAVIAC_INTERNAL_DECLARE_DYNAMIC_PUBLIC_METHODES %s must be call ADD_BEHAVIAC_DYNAMIC_TYPE", nodeClassName))
    assert(BEHAVIAC_DYNAMIC_TYPES[fatherClassName], string.format("BEHAVIAC_INTERNAL_DECLARE_DYNAMIC_PUBLIC_METHODES %s must be called after ADD_BEHAVIAC_DYNAMIC_TYPE", fatherClassName))

    STATIC_BEHAVIAC_HierarchyLevels[nodeClassName] = STATIC_BEHAVIAC_HierarchyLevels[fatherClassName] + 1 
    BEHAVIAC_DYNAMIC_TYPES[nodeClassName].sm_HierarchyLevel = STATIC_BEHAVIAC_HierarchyLevels[nodeClassName]

    local checkFunName = string.format("is%s", string.sub(nodeClassName, 2, -1))
    BEHAVIAC_DYNAMIC_TYPES[nodeClassName][checkFunName] = function() return true end
    local rootFatherName = fatherClassName
    local fName = fatherClassName
    while fName do
        fName = FATHER_CLASS_INFO[fName]
        if fName then
            rootFatherName = fName
        end
    end
    if rootFatherName then
        if not BEHAVIAC_DYNAMIC_TYPES[rootFatherName][checkFunName] then
            BEHAVIAC_DYNAMIC_TYPES[rootFatherName][checkFunName] = function() return false end
        end
    end


    BEHAVIAC_DYNAMIC_TYPES[nodeClassName].getClassHierarchyInfoDecl = function(self)
        Logging.error("getClassHierarchyInfoDecl ????????")
        return "getClassHierarchyInfoDecl"
    end

    BEHAVIAC_DYNAMIC_TYPES[nodeClassName].getHierarchyInfo = function(self)
        local decl = self:getClassHierarchyInfoDecl()
        if not decl.m_szCassTypeName then
            decl:InitClassLayerInfo(self:getClassTypeName(), BEHAVIAC_DYNAMIC_TYPES[fatherClassName]:getHierarchyInfo())
        end
        return decl
    end

    BEHAVIAC_DYNAMIC_TYPES[nodeClassName].getClassTypeId = function(self)
        Logging.error("getClassTypeId = %s", nodeClassName)
        return 1
    end

    BEHAVIAC_DYNAMIC_TYPES[nodeClassName].isClassAKindOf = function(self)
        return true
    end

    BEHAVIAC_DYNAMIC_TYPES[nodeClassName].dynamicCast = function(self, other)
        Logging.error("dynamicCast use is%s fun", string.sub(nodeClassName, 2, -1))
        return false
    end
end

function BEHAVIAC_ASSERT(check, msgFormat, ...)
    if not check then
        Logging.error("BEHAVIAC_ASSERT " .. msgFormat, ...)
        assert(false)
    end
end

-- same as C++ 
-- BEHAVIAC_DECLARE_DYNAMIC_TYPE is must be called after ADD_BEHAVIAC_DYNAMIC_TYPE
function BEHAVIAC_DECLARE_DYNAMIC_TYPE(nodeClassName, fatherClassName)
    FATHER_CLASS_INFO[nodeClassName] = fatherClassName
    BEHAVIAC_INTERNAL_DECLARE_DYNAMIC_TYPE_COMPOSER(nodeClassName)
    BEHAVIAC_INTERNAL_DECLARE_DYNAMIC_PUBLIC_METHODES(nodeClassName, fatherClassName)
end