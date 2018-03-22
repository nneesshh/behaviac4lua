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

return _M