local addonName = ...
LuaPad = LuaPad or {}
local LP = LuaPad

local WELCOME = [==[
-- Welcome to LuaPad!
-- Paste or write Lua here. Errors show up under the editor
-- with the exact line they happened on.
--
-- Helpers available in every snippet:
--   On("EVENT", function(event, ...) end)   listen to an event
--   Every(seconds, function() end)          repeating timer
--   After(seconds, function() end)          one-shot timer
--   Print(...)                              chat message
--
-- Ctrl+S saves the snippet. Switch it on with "Enabled" to run it.

On("PLAYER_ENTERING_WORLD", function()
  Print("Hello from LuaPad!")
end)
]==]

local TEMPLATE = [==[
-- On("EVENT", function(event, ...) end)
-- Every(seconds, function() end)
-- After(seconds, function() end)
-- Print(...)

]==]

function LP.Get(id)
  if not id or not LuaPadDB then return nil end
  for _, snippet in ipairs(LuaPadDB.snippets) do
    if snippet.id == id then return snippet end
  end
end

function LP.Current()
  return LuaPadDB and LP.Get(LuaPadDB.selected)
end

-- Code snippets keep unsaved edits in .draft; Simple rules differ from .savedCode instead.
function LP.IsDirty(snippet)
  if not snippet then return false end
  if snippet.mode == "simple" then return snippet.savedCode ~= nil and snippet.code ~= snippet.savedCode end
  return snippet.draft ~= nil
end

function LP.Incomplete(snippet)
  if snippet and snippet.mode == "simple" then
    return LP.Builder.Validate(LP.Builder.EnsureCfg(snippet))
  end
end

function LP.DeepCopy(v)
  if type(v) ~= "table" then return v end
  local copy = {}
  for k, val in pairs(v) do copy[k] = LP.DeepCopy(val) end
  return copy
end

function LP.New(mode)
  local db = LuaPadDB
  db.nextId = db.nextId + 1
  local snippet = { id = db.nextId, name = "Snippet " .. db.nextId, code = TEMPLATE, enabled = false }
  if mode == "simple" then
    snippet.mode = "simple"
    snippet.cfg = LP.Builder.DefaultCfg()
    snippet.code = LP.Builder.Generate(snippet.cfg)
  end
  db.snippets[#db.snippets + 1] = snippet
  return snippet
end

function LP.Delete(id)
  LP.Stop(id)
  LP.State[id] = nil
  for i, snippet in ipairs(LuaPadDB.snippets) do
    if snippet.id == id then table.remove(LuaPadDB.snippets, i) break end
  end
end

local function InitDB()
  LuaPadDB = LuaPadDB or {}
  local db = LuaPadDB
  if type(db.snippets) ~= "table" then
    db.snippets = { { id = 1, name = "Welcome", code = WELCOME, enabled = false } }
    local example = { id = 2, name = "Example: combat alert", mode = "simple", enabled = false, cfg = LP.Builder.ExampleCfg() }
    example.code = LP.Builder.Generate(example.cfg)
    db.snippets[2] = example
    db.nextId = 2
    db.selected = 1
  end
  db.nextId = db.nextId or #db.snippets
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" then
    if arg1 ~= addonName then return end
    InitDB()
    boot:UnregisterEvent("ADDON_LOADED")
  else
    LP.loginPhase = true
    for _, snippet in ipairs(LuaPadDB.snippets) do
      if snippet.enabled then LP.Run(snippet.id) end
    end
    LP.loginPhase = false
    boot:UnregisterEvent("PLAYER_LOGIN")
  end
end)
