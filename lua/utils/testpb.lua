--
require "bootstrap"

--local pvp_pb = require("table.Pvp_pb")

--------------------------------------------------------------------------------
-- run_test_c_frame_list
--------------------------------------------------------------------------------
local run_test_c_frame_list = function(c_frame_list)
	local frameid
	local now = os.clock()
	local num = 1000000
	
	print("run_test_c_frame_list() start-------------------------------"..tostring(now))
	for i = 1, num do
		for j = 0, c_frame_list:list_size() - 1 do 
			local frame = c_frame_list:list(j)
			local start = frame:frameid()
			local to = frame:frameid() + 100
			local frame_state = frame:frame_state()
			
			frameid = frame:frameid()
			for k = start, to do
				-- nop()
			end
		end
	end
	
	local elapsed = os.clock() - now
	print("run_test_c_frame_list() elapsed-------------------------------"..tostring(elapsed))
	print("run_test_c_frame_list() over, frameid="..string.format("frameid(%u), per_second_num(%0.2f)", frameid, num / elapsed))
end

--------------------------------------------------------------------------------
-- run_test_lua_frame_list
--------------------------------------------------------------------------------
local run_test_lua_frame_list = function(lua_frame_list)
	local frameid
	local now = os.clock()
	local num = 1000000
	local lua_card = pvp_pb.Card()
	
	print("run_test_lua_frame_list() start-------------------------------"..tostring(now))
	for i = 1, num do
		for _,v in ipairs(lua_frame_list.list) do 
			local frame = v
			local start = frame.frameid
			local to = frame.frameid + 100
		
			frameid = frame.frameid
			for k = start, to do
				-- nop()
			end
		end
	end
	
	local elapsed = os.clock() - now
	print("run_test_lua_frame_list() elapsed-------------------------------"..tostring(elapsed))
	print("run_test_lua_frame_list() over, frameid="..string.format("frameid(%u), per_second_num(%0.2f)", frameid, num / elapsed))
end

--------------------------------------------------------------------------------
-- test_pb
--------------------------------------------------------------------------------
test_pb = function(c_frame_list)
	--[[
	local lua_frame_list = pvp_pb.CombatFrameList()
	local lua_frame = pvp_pb.CombatFrame()
	lua_frame.frameid = 1234567
	lua_frame_list.list:add(lua_frame)
	
	run_test_lua_frame_list(lua_frame_list)
	]]

	print("================")
	print("========")
	print("====")
	print("==")
	print("=")

	run_test_c_frame_list(c_frame_list)
end

