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

function _M.testFileType(path)
	local extensionName, fileType, loadFunc, pathBase
	for _, v in ipairs(constFileType) do
		extensionName = v[1]
		fileType = v[2]
		loadFunc = v[3]
		local posStart, _ = string.find(path, extensionName.."$")
		if posStart then
			pathBase = string.sub(path, 1, posStart - 1)
			return extensionName, fileType, loadFunc, pathBase
		end
	end
	return false, _M.FILE_TYPE_UNKNOWN
end

local function try_load_by_auto_match_file_type(pathBase)
	local data = nil
	local extensionName, fileType, loadFunc
	for _, v in ipairs(constFileType) do
		extensionName = v[1]
		fileType = v[2]
		loadFunc = v[3]
		data = loadFunc(pathBase .. extensionName)
		if data then
			return data, fileType
		end
	end
	return false, _M.FILE_TYPE_UNKNOWN
end

-- Load 
function _M.load(pathBase)
	return try_load_by_auto_match_file_type(pathBase)
end

return _M