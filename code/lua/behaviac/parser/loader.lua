--- Behaviac lib Component: lib_loader.
-- @module loader.lua
-- @author n.lee
-- @copyright 2016
-- @license MIT/X11

local _M = {}

--------------------------------------------------------------------------------
-- Localize
--------------------------------------------------------------------------------
local pdir = (...):gsub('%.[^%.]+%.loader$', '') .. "."
local cwd   = (...):gsub('%.loader$', '') .. "."
local lib_json = require(pdir .. "external.json")

local function load_from_file(filepath)
	local contents
	local file, err = io.open(filepath, "r")
	if err then
		print("[load_from_file()] open file(" .. filepath .. ") error -- " .. err)
	elseif file then
		contents = file:read("*a")
		io.close(file)
		file = nil
	end
	return contents
end

--------------------------------------------------------------------------------
-- Load Map Data
--------------------------------------------------------------------------------
function _M.load(path)
	local extension = path:match("%.[^%./]-$") or "[no extension]"
	if extension ~= ".json" and extension ~= ".lua" then
		error("Unsupported file extension " .. extension .. ".")
	end

	------------------------------------------------------------------------------
	-- Load JSON
	------------------------------------------------------------------------------
	if extension == ".json" then
		local contents = load_from_file(path)
		local data, _, msg = lib_json:decode(contents) -- Ignore the second value - it's the character the issue was found on

		if not data then
			error("Failed to parse JSON data '" .. path .. "'")
		end

		return data

	------------------------------------------------------------------------------
	-- Load Lua
	------------------------------------------------------------------------------
	elseif extension == ".lua" then
		local luaName = path:match("^[%.]?[/]?(.+)%.[^%./]-$"):gsub("/", ".")
		local success, result = pcall(require, luaName)

		if not success then
			error("Failed to load Lua data from map '" .. filename .. "'")
		end

		return result
	end -- No need to check for other extensions because we already safeguarded with a check earlier

	return data
end

return _M