--- Behaviac lib Component: blackboard of agent.
-- @module Blackboard.lua
-- @author n.lee
-- @copyright 2016
-- @license MIT/X11

-- Class
local Blackboard = class("Blackboard")
_G.ADD_BEHAVIAC_DYNAMIC_TYPE("Blackboard", Blackboard)
local _M = Blackboard

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- ctor
function _M:ctor(agent)
    self.m_agent       = agent
    self.m_baseMemory  = { localVars = {} }
    self.m_treeMemory  = { }
end

function _M.s_getNodeMem(treeMem, nodeScope) 
    local memory = treeMem.nodeMemory
    if nil == memory[nodeScope] then
        memory[nodeScope] = {}
    end
    return memory[nodeScope]
end

function _M.s_setTreeNode(treeMem, key, value, nodeScope) 
    local nodeMem = _M.s_getNodeMem(treeMem, nodeScope)
    nodeMem[key] = value
end

function _M.s_getTreeNode(treeMem, key, nodeScope) 
    local nodeMem = _M.s_getNodeMem(treeMem, nodeScope)
    return nodeMem[key]
end

function _M:setLocalVariable(varName, value) 
    local memory = self.m_baseMemory.localVars
    memory[varName] = value
end

function _M:addLocalVariables(vars)
    if vars then
        local memory = self.m_baseMemory.localVars
         for varName, value in pairs(vars) do
            memory[varName] = value
         end
    end
end

function _M:getLocalVariable(varName)
    local memory = self.m_baseMemory.localVars
    return memory[varName]
end

function _M:getTreeMemory(treeScope) 
    if nil == self.m_treeMemory[treeScope] then
        self.m_treeMemory[treeScope] = { nodeMemory = {} }
    end
    return self.m_treeMemory[treeScope]
end

function _M:getMemory(treeScope, nodeScope) 
    local memory = self.m_baseMemory

    if treeScope then
        local treeMem = self:getTreeMemory(treeScope)
        memory = treeMem
        if nodeScope then
            local nodeMem = _M.s_getNodeMem(treeMem, nodeScope)
            memory = nodeMem
        end
    end

    return memory
end

-- Stores a value in the blackboard. If treeScope and nodeScope are
-- provided, this method will save the value into the per node per tree
-- memory. If only the treeScope is provided, it will save the value into
-- the per tree memory. If no parameter is provided, this method will save
-- the value into the global memory. Notice that, if only nodeScope is
-- provided (but treeScope not), this method will still save the value into
-- the global memory.
--
-- @method set
-- @param {String} key The key to be stored.
-- @param {String} value The value to be stored.
-- @param {String} treeScope The tree id if accessing the tree or node
--                           memory.
-- @param {String} nodeScope The node id if accessing the node memory.
function _M:set(key, value, treeScope, nodeScope) 
    local mem = self:getMemory(treeScope, nodeScope)
    mem[key] = value  
end

function _M:get(key, treeScope, nodeScope) 
    local mem = self:getMemory(treeScope, nodeScope);
    return mem[key];
end

return _M