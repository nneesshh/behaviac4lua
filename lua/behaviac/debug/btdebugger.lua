-- use loaded modules or load explicitly on those systems that require that
local require = require
local io = io or require "io"
local table = table or require "table"
local string = string or require "string"
local unpack = table.unpack or unpack

local cwd = (...):gsub('%.[^%.]+$', '') .. "."
local socket = require(cwd .. "socket.socket")
local lpack = require("lpack")

-- protect require "os" as it may fail on embedded systems without os module
local os = os or (function(module)
  local ok, res = pcall(require, module)
  return ok and res or nil
end)("os")

-- check for OS and convert file names to lower case on windows
-- (its file system is case insensitive, but case preserving), as setting a
-- breakpoint on x:\Foo.lua will not work if the file was loaded as X:\foo.lua.
-- OSX and Windows behave the same way (case insensitive, but case preserving).
-- OSX can be configured to be case-sensitive, so check for that. This doesn't
-- handle the case of different partitions having different case-sensitivity.
local win = os and os.getenv and (os.getenv('WINDIR') or (os.getenv('OS') or ''):match('[Ww]indows')) and true or false
local mac = not win and (os and os.getenv and os.getenv('DYLD_LIBRARY_PATH') or not io.open("/proc")) and true or false
local iscasepreserving = win or (mac and io.open('/library') ~= nil)

local function _split_str(str, char)
  local ret = {}
  local e = 1
  local b = string.find(str, char, e)
  while b do
      table.insert(ret, string.sub(str, e, b - 1))
      e = b + 1
      b = string.find(str, char, e)
  end
  table.insert(ret, string.sub(str, e, -1))
  return ret
end

local function _normalize_path(file)
  local n
  repeat
    file, n = file:gsub("/+%.?/+","/") -- remove all `//` and `/./` references
  until n == 0
  -- collapse all up-dir references: this will clobber UNC prefix (\\?\)
  -- and disk on Windows when there are too many up-dir references: `D:\foo\..\..\bar`;
  -- handle the case of multiple up-dir references: `foo/bar/baz/../../../more`;
  -- only remove one at a time as otherwise `../../` could be removed;
  repeat
    file, n = file:gsub("[^/]+/%.%./", "", 1)
  until n == 0
  -- there may still be a leading up-dir reference left (as `/../` or `../`); remove it
  return (file:gsub("^(/?)%.%./", "%1"))
end

local function _makeVariableId(idStr)
  return lpack.crc32(idStr)
end

local _M = {
  _NAME = "btdebugger",
  _VERSION = "1.0",
  _COPYRIGHT = "n.lee",
  _DESCRIPTION = "Online debugger for behavior tree",
  
  m_enable = true,
  m_host = "*",
  m_port = 60636,

  m_server = false,
  m_client = false,
  m_running = false,
  m_seq = 0,
  m_frame = 0,

  m_texts = "",
  m_breakpoints = {},
  m_actions_count = {},
  m_profiling = false,
  m_applogFilter = false,
 }

 local constCommand = {
  kBreakpoint = "[breakpoint]",
  kProperty = "[property]",
  kProfiling = "[profiling]",
  kStart = "[start]",
  kAppLogFilter = "[applogfilter]",
  kContinue = "[continue]",
  kCloseConnection = "[closeconnection]",
  kHitNumber = "Hit=",

  kPlatform = "[platform] Windows \n",
  kWorkspace = "[workspace] xml \"\"\n",
}

local constCommandId = {
  CMDID_INITIAL_SETTINGS = 1,
  CMDID_TEXT = 2,
}

local constPlatform = {
  WINDOWS = 0
}

local constEActionResult = {
  EAR_none = 0,
  EAR_success = 1,
  EAR_failure = 2,
  EAR_all = 3
}

local constLogMode = {
  ELM_tick = 0,
  ELM_breaked = 1,
  ELM_continue = 2,
  ELM_jump = 3,
  ELM_return = 4,

  ELM_log = 5,
}

local kConstBufferLen = 2048

local function _reset()
  _M.m_client:close()
  _M.m_client = false
  _M.m_seq = 0
  _M.m_frame = 0
end

local function _sendInitialSettings()
  if _M.m_client then
    local peer = _M.m_client
    -- uint8_t	messageSize
    -- uint8_t	command
    -- uint8_t	platform
    -- uint32_t processId
    local messageSize = 1 + 1 + 4 -- command + platform + processId
    local processId = lpack.current_procid()
    local bytes = lpack.pack('<b3I', messageSize, constCommandId.CMDID_INITIAL_SETTINGS, constPlatform.WINDOWS, processId)
    local _, err = peer:send(bytes)
    if err == 'closed' then
      
    end
  end
end

local function _sendText(text)
  if _M.m_client then
    local peer = _M.m_client
    -- uint8_t	messageSize
    -- uint8_t	command
    -- string	  data
    -- uint32_t seq
    local messageSize = 1 + #text -- command + data
    local seq = _M.m_seq
    local bytes = lpack.pack('<b2A', messageSize, constCommandId.CMDID_TEXT, text)
    _M.m_seq = seq + 1
    local _, err = peer:send(bytes)
    if err == 'closed' then
      _reset()
    --else
    --  print("send text -- ", text)
    end
  end
end

local function _sendWorkspaceSettings()
  _sendText(constCommand.kPlatform)
  _sendText(constCommand.kWorkspace)
end

local function _sendInitialProperties()
  
end

local function _sendExistingPackets()
  
end

--void LogManager::Log(const behaviac::Agent* pAgent, const char* btMsg, behaviac::EActionResult actionResult, behaviac::LogMode mode) {
local function _sendBtMsg(agent, btMsg, actionResult, mode)
  if btMsg then
    local agentName = agent:getObjectTypeName() .. "#" ..agent:getInstanceName()
    local actionResultStr = ""

    if actionResult == constEActionResult.EAR_success then
      actionResultStr = "success"
    elseif actionResult == constEActionResult.EAR_failure then
      actionResultStr = "failure"
    else
      --//although actionResult can be EAR_none or EAR_all, but, as this is the real result of an action
      --//it can only be success or failure
      --//when it is EAR_none, it is for update
      if actionResult == constEActionResult.EAR_none and mode == constLogMode.ELM_tick then
        actionResultStr = "running"
      else
        actionResultStr = "none"
      end
    end

    if mode == constLogMode.ELM_continue then
      --//[continue]Ship::Ship_1 ships\suicide.xml->BehaviorTreeTask[0]:enter [all/success/failure] [1]
      local count = _M.getActionCount(btMsg)
      local buffer = string.format("[continue]%s %s [%s] [%d]\n", agentName, btMsg, actionResultStr, count)

      --this->Output(pAgent, buffer);
      _sendText(buffer)
    elseif mode == constLogMode.ELM_breaked then
      --//[breaked]Ship::Ship_1 ships\suicide.xml->BehaviorTreeTask[0]:enter [all/success/failure] [1]
      local count = _M.getActionCount(btMsg)
      local buffer = string.format("[breaked]%s %s [%s] [%d]\n", agentName, btMsg, actionResultStr, count)

      --this->Output(pAgent, buffer);
      _sendText(buffer)
    elseif mode == constLogMode.ELM_tick then
      --//[tick]Ship::Ship_1 ships\suicide.xml->BehaviorTreeTask[0]:enter [all/success/failure] [1]
      --//[tick]Ship::Ship_1 ships\suicide.xml->BehaviorTreeTask[0]:update [1]
      --//[tick]Ship::Ship_1 ships\suicide.xml->Selector[1]:enter [all/success/failure] [1]
      --//[tick]Ship::Ship_1 ships\suicide.xml->Selector[1]:update [1]
      local count = _M.updateActionCount(btMsg);

      if actionResultStr ~= "running" then
        local buffer = string.format("[tick]%s %s [%s] [%d]\n", agentName, btMsg, actionResultStr, count)

        --this->Output(pAgent, buffer);
        _sendText(buffer)
      end
    elseif mode == constLogMode.ELM_jump then
      local buffer = string.format("[jump]%s %s\n", agentName, btMsg)

      --this->Output(pAgent, buffer);
      _sendText(buffer)
    elseif mode == constLogMode.ELM_return then
      local buffer = string.format("[return]%s %s\n", agentName, btMsg);

      --this->Output(pAgent, buffer);
      _sendText(buffer)
    else
      assert(false)
    end
  end
end

local function _createServer(host, port)
  host = host or "*"
  port = port or _M.m_port
  return socket.bind(host, port)
end

local function _readNext(peer)
  local res, err, partial = peer:receive(kConstBufferLen)
  return res or partial or '', err
end

-- process texts
local function _readText() 
  local text = #_M.m_texts > 0 and _M.m_texts
  _M.m_texts = ""
  return text
end

function _M.receivePackets(msgCheck)
  if _M.m_client then
    local peer = _M.m_client
    peer:settimeout(0) -- non-blocking

    local bLoop = true
    local buf, err
    while bLoop do 
      buf, err = _readNext(peer)
      if buf and #buf > 0 then
        _M.m_texts = _M.m_texts .. buf
      else
        if err == 'closed' then
          _reset()
        end
        
        -- no more data
        bLoop = false
      end
    end

    peer:settimeout() -- back to blocking
  end
 
  if msgCheck then
    return _M.m_texts:find(msgCheck, 1, true)
  else
    return false
  end
end

function _M.receivePacketsTimeout(msgCheck, waitTime)
  if _M.m_client then
    local peer = _M.m_client
    waitTime = waitTime or 1 -- default block 1 seconds
    peer:settimeout(waitTime) 

    local bLoop = true
    local buf, err
    local count = 0
    while bLoop do 
      buf, err = _readNext(peer)
      if buf and #buf > 0 then
        _M.m_texts = _M.m_texts .. buf
        count = count + #buf
      else
        if err == 'closed' then
          _reset()

          -- closed
          bLoop = false
        elseif err == 'timeout' or count > 0 then
          -- timeout or no more data
          bLoop = false
        end
      end
    end

    peer:settimeout() -- back to blocking
  end
  
  if msgCheck then
    return _M.m_texts:find(msgCheck, 1, true)
  else
    return false
  end
end

local function _onConnection()
  --
  _sendInitialSettings()
  _sendWorkspaceSettings()
  _sendInitialProperties()
  _sendExistingPackets()

  --
  _sendText("[connected]precached message done")

  --
  while not bFound do
    local bFound = _M.receivePacketsTimeout(constCommand.kStart)
    if bFound then
      _M.handleRequests()
      break
    end
  end
end

local function _doAccept()
  local client, err = _M.m_server:accept()
  if client then
    _M.m_client = client
    _onConnection()
    print("[behaviac]connected.")
  else
    _reset()
  end
end

local function _doAcceptNonblocking()
  _M.m_server:settimeout(0) -- non-blocking

  local client, err = _M.m_server:accept()
  if client then
    _M.m_client = client
    _onConnection()
    print("[behaviac]connected.")
  elseif err == 'closed' then
    _reset()
  end

  _M.m_server:settimeout() -- back to blocking
end

function _M.startDebugger(bWaitOnStartup)
  if not _M.m_running then
    print("Start behavior tree debugger...")

    _M.m_running = true	
    _M.m_server = _createServer(_M.m_host, _M.m_port)

    if bWaitOnStartup then
      print("[behaviac]wait for the designer to connnect at port ...", _M.m_port)
      _doAccept()
    else
      print("[behaviac]debugger start on port ...", _M.m_port)
      _doAcceptNonblocking()
    end
  else
    print("Debugger is already started!!!")
  end
end

function _M.tryRestartDebugger()
  if _M.m_running then
    -- re-accept
    if not _M.m_client then
      _doAcceptNonblocking()
    end
  end
end

function _M.stopDebugger()
  if _M.m_running then
    _reset()
    _M.m_running = false
  end
end

--
--
--

--//[breakpoint] add TestBehaviorGroup\btunittest.xml->Sequence[3]:enter all Hit=1
--//[breakpoint] add TestBehaviorGroup\btunittest.xml->Sequence[3]:exit all Hit=1
--//[breakpoint] add TestBehaviorGroup\btunittest.xml->Sequence[3]:exit success Hit=1
--//[breakpoint] add TestBehaviorGroup\btunittest.xml->Sequence[3]:exit failure Hit=1
--//[breakpoint] remove TestBehaviorGroup\btunittest.x1ml->Sequence[3]:enter all Hit=10
--void Workspace::ParseBreakpoint(const behaviac::vector<behaviac::string>& tokens) {
local function _parseBreakpoint(tokens)
  local bp = {
    btname = false,
    hit_config = 0,
    action_result = constEActionResult.EAR_all
  }

  local bAdd = false
  local bRemove = false

  if tokens[2] == "add" then
    bAdd = true
  elseif tokens[2] == "remove" then
    bRemove = true
  else
    assert(false)
  end

  bp.btname = tokens[3]

  if tokens[4] == "all" then
    assert(bp.action_result == constEActionResult.EAR_all)
  elseif tokens[4] == "success" then
    bp.action_result = constEActionResult.EAR_success
  elseif tokens[4] == "failure" then
    bp.action_result = constEActionResult.EAR_failure
  else
    assert(false)
  end

  local pos_b, pos_e = tokens[5]:find(constCommand.kHitNumber, 1, true)
  if pos_b then
    pos_b = pos_e + 1
    
    local _, pos_e2 = tokens[5]:find('\n', pos_b, true)
    if pos_e2 then
      pos_e = pos_e2 - 1
    else
      pos_e = #tokens[5]
    end
    
    local numString = tokens[5]:sub(pos_b, pos_e)
    bp.hit_config = tonumber(numString)
  end

  local bpid = _makeVariableId(bp.btname)
  if bAdd then
    _M.m_breakpoints[bpid] = bp
  elseif bRemove then
    _M.m_breakpoints[bpid] = nil
  end
end

local function _parseProfiling(tokens)
  return (tokens[2] == "true")
end

local function _parseAppLogFilter(tokens)
  return tokens[2]
end

--//[property] WorldState::WorldState int WorldState::time->185606213
--//--[property] Ship::Ship_2_3 long GameObject::age->91291
--//[property] Ship::Ship_2_3 bool par_a->true
local function _parseProperty(tokens)
  local agentName = tokens[2]
  local pos_b, pos_e
  local size = 0

  --[[
  local agent = AgentMeta.getAgent(agentName)

  --//agent could be 0
  if agent and #tokens == 4 then
    local varNameValue = tokens[4]

    local pos_b = varNameValue:find("->", 1, true)
    if pos_b then
      --//varNameValue is the last one with '\n'
      local pos_e = varNameValue:find('\n', 1, true)
      if pos_e then
        size = pos_e - pos_b - 1
      end

      local varName = varNameValue:sub(1, pos_b + 1)
      local varValue = varNameValue:substr(pos_b + 3, size)

      --if agent then
        --agent->SetVariableFromString(varName, varValue)
      --end
    end
  end]]
end

function _M.handleRequests()
  local bContinue = false
  local buf, err = _M.receivePackets()
  local text = _readText()
  if text then
    -- commands
    local cs = _split_str(text, "\n")
    for i, c in ipairs(cs) do
      if c:len() > 0 then
        -- tokens
        local tokens = _split_str(c, " ")
        if tokens[1] == constCommand.kBreakpoint then
          _parseBreakpoint(tokens)
        elseif tokens[1] == constCommand.kProperty then
          _parseProperty(tokens)
        elseif tokens[1] == constCommand.kProfiling then
          _M.m_profiling = _parseProfiling(tokens)
        elseif tokens[1] == constCommand.kStart then
          -- clear
          _M.m_breakpoints = {}
          bContinue = true
        elseif tokens[1] == constCommand.kAppLogFilter then
          _M.m_applogFilter = _parseAppLogFilter(tokens)
        elseif tokens[1] == constCommand.kContinue then
          bContinue = true
        elseif tokens[1] == constCommand.kCloseConnection then
          -- clear
          _M.m_breakpoints = {}
          bContinue = true
        else
          assert(false)
        end
      end -- //end of if c:length() > 0
    end -- //end of for
  end -- //end of if text

  return bContinue
end

local function _getParentTreeName(agent, node)
  local btName

  if node:isReferencedBehavior() then
      node = node:getParent()
  end

  local bIsTree = false
  local bIsRefTree = false
  while node do
    bIsTree = node:isBehaviorTree()
    bIsRefTree = node:isReferencedBehavior()

    if bIsTree or bIsRefTree then
      break
    end

    node = node:getParent()
  end

  if bIsTree then
    btName = node:getName()
  elseif bIsRefTree then
    btName = refTree:getReferencedTreeName(agent)
  else
    assert(false)
  end

  return btName;
end

local function _getTickInfo(agent, node, action)
  if agent then
    local className = node:getClassNameString()

    --//filter out intermediate bt, whose class name is empty
    if #className > 0 then
      local btName = _getParentTreeName(agent, node)

      local nodeId = node:getId()
      --//TestBehaviorGroup\scratch.xml->EventetTask[0]:enter
      local bpstr = ""
      local temp

      if type(btName) == 'string' and string.len(btName) > 0 then
        temp = string.format("%s.xml->", btName)
        bpstr = bpstr .. temp
      end

      temp = string.format("%s[%i]", className, nodeId)
      bpstr = bpstr .. temp

      if type(action) == 'string' and string.len(action) > 0 then
        temp = string.format(":%s", action)
        bpstr = bpstr .. temp
      end

      return bpstr
    end
  end

  return ""
end

function _checkBreakpoint(agent, node, action, actionResult)
  local bpStr = _getTickInfo(agent, node, action)
  local bpid = _makeVariableId(bpStr)

  local bp = _M.m_breakpoints[bpid]
  if bp then

    local bHit = false
    if bp.action_result == constEActionResult.EAR_none then
      bHit = false
    elseif bp.action_result == constEActionResult.EAR_EAR_success or bp.action_result == constEActionResult.EAR_failure then
      bHit = (actionResult == bp.action_result or actionResult == constEActionResult.EAR_all)
    elseif bp.action_result == constEActionResult.EAR_all then
      bHit = true
    end

    if bHit then
      local count = _M.getActionCount(bpStr)

      if bp.hit_config == 0 or bp.hit_config == count then
        return true
      end
    end
  end

  return false
end

local function _waitforContinue()
  while true do
    local bLoop = _M.m_client and not _M.handleRequests()
    if not bLoop  then 
      break
    end
    
    -- wait 0.1 seconds
    _M.receivePacketsTimeout(nil, 0.1)
  end
end

--//CheckBreakpoint should be after log of onenter/onexit/update, as it needs to flush msg to the client
-- void CHECK_BREAKPOINT(Agent* pAgent, const BehaviorNode* b, const char* action, EActionResult actionResult) {
function _M.CHECK_BREAKPOINT(agent, node, action, result)
  local bpstr = _getTickInfo(agent, node, action);
 
  if bpstr then
    local actionResult = result and constEActionResult.EAR_success or constEActionResult.EAR_failure
    _sendBtMsg(agent, bpstr, actionResult, constLogMode.ELM_tick);

    if _checkBreakpoint(agent, node, action, actionResult) then
      --//log the current variables, otherwise, its value is not the latest
      --pAgent->LogVariables(false);
      _sendBtMsg(agent, bpstr, actionResult, constLogMode.ELM_breaked);
      --LogManager::GetInstance()->Flush(pAgent);
      --behaviac::Socket::Flush();

      --
      _waitforContinue()

      _sendBtMsg(agent, bpstr, actionResult, constLogMode.ELM_continue);
      --LogManager::GetInstance()->Flush(pAgent);
      --behaviac::Socket::Flush();
    end
  end
end

function _M.checkAppLogFilter(filter)
  --//m_applogFilter is UPPER
  if #_M.m_applogFilter > 0 then
    if _M.m_applogFilter == "ALL" then
      return true
    else
      local f = filter
      f = string.upper(f)
      if _M.m_applogFilter == f then
        return true
      end
    end
  end

  return false
end

function _M.updateActionCount(actionStr)
  local action = _makeVariableId(actionStr)
  local count = _M.m_actions_count[action] or 0
  count = count + 1
  _M.m_actions_count[action] = count
  return count
end

function _M.getActionCount(actionStr) 
  local action = _makeVariableId(actionStr)
  return _M.m_actions_count[action] or 0

end

-- void Workspace::LogFrames()
function _M.logFrames()
  _M.m_frame = _M.m_frame + 1

  if _M.m_client then
    local buffer = string.format("[frame]%d\n", _M.m_frame);

    --this->Output(pAgent, buffer);
    _sendText(buffer)
  end
end

function _M.logJumpTree(agent, newTree)
  if _M.m_client then
    local msg = newTree .. ".xml"
    _sendBtMsg(agent, msg, constEActionResult.EAR_none, constLogMode.ELM_jump)
  end
end

function _M.logReturnTree(agent, returnFromTree)
  if _M.m_client then
    local msg = returnFromTree .. ".xml"
    _sendBtMsg(agent, msg, constEActionResult.EAR_none, constLogMode.ELM_return)
  end
end

function _M.logUpdate(agent, node)
  if _M.m_client then
    local btStr = _getTickInfo(agent, node, "update")

    -- //empty btStr is for internal BehaviorTreeTask
    if type(btStr) == 'string' and #btStr > 0 then
      _sendBtMsg(agent, btStr, constEActionResult.EAR_none, constLogMode.ELM_tick)
    end
  end
end

return _M