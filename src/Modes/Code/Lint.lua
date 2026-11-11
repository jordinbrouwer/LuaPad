LuaPad = LuaPad or {}
local LP = LuaPad

local KEYWORDS = {}
for w in ([[and break do else elseif end false for function goto if in local nil not or
  repeat return then true until while]]):gmatch("%a+") do KEYWORDS[w] = true end

local HELPERS = {
  On = true, Every = true, After = true, Print = true, Sound = true, Text = true,
  Flash = true, Status = true, self = true, _G = true,
}

local BLOCKED_EVENTS = {
  COMBAT_LOG_EVENT_UNFILTERED = "Blizzard blocks the combat log for addons in this version.",
  COMBAT_LOG_EVENT = "Blizzard blocks the combat log for addons in this version.",
}

-- Replaces comments and string contents with spaces, keeping every newline and position.
local function Blank(s)
  return (s:gsub("[^\n]", " "))
end

local function StripCode(code)
  local out, i, n = {}, 1, #code
  while i <= n do
    local c = code:sub(i, i)
    if c == "-" and code:sub(i + 1, i + 1) == "-" then
      local eq = code:match("^%[(=*)%[", i + 2)
      local stop
      if eq then
        local _, e = code:find("]" .. eq .. "]", i + 4 + #eq, true)
        stop = e or n
      else
        stop = (code:find("\n", i, true) or (n + 1)) - 1
      end
      out[#out + 1] = Blank(code:sub(i, stop))
      i = stop + 1
    elseif c == '"' or c == "'" then
      local j = i + 1
      while j <= n do
        local d = code:sub(j, j)
        if d == "\\" then j = j + 2
        elseif d == c or d == "\n" then break
        else j = j + 1 end
      end
      out[#out + 1] = c .. Blank(code:sub(i + 1, j - 1)) .. (j <= n and code:sub(j, j) or "")
      i = j + 1
    elseif c == "[" and code:match("^%[=*%[", i) then
      local eq = code:match("^%[(=*)%[", i)
      local _, e = code:find("]" .. eq .. "]", i + 2 + #eq, true)
      e = e or n
      out[#out + 1] = Blank(code:sub(i, e))
      i = e + 1
    else
      local j = code:find("[%-\"'%[]", i) or (n + 1)
      if j == i then j = i + 1 end
      out[#out + 1] = code:sub(i, j - 1)
      i = j
    end
  end
  return table.concat(out)
end

local function LineAt(text, pos)
  local _, count = text:sub(1, pos):gsub("\n", "")
  return count + 1
end

local function Lookup(tbl, key)
  local ok, value = pcall(function() return tbl[key] end)
  if ok then return value end
end

local function EventProblem(event)
  if BLOCKED_EVENTS[event] then return BLOCKED_EVENTS[event] end
  if C_EventUtils and C_EventUtils.IsEventValid then
    local ok, valid = pcall(C_EventUtils.IsEventValid, event)
    if ok and valid == false then return ("'%s' is not an event in this version of the game."):format(event) end
  end
end

function LP.Lint(code, max)
  code = code or ""
  max = max or 6
  local found, seen = {}, {}
  local function Warn(pos, key, msg)
    if seen[key] then return end
    seen[key] = true
    found[#found + 1] = { line = LineAt(code, pos), msg = msg }
  end

  for _, pattern in ipairs({
    "()%f[%w_]On%s*%(%s*[\"']([%w_]+)[\"']",
    "()RegisterEvent%s*%(%s*[\"']([%w_]+)[\"']",
    "()RegisterUnitEvent%s*%(%s*[\"']([%w_]+)[\"']",
  }) do
    for pos, event in code:gmatch(pattern) do
      local problem = EventProblem(event)
      if problem then Warn(pos, "event:" .. event, problem) end
    end
  end

  local clean = StripCode(code)

  local known = {}
  local function Names(list)
    for name in list:gmatch("[%a_][%w_]*") do known[name] = true end
  end
  for list in clean:gmatch("local%s+([^=\n;]+)") do Names(list) end
  for name in clean:gmatch("function%s+([%a_][%w_]*)") do known[name] = true end
  for list in clean:gmatch("function[^%(\n]*%(([^%)]*)%)") do Names(list) end
  for list in clean:gmatch("for%s+([^\n=]-)%s+in[%s%(]") do Names(list) end
  for name in clean:gmatch("for%s+([%a_][%w_]*)%s*=") do known[name] = true end
  local fieldSet = {}
  for pos, name in clean:gmatch("()([%a_][%w_]*)%s*=[^=]") do
    local prev = clean:sub(pos - 1, pos - 1)
    if prev == "." or prev == ":" then
      local owner = clean:sub(1, pos - 2):match("([%a_][%w_]*)%s*$")
      if owner then fieldSet[owner .. "." .. name] = true end
    else
      known[name] = true
    end
  end

  -- Names checked before use ("if X then", "X and X()") may be missing on purpose.
  local guarded = {}
  for _, pattern in ipairs({
    "%f[%w_]if%s+([%a_][%w_%.]*)%s+then", "%f[%w_]if%s+not%s+([%a_][%w_%.]*)",
    "%f[%w_]not%s+([%a_][%w_%.]*)", "([%a_][%w_%.]*)%s+and%f[^%w_]", "([%a_][%w_%.]*)%s+or%f[^%w_]",
  }) do
    for chain in clean:gmatch(pattern) do guarded[chain] = true end
  end

  for pos, name in clean:gmatch("()([%a_][%w_]*)") do
    local prev, prev2 = clean:sub(pos - 1, pos - 1), clean:sub(pos - 2, pos - 2)
    local isField = (prev == "." and prev2 ~= ".") or prev == ":"
    local partOfNumber = prev:match("[%w_]") ~= nil
    if not isField and not partOfNumber and not KEYWORDS[name] and not HELPERS[name] and not known[name]
      and not guarded[name] then
      local value = Lookup(_G, name)
      local after = clean:sub(pos + #name)
      if value == nil then
        if after:match("^%s*[%(\"'{]") then
          Warn(pos, "name:" .. name, ("'%s' doesn't exist. Calling it will fail (typo?)."):format(name))
        else
          Warn(pos, "name:" .. name, ("'%s' doesn't exist, so it is nil here (typo?)."):format(name))
        end
      elseif type(value) == "table" then
        local sep, field = after:match("^%s*([%.:])%s*([%a_][%w_]*)%s*[%(\"'{]")
        if field and not fieldSet[name .. "." .. field] and not guarded[name .. "." .. field]
          and Lookup(value, field) == nil then
          Warn(pos, "field:" .. name .. sep .. field,
            ("'%s%s%s' doesn't exist in this version. Calling it will fail."):format(name, sep, field))
        end
      end
    end
  end

  table.sort(found, function(a, b) return a.line < b.line end)
  while #found > max do table.remove(found) end
  return found
end