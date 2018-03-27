--- Behaviac lib Component: lib loader.
-- @module loader.lua
-- @author n.lee
-- @copyright 2016
-- @license MIT/X11

local _M = {
	FILE_TYPE_UNKNOWN = 0,
	FILE_TYPE_BSON_BYTES = 1,
	FILE_TYPE_JSON = 2,
	FILE_TYPE_LUA = 3
}

-- Localize
local pdir = (...):gsub('%.[^%.]+%.loader$', '') .. "."
local cwd   = (...):gsub('%.loader$', '') .. "."
local lib_bson = require(pdir .. "external.bson")
local lib_json = require(pdir .. "external.json")

local function open_binary(filepath)
	return io.open(filepath, "rb")
end

local function load_from_file(filepath)
	local f, err = io.open(filepath, "r")
	if f then
		local contents = f:read("*a")
		io.close(f)
		f = nil
		return contents
	end
end

local function load_bson_bytes(path)
	local f, err = open_binary(path)
	if f then
		local doc = lib_bson.readDocument(f)
		io.close(f)
		return doc
	end
end

local function load_json(path)
	local contents = load_from_file(path)
	if contents then
		local data, _, msg = lib_json:decode(contents) -- Ignore the second value - it's the character the issue was found on
		return data
	end
end

local function load_lua(path)
	local luaName = path:match("^[%.]?[/]?(.+)%.[^%./]-$"):gsub("/", ".")
	local success, data = pcall(require, luaName)
	if success then
		return data
	end
end

local constFileType = {
	{ ".bson.bytes", _M.FILE_TYPE_BSON_BYTES, load_bson_bytes },
	{ ".json", _M.FILE_TYPE_JSON, load_json },
	{ ".lua", _M.FILE_TYPE_LUA, load_lua },
}

function _M.getBehaviorTreeBaseName(treeName)
	for _, v in ipairs(constFileType) do
		local posStart, _ = string.find(treeName, v[1].."$")
		if posStart then
			return string.sub(treeName, 1, posStart-1)
		end
	end
	return treeName
end

local function loadIter(t, index)

end

-- Load 
function _M.load(path)
	local result = false
	for _, v in ipairs(constFileType) do
		result = v[3](path .. v[1])
		if result then
			return result, v[2]
		end
	end
	return nil, _M.FILE_TYPE_UNKNOWN
end

return _M