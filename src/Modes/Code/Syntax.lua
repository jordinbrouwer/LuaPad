LuaPad = LuaPad or {}

local find, sub = string.find, string.sub

local KEYWORD = "|cffc792ea"
local STRING = "|cffa5d6a7"
local NUMBER = "|cfff2a65a"
local COMMENT = "|cff6b7280"
local API = "|cff7aa2f7"

local KEYWORDS = {}
for word in ([[and break do else elseif end for function if in local not or repeat return then until while]]):gmatch("%a+") do
  KEYWORDS[word] = true
end
local CONSTANTS = { ["true"] = true, ["false"] = true, ["nil"] = true }

function LuaPad.Highlight(s)
  local out, n = {}, 0
  local len = #s
  local i = 1

  local function Add(color, text)
    n = n + 1
    if find(text, "|", 1, true) then text = text:gsub("|", "||") end
    out[n] = color and (color .. text .. "|r") or text
  end

  while i <= len do
    local a, b = find(s, "^%s+", i)
    if a then
      Add(nil, sub(s, a, b))
      i = b + 1
    else
      local c = sub(s, i, i)
      local stop
      if c == "-" and sub(s, i + 1, i + 1) == "-" then
        local ls, le, eq = find(s, "^%[(=*)%[", i + 2)
        if ls then
          local _, ce = find(s, "]" .. eq .. "]", le + 1, true)
          stop = ce or len
        else
          local _, e = find(s, "^[^\n]*", i)
          stop = e
        end
        Add(COMMENT, sub(s, i, stop))
        i = stop + 1
      elseif c == "[" and find(s, "^%[=*%[", i) then
        local _, le, eq = find(s, "^%[(=*)%[", i)
        local _, ce = find(s, "]" .. eq .. "]", le + 1, true)
        stop = ce or len
        Add(STRING, sub(s, i, stop))
        i = stop + 1
      elseif c == '"' or c == "'" then
        local pattern = c == '"' and '[\\"\n]' or "[\\'\n]"
        local j = i + 1
        while true do
          local p = find(s, pattern, j)
          if not p then stop = len break end
          local ch = sub(s, p, p)
          if ch == "\\" then
            j = p + 2
          elseif ch == "\n" then
            stop = p - 1 break
          else
            stop = p break
          end
        end
        Add(STRING, sub(s, i, stop))
        i = stop + 1
      elseif find(s, "^%d", i) or (c == "." and find(s, "^%.%d", i)) then
        local _, e = find(s, "^0[xX]%x+", i)
        if not e then
          _, e = find(s, "^%d*%.?%d*", i)
          local _, ee = find(s, "^[eE][%+%-]?%d+", e + 1)
          if ee then e = ee end
        end
        Add(NUMBER, sub(s, i, e))
        i = e + 1
      elseif find(s, "^[%a_]", i) then
        local _, e = find(s, "^[%a_][%w_]*", i)
        local word = sub(s, i, e)
        local prev = sub(s, i - 1, i - 1)
        if prev == "." or prev == ":" then
          Add(nil, word)
        elseif KEYWORDS[word] then
          Add(KEYWORD, word)
        elseif CONSTANTS[word] then
          Add(NUMBER, word)
        elseif type(_G[word]) == "function" then
          Add(API, word)
        else
          Add(nil, word)
        end
        i = e + 1
      else
        local _, e = find(s, "^[^%w_%s\"'%[%-%.]+", i)
        if e then
          Add(nil, sub(s, i, e))
          i = e + 1
        else
          Add(nil, c)
          i = i + 1
        end
      end
    end
  end
  return table.concat(out)
end

LuaPad.Colorize = LuaPad.Highlight

-- The edit box holds coloured text. Cursor positions there are chars; Lua strings index bytes.
local UTF8_CHAR = "[%z\1-\127\194-\244][\128-\191]*"

local function CharToByte(s, n)
  if n <= 0 then return 0 end
  if not find(s, "[\128-\255]") then return math.min(n, #s) end
  local bytes, count = 0, 0
  for ch in s:gmatch(UTF8_CHAR) do
    bytes, count = bytes + #ch, count + 1
    if count == n then return bytes end
  end
  return #s
end

local function ByteToChar(s, b)
  if b <= 0 then return 0 end
  if not find(s, "[\128-\255]") then return math.min(b, #s) end
  local bytes, count = 0, 0
  for ch in s:gmatch(UTF8_CHAR) do
    if bytes + #ch > b then break end
    bytes, count = bytes + #ch, count + 1
  end
  return count
end

local function StripRaw(raw)
  local out, n, i, len = {}, 0, 1, #raw
  while i <= len do
    local c = sub(raw, i, i)
    if c == "|" then
      local nx = sub(raw, i + 1, i + 1)
      if nx == "|" then
        n = n + 1; out[n] = "|"; i = i + 2
      elseif nx == "c" and find(raw, "^|c%x%x%x%x%x%x%x%x", i) then
        i = i + 10
      elseif nx == "r" then
        i = i + 2
      else
        n = n + 1; out[n] = "|"; i = i + 1
      end
    else
      local _, e = find(raw, "^[^|]+", i)
      n = n + 1; out[n] = sub(raw, i, e); i = e + 1
    end
  end
  return table.concat(out)
end

function LuaPad.Strip(raw, cursor)
  local plain = StripRaw(raw)
  if cursor == nil then return plain end
  return plain, #StripRaw(sub(raw, 1, CharToByte(raw, cursor)))
end

function LuaPad.MapToColored(raw, target)
  if target <= 0 then return 0 end
  local i, plainLen, len = 1, 0, #raw
  while i <= len and plainLen < target do
    local c = sub(raw, i, i)
    if c == "|" then
      local nx = sub(raw, i + 1, i + 1)
      if nx == "|" then
        plainLen = plainLen + 1; i = i + 2
      elseif nx == "c" and find(raw, "^|c%x%x%x%x%x%x%x%x", i) then
        i = i + 10
      elseif nx == "r" then
        i = i + 2
      else
        plainLen = plainLen + 1; i = i + 1
      end
    else
      local _, e = find(raw, "^[^|]+", i)
      local take = math.min(e - i + 1, target - plainLen)
      plainLen, i = plainLen + take, i + take
    end
  end
  return ByteToChar(raw, i - 1)
end

local dedentLine
function LuaPad.AutoFormat(prev, plain, pos)
  if #plain ~= #prev + 1 or pos < 1 then return plain, pos end
  if sub(plain, 1, pos - 1) .. sub(plain, pos + 1) ~= prev then return plain, pos end
  if sub(plain, pos, pos) == "\n" then
    dedentLine = nil
    local line = sub(plain, 1, pos - 1):match("[^\n]*$")
    local indent = line:match("^ *")
    local code = line:gsub("%-%-.*$", "")
    if code:find("%f[%w_]then%s*$") or code:find("%f[%w_]do%s*$") or code:find("%f[%w_]else%s*$")
      or code:find("%f[%w_]repeat%s*$") or code:find("function[^\n]*%)%s*$") or code:find("{%s*$") then
      indent = indent .. "  "
    end
    if indent ~= "" then
      plain = sub(plain, 1, pos) .. indent .. sub(plain, pos + 1)
      pos = pos + #indent
    end
    return plain, pos
  end
  local lineText = sub(plain, 1, pos):match("[^\n]*$")
  local ls = pos - #lineText + 1
  if dedentLine ~= ls then dedentLine = nil end
  if sub(lineText, 1, 2) == "  " then
    local word = lineText:match("^%s+(%a+)$") or lineText:match("^%s+(})$")
    local hit = word == "end" or word == "until" or word == "}"
    if (word == "else" or word == "elseif") and dedentLine ~= ls then hit = true; dedentLine = ls end
    if hit then
      plain = sub(plain, 1, ls - 1) .. sub(lineText, 3) .. sub(plain, pos + 1)
      pos = pos - 2
    end
  end
  return plain, pos
end