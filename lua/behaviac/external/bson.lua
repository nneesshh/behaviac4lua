--
-- Pure Lua (5.1) implementation of BSON
--
--
-- Copyright (c) 2013, Todd Coram. All rights reserved.
-- See LICENSE for details.
--

function ppp(t, d, e)
  if e == nil then
    e = ''
  end
  
  e = e .. '  '
  
  print('tab', t)
  if type(d) == 'string' then
    print('index', 'value', 'char code')
    for i=1,#d do
      print(i, d:sub(i,i), string.byte(d:sub(i,i)))
    end
  elseif type(d) == 'table' then
    print('index', 'value', 'char code')
    for i,j in pairs(d) do
      if type(j) == 'table' then
        ppp(t .. ' - ' .. i, j, e)
      else
        if type(j) == 'boolean' then
          code = 'bool'
        else
          code = string.byte(j)
        end
        print(i, j, code)
      end
    end
  else
    print(d)
  end
  if #e == 2 then
    print('')
  end
end

local bson = {}

-- Helper functions

local function toLSB(bytes,value)
  local str = ""
  for j=1,bytes do
     str = str .. string.char(value % 256)
     value = math.floor(value / 256)
  end
  return str
end

local function toLSB16(value) return toLSB(2,value) end
local function toLSB32(value) return toLSB(4,value) end
local function toLSB64(value) return toLSB(8,value) end

local function fromLSB8(s,p)
  return s:byte(p), p+1
end

local function fromLSB16(s,p)
  return s:byte(p) + (s:byte(p+1)*256), p+2
end

local function fromLSB32(s,p)
  return s:byte(p) + (s:byte(p+1)*256) + 
  (s:byte(p+2)*65536) + (s:byte(p+3)*16777216), p+4
end

local function fromLSB64(s,p)
  return fromLSB32(s,p) +
  (s:byte(p+4)*4294967296) + (s:byte(p+5)*1099511627776) +
  (s:byte(p+6)*2.8147497671066e+14) + (s:byte(p+7)*7.2057594037928e+16), p+8
end

local function to_double(value)
  local buffer = ''
  local float64 = {}
  local bias = 1023
  local max_bias = 2047
  local sign = nil
  local exponent_length = 11
  local mantissa = 0
  local mantissa_length = 52

  -- Sign 1 if value is negative and 0 otherwise
  if value < 0 then
    sign = 1
  else
    sign = 0
  end
  
  -- Avoid log of negative numbers
  value = math.abs(value)
  
  -- 2 to the power of what gives value
  local exponent = math.floor(math.log(value) / math.log(2))
  local flag = math.pow( 2, -exponent )
  
  if value * flag < 1 then
    exponent = exponent - 1
    flag = flag * 2
  end
  
  if value * flag >= 2 then
    exponent = exponent + 1
    flag = flag / 2;
  end

  if exponent + bias >= max_bias then -- Very big
    exponent = max_bias
  elseif exponent + bias >= 1 then -- Most of the time will fall here
    mantissa = (value * flag - 1) * math.pow(2, mantissa_length)
    exponent = exponent + bias
  else -- Very tiny
    mantissa = value * math.pow(2, bias - 1) * math.pow(2, mantissa_length);
    exponent = 0
  end

  while mantissa_length >= 8  do
    table.insert(float64, math.floor(mantissa % 256))
    mantissa = mantissa / 256
    mantissa_length = mantissa_length - 8
  end
  
  exponent = math.floor(exponent * math.pow(2, mantissa_length) + mantissa);
  exponent_length = exponent_length + mantissa_length;
  
  while exponent_length > 0  do
    table.insert(float64, math.floor(exponent % 256))
    exponent = exponent / 256
    exponent_length = exponent_length - 8
  end
  
  float64[8] = float64[8] + (sign * 128);

  for i, value in pairs(float64) do
    buffer = buffer .. string.char(value)
  end
  
  return buffer
end


-- BSON generators
--

function bson.to_bool(n,v) 
  local pre = "\008"..n.."\000"
  if v then
     return pre.."\001"
  else
     return pre.."\000"
  end
end

function bson.to_str(n,v) return "\002"..n.."\000"..toLSB32(#v+1)..v.."\000" end
function bson.to_int32(n,v) return "\016"..n.."\000"..toLSB32(v) end
function bson.to_int64(n,v) return "\018"..n.."\000"..toLSB64(v) end
function bson.to_double(n,v) return "\001"..n.."\000"..to_double(v) end
function bson.to_x(n,v) return v(n) end

function bson.utc_datetime(t)
  local t = t or (os.time()*1000)
  f = function (n)
     return "\009"..n.."\000"..toLSB64(t)
  end
  return f
end

-- Binary subtypes
bson.B_GENERIC  = "\000"
bson.B_FUNCTION = "\001"
bson.B_UUID     = "\004"
bson.B_MD5      = "\005"
bson.B_USER_DEFINED = "\128"

function bson.binary(v, subtype)
  local subtype = subtype or bson.B_GENERIC
  f = function (n) 
     return "\005"..n.."\000"..toLSB32(#v)..subtype..v
  end
  return f
end

function bson.to_num(n,v)
  if v == math.huge then
    return "\001"..n.."\000\000\000\000\000\000\000\240\127"
  elseif v == -math.huge then
    return "\001"..n.."\000\000\000\000\000\000\000\240\255"
  elseif v ~= v then -- NaN
    return "\001"..n.."\000\001\000\000\000\000\000\240\127"
  end

  if math.floor(v) ~= v then
    return bson.to_double(n,v)
  elseif v > 2147483647 or v < -2147483648 then
    return bson.to_int64(n,v)
  else
    return bson.to_int32(n,v)
  end
end

function bson.to_doc(n,doc)
  local d=bson.start()
  local docType = "\003"
  for cnt,v in ipairs(doc) do
     local t = type(v)
     local o = lua_to_bson_tbl[t](tostring(cnt-1),v)
     d = d..o
     docType = "\004"
  end
  -- do this only if we don't have an array (enumerated pairs)
  if d == "" then
     for nm,v in pairs(doc) do
  local t = type(v)
  local o = lua_to_bson_tbl[t](nm,v)
  d = d..o
     end
  end
  return docType..n.."\000"..bson.finish(d)
end


-- Mappings between lua and BSON.
-- "function" is a special catchall for non-direct mappings.
--
lua_to_bson_tbl= {
  boolean = bson.to_bool,
  string = bson.to_str,
  number = bson.to_num,
  table = bson.to_doc,
  ["function"] = bson.to_x
}

-- BSON document creation.
--
function bson.start() return "" end

function bson.finish(doc) 
  doc = doc .. "\000"
  return toLSB32(#doc+4)..doc
end

function bson.encode(doc)
  local d=bson.start()
  for e,v in pairs(doc) do
     local t = type(v)
     local o = lua_to_bson_tbl[t](e,v)
     d = d..o
  end
  return bson.finish(d)
end


-- BSON parsers

function bson.from_bool(doc, startPos)
  return doc:byte(startPos) == 1, startPos+1
end

function bson.from_int16(doc, startPos)
  return fromLSB16(doc, startPos)
end

function bson.from_int32(doc, startPos)
   return fromLSB32(doc, startPos)
end

function bson.from_int64(doc, startPos)
   return fromLSB64(doc, startPos)
end

function bson.from_double(doc, startPos)
  local buffer = {}
  local bias = 1023
  local last = 0
  local sign = 1
  
  -- Create a reverse version of the buffer
  for i=1, 8 do
    last = 8 - (i - 1)
    buffer[i] = string.byte(doc:sub(startPos+last-1, startPos+last-1))
  end
  
  -- If the first bit is 1 turn sign to -1
  if math.floor(buffer[1] / math.pow(2, 7)) > 0 then
    sign = -1
  end
  
  -- Take the last 7 bits
  local exponent = math.floor(buffer[1] % 128)
  -- Left shift 8 bits and sum with the seconds octect
  exponent = exponent * 256 + buffer[2]
  
  -- Take the last 4 bits
  local mantissa = math.floor(exponent % 16)
  
  -- Right shift 4 bits
  exponent = math.floor(exponent / math.pow(2, 4))
  
  -- Read the buffer as int32 value
  for i=3, 8 do
    mantissa = mantissa * 256 + buffer[i]
  end

  if exponent == 0 then -- Very tiny
    exponent = 1 - bias
  elseif exponent == 2047 then -- Very big
    if mantissa > 0 then
      return 0 / 0 -- Not a number
    else
      return sign * (1 / 0) -- Positive or negative infinite
    end
  else -- Most of the time will fall here
    mantissa = mantissa + 4503599627370496
    exponent = exponent - bias
  end
  
  return sign * mantissa * math.pow(2, exponent - 52), startPos+8
end

function bson.from_utc_date_time(doc, startPos)
  return fromLSB64(doc, startPos)
end

function bson.from_binary(doc, startPos)
  local len, nextPos = fromLSB32(doc, startPos)
  local str = doc:sub(nextPos+1, nextPos+1+len-1)
  return str, nextPos+1+len
end


function bson.from_str(doc, startPos)
  local len, nextPos = fromLSB32(doc, startPos)
  local str = doc:sub(nextPos, nextPos+len-2)
  return str, nextPos+len
end

function bson.decode_doc(doc, startPos, docType)
  local len, nextPos = bson.from_int32(doc, startPos)
  return bson.decode_doc_(len, doc, nextPos, docType)
end

function bson.decode_doc_(len, doc, startPos, docType)
  local luatab = {}
  local nextPos = startPos
  local val, ename, etype
  repeat
    etype, nextPos = fromLSB8(doc, nextPos)
    if etype == 0 then
      break
    elseif not bson_to_lua_tbl[etype] then
      val, nextPos = bson.readUnknownElement(doc, nextPos, etype)
    else
      ename = doc:match("(%Z+)\000",nextPos)
      nextPos = nextPos+#ename+1
      val, nextPos = bson_to_lua_tbl[etype](doc, nextPos, etype)
    end
    
    -- ppp('val', val)
    -- ppp('doc', doc)
    
    if docType == 4 or not ename then
      table.insert(luatab,val)
    else
      luatab[ename] = val
    end
  until not doc
  return luatab, nextPos
end

bson_to_lua_tbl= {
  [1]  = bson.from_double, -- Double
  [2]  = bson.from_str, -- String
  [16] = bson.from_int32,
  [18] = bson.from_int64,
  [8]  = bson.from_bool,
  [3]  = bson.decode_doc, -- Object
  [4]  = bson.decode_doc, -- Array
  [5]  = bson.from_binary, -- Binary data
  [9]  = bson.from_utc_date_time,
  --[11] = bson.form_regex, -- Regular Expression
  --[19] = bson.from_float, -- standard of BSON Types == "Decimal128"
}

function bson.decode(len, doc)
  return bson.decode_doc_(len, doc, 1, nil)
end

function bson.decode_next_io(fd)
  local slen = fd:read(4)
  if not slen then return nil end
  local len, _ = fromLSB32(slen, 1) - 4
  local doc = fd:read(len)
  return bson.decode(len, doc)
end

function bson.readUnknownElement(doc, startPos, etype)
  local len, nextPos = bson.from_int32(doc, startPos)
  local val = {
    ["is_undefined"] = true,
    ["etype"] = etype,
    ["data"] = doc:sub(nextPos, nextPos+len-4-2)
  }
  return val, nextPos+len-4
end

function bson.readDocument(fd)
  local slen = fd:read(4)
  if not slen then return nil end
  local len, _ = fromLSB32(slen, 1) - 4
  local doc = fd:read(len)
  return doc, len
end

function bson.readByte(s,p)
  return fromLSB8(s,p)
end

function bson.readBool(s,p)
  return bson.from_bool(s,p)
end

function bson.readInt16(s,p)
  return fromLSB16(s,p)
end

function bson.readInt32(s,p)
  return fromLSB32(s,p)
end

function bson.readString(s,p)
  local len, nextPos = fromLSB16(s,p)
  local str = s:sub(nextPos, nextPos+len-2)
  return str, nextPos+len
end

return bson