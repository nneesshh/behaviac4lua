--- Behavior3 lib Component: lib util
-- @module util.lua
-- @author n.lee
-- @copyright 2016
-- @license MIT/X11

local lib_util = {}

-- Localize
local cwd = (...):gsub('%.[^%.]+$', '') .. "."
local rand = math.random

local _M = lib_util

_M.createUUID = function()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and rand(0, 0xf) or rand(8, 0xb)
        return string.format('%x', v)
    end)
end

_M.makeReadOnly = function(t)  
    local proxy = {}  --定义一个空表，访问任何索引都是不存在的，所以会调用__index 和__newindex  
    local mt = {  
        __index = t, ---__index 可以是函数，也可以是table，是table的话，调用直接返回table的索引值  
        __newindex = function(t,k,v)  
        error("attempt to update a read-only table",2)  
    end  
    }  
    setmetatable(proxy,mt)  
    return proxy  
end  

--[[
local function testReadOnly()
    local days = readOnly{"Sunday","Monday","Tuesday","Wednessday","Thursday","Friday","Saturday"}   
    print(days[1])
    table.insert(days, "xxxxxxxxxxxxxxxx") --error in lua5.3, but not in lua5.1
    days[2] = "hello" --error
end
testReadOnly()
]]

return _M