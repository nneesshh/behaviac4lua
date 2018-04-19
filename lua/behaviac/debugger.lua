
local _M = {
	-- debugger settings
	enable_debugger = true,
	wait_on_startup = true,
	lib = false,
}

-- Localize
local cwd = (...):gsub('%.[^%.]+$', '') .. "."

-- startup
if _M.enable_debugger then
	_M.lib = require(cwd .. "debug.btdebugger")
	_M.lib.startDebugger(_M.wait_on_startup)
end

return _M