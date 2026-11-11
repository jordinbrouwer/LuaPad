LuaPad = LuaPad or {}
local LP = LuaPad

LP.State = {}
local State = LP.State
local events = {}
local dispatcher = CreateFrame("Frame")

local function Changed()
  if LP.OnStateChanged then LP.OnStateChanged() end
end

local function GetState(id)
  local st = State[id]
  if not st then
    st = { tickers = {}, frames = {}, gen = 0 }
    State[id] = st
  end
  return st
end

local function Clean(msg)
  msg = tostring(msg == nil and "unknown error" or msg)
  local line = tonumber(msg:match("LuaPad#%d+:(%d+):"))
  local text = msg:gsub("^LuaPad#%d+:%d+:%s*", "")
  return text, line
end

local function CleanTrace(trace)
  if not trace then return nil end
  local out = {}
  for l in trace:gmatch("[^\n]+") do
    if not l:find("LuaPad[/\\]Core[/\\]Runtime%.lua") and not l:find("[C]", 1, true) then
      l = l:gsub("LuaPad#%d+:(%d+)", "line %1")
      l = l:gsub("Interface\\AddOns\\", "")
      out[#out + 1] = l
      if #out >= 4 then break end
    end
  end
  return #out > 0 and table.concat(out, "\n") or nil
end

local function Fail(snippet, err, trace, kind)
  local st = GetState(snippet.id)
  local text, line = Clean(err)
  if not line and trace then line = tonumber(trace:match("LuaPad#%d+:(%d+)")) end
  local isNew = st.err ~= text
  st.count = (isNew and 0 or (st.count or 0)) + 1
  st.err, st.kind, st.line, st.trace = text, kind, line, CleanTrace(trace)
  st.time = date("%H:%M:%S")
  if isNew then
    if LP.ShowErrorToast then
      LP.ShowErrorToast(snippet, line, text)
    else
      print(("|cffe6333fLuaPad|r |cffffffff%s|r  %s%s"):format(snippet.name or "?", line and ("line " .. line .. ": ") or "", text))
    end
  end
  Changed()
end

local function Handler(err)
  return { err = err, trace = debugstack and debugstack(2, 12, 0) or nil }
end

local current

local function Call(snippet, fn, ...)
  local n, args = select("#", ...), { ... }
  local prev = current
  current = snippet
  local ok, res = xpcall(function() return fn(unpack(args, 1, n)) end, Handler)
  current = prev
  if not ok then
    if type(res) ~= "table" then res = { err = res } end
    Fail(snippet, res.err, res.trace, "runtime")
  end
  return ok
end

function LP.CheckSyntax(code)
  local fn, err = loadstring(code or "", "=LuaPad#0")
  if fn then return nil end
  return Clean(err)
end

-- Blocked protected calls arrive as events while the offending call is still running.
local guard = CreateFrame("Frame")
guard:RegisterEvent("ADDON_ACTION_FORBIDDEN")
guard:RegisterEvent("ADDON_ACTION_BLOCKED")
guard:SetScript("OnEvent", function(_, event, _, func)
  if not current then return end
  local what = event == "ADDON_ACTION_FORBIDDEN" and "is not allowed for addons" or "is blocked (in combat?)"
  Fail(current, ("'%s' %s"):format(tostring(func or "?"), what), debugstack and debugstack(2, 12, 0) or nil, "runtime")
end)

dispatcher:SetScript("OnEvent", function(_, event, ...)
  local list = events[event]
  if not list then return end
  local first = ...
  for i = 1, #list do
    local entry = list[i]
    if entry and not entry.dead and (not entry.unit or entry.unit == first) then
      local snippet = LP.Get(entry.id)
      if snippet then Call(snippet, entry.fn, event, ...) end
    end
  end
end)

local function Register(snippet, event, fn, unit)
  if type(event) ~= "string" then error("On(event, fn): event must be a string", 3) end
  if type(fn) ~= "function" then error("On(event, fn): fn must be a function", 3) end
  local list = events[event]
  if not list then
    if not pcall(dispatcher.RegisterEvent, dispatcher, event) then
      error("On(): unknown event '" .. event .. "'", 3)
    end
    list = {}
    events[event] = list
  end
  list[#list + 1] = { id = snippet.id, fn = fn, unit = unit }
end

local FRAME_SCRIPTS = {
  "OnEvent", "OnUpdate", "OnShow", "OnHide", "OnClick", "OnEnter", "OnLeave",
  "OnMouseDown", "OnMouseUp", "OnMouseWheel", "OnValueChanged", "OnTextChanged",
}

function LP.Stop(id)
  local st = GetState(id)
  for event, list in pairs(events) do
    local keep = {}
    for _, entry in ipairs(list) do
      if entry.id == id then entry.dead = true else keep[#keep + 1] = entry end
    end
    if #keep == 0 then
      events[event] = nil
      dispatcher:UnregisterEvent(event)
    else
      events[event] = keep
    end
  end
  for _, ticker in ipairs(st.tickers) do ticker:Cancel() end
  st.tickers = {}
  -- Frames can't be destroyed, only silenced and hidden.
  for _, f in ipairs(st.frames) do
    pcall(f.UnregisterAllEvents, f)
    for _, script in ipairs(FRAME_SCRIPTS) do
      if f.HasScript and f:HasScript(script) then pcall(f.SetScript, f, script, nil) end
    end
    pcall(f.Hide, f)
  end
  st.frames = {}
  if LP.Fx and LP.Fx.HideOwner then LP.Fx.HideOwner(id) end
  st.gen = st.gen + 1
  st.running = false
end

local function MakeEnv(snippet, st)
  local env = setmetatable({}, { __index = _G })
  local function Wrap(fn)
    if type(fn) ~= "function" then return fn end
    local gen = st.gen
    return function(...)
      if st.gen == gen then Call(snippet, fn, ...) end
    end
  end
  env.On = function(event, fn, unit) Register(snippet, event, fn, unit) end
  env.Print = function(...)
    print("|cffe6333f" .. (snippet.name or "LuaPad") .. "|r", ...)
  end
  env.After = function(seconds, fn)
    if type(seconds) ~= "number" or type(fn) ~= "function" then error("After(seconds, fn): bad arguments", 2) end
    local gen = st.gen
    C_Timer.After(seconds, function()
      if st.gen == gen then Call(snippet, fn) end
    end)
  end
  env.Every = function(seconds, fn)
    if type(seconds) ~= "number" or type(fn) ~= "function" then error("Every(seconds, fn): bad arguments", 2) end
    local ticker = C_Timer.NewTicker(seconds, function() Call(snippet, fn) end)
    st.tickers[#st.tickers + 1] = ticker
    return ticker
  end
  env.Sound = function(...) LP.Fx.Sound(...) end
  env.Text = function(...) LP.Fx.Text(...) end
  env.Flash = function(...) LP.Fx.Flash(...) end
  env.Status = function(...) LP.Fx.Status(snippet.id, ...) end
  env.CreateFrame = function(...)
    local f = CreateFrame(...)
    st.frames[#st.frames + 1] = f
    local set, hook = f.SetScript, f.HookScript
    f.SetScript = function(self, script, fn) return set(self, script, Wrap(fn)) end
    f.HookScript = function(self, script, fn, ...) return hook(self, script, Wrap(fn), ...) end
    return f
  end
  env.C_Timer = setmetatable({
    After = function(seconds, fn) return C_Timer.After(seconds, Wrap(fn)) end,
    NewTimer = function(seconds, fn, ...)
      local t = C_Timer.NewTimer(seconds, Wrap(fn), ...)
      st.tickers[#st.tickers + 1] = t
      return t
    end,
    NewTicker = function(seconds, fn, ...)
      local t = C_Timer.NewTicker(seconds, Wrap(fn), ...)
      st.tickers[#st.tickers + 1] = t
      return t
    end,
  }, { __index = C_Timer })
  -- Hooks can't be removed, so they go dead once the snippet restarts.
  env.hooksecurefunc = function(a, b, c)
    if type(a) == "table" then hooksecurefunc(a, b, Wrap(c)) else hooksecurefunc(a, Wrap(b)) end
  end
  return env
end

-- Simple rules regenerate .code on every click; only .savedCode may run.
function LP.RunnableCode(snippet)
  if snippet.mode == "simple" and snippet.savedCode then return snippet.savedCode end
  return snippet.code or ""
end

function LP.ClearError(id)
  local st = State[id]
  if st then st.err, st.line, st.trace, st.kind, st.count = nil, nil, nil, nil, nil end
end

function LP.Run(id)
  local snippet = LP.Get(id)
  if not snippet then return false end
  LP.Stop(id)
  local st = GetState(id)
  LP.ClearError(id)
  local fn, cerr = loadstring(LP.RunnableCode(snippet), "=LuaPad#" .. id)
  if not fn then
    Fail(snippet, cerr, nil, "syntax")
    return false
  end
  setfenv(fn, MakeEnv(snippet, st))
  st.running = true
  -- Hooked versions keep running until a reload, so "running since" keeps the first time.
  if not (st.ran and LP.NeedsReload and LP.NeedsReload(snippet.code)) then
    st.ran = date("%H:%M:%S")
  end
  local ok = Call(snippet, fn)
  -- Snippets start after PLAYER_LOGIN has fired, so replay it for those that listen.
  if ok and LP.loginPhase and events.PLAYER_LOGIN then
    for _, entry in ipairs(events.PLAYER_LOGIN) do
      if entry.id == id and not entry.dead then Call(snippet, entry.fn, "PLAYER_LOGIN") end
    end
  end
  Changed()
  return ok
end

function LP.SetEnabled(id, enabled)
  local snippet = LP.Get(id)
  if not snippet then return end
  snippet.enabled = enabled and true or false
  if snippet.enabled then
    LP.Run(id)
  else
    LP.Stop(id)
    local st = State[id]
    if st then st.ran = nil end
    Changed()
  end
end

function LP.Status(snippet)
  local st = State[snippet.id]
  if st and st.err then
    local label = st.kind == "syntax" and "Syntax error" or "Error"
    return "error", st.line and (label .. " · line " .. st.line) or label
  end
  if not snippet.enabled then return "off", "Disabled" end
  return "ok", "Active"
end
