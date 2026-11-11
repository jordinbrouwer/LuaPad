-- Only options that still work under Midnight's secret values are offered. Auras and cooldowns may
-- be hidden in combat; the generated code checks issecretvalue and then does nothing.
LuaPad = LuaPad or {}
local LP = LuaPad
local B = {}
LP.Builder = B

B.COLORS = {
  { value = "white", label = "White", rgb = { 1, 1, 1 } },
  { value = "red", label = "Red", rgb = { 1, 0.25, 0.25 } },
  { value = "orange", label = "Orange", rgb = { 1, 0.6, 0.15 } },
  { value = "yellow", label = "Yellow", rgb = { 1, 0.9, 0.2 } },
  { value = "green", label = "Green", rgb = { 0.35, 0.9, 0.4 } },
  { value = "cyan", label = "Cyan", rgb = { 0.3, 0.85, 1 } },
  { value = "blue", label = "Blue", rgb = { 0.35, 0.5, 1 } },
  { value = "purple", label = "Purple", rgb = { 0.7, 0.45, 1 } },
  { value = "pink", label = "Pink", rgb = { 1, 0.5, 0.8 } },
}
B.SIZES = {
  { value = 24, label = "Small" }, { value = 36, label = "Medium" },
  { value = 52, label = "Large" }, { value = 72, label = "Huge" },
}
B.POSITIONS = {
  { value = "top", label = "Top" }, { value = "center", label = "Center" }, { value = "bottom", label = "Lower" },
}
B.TEXT_Y = { top = 230, center = 90, bottom = -40 }
B.ICONOPTS = {
  { value = "icon", label = "Icon + text" }, { value = "text", label = "Text only" },
}
B.SOUNDS = {
  { value = 8959, label = "Raid warning" },
  { value = 8960, label = "Ready check" },
  { value = 12867, label = "Alarm clock" },
  { value = 3175, label = "Map ping" },
  { value = 888, label = "Level up" },
  { value = 878, label = "Quest complete" },
  { value = 5274, label = "Auction bell" },
  { value = 3081, label = "Whisper" },
  { value = "custom", label = "Custom sound ID..." },
}
B.MAX_CONDS = 4
B.CONDITIONS = {
  { value = "combat", label = "I am in combat" },
  { value = "nocombat", label = "I am not in combat" },
  { value = "group", label = "I am in a group" },
  { value = "solo", label = "I am solo" },
  { value = "instance", label = "I am in a dungeon or raid" },
  { value = "item_on", label = "I have an item equipped..." },
  { value = "item_off", label = "I don't have an item equipped..." },
  { value = "aura_on", label = "A buff or debuff is active..." },
  { value = "aura_off", label = "A buff or debuff is not active..." },
}
B.AURA_CONDS = { aura_on = true, aura_off = true }
B.ITEM_CONDS = { item_on = true, item_off = true }
B.ITEM_TRIGGERS = { equip = true, unequip = true, item_while = true }
B.STATE_TRIGGERS = { always = true, item_while = true, aura_while = true, cd_ready_while = true, cd_cooldown_while = true }
B.AURA_TRIGGERS = { aura_while = true, aura_gain = true, aura_lose = true }
B.CD_TRIGGERS = { cd_ready = true, cd_ready_while = true, cd_cooldown_while = true }
B.TIMER_TRIGGERS = { aura_while = true, cd_cooldown_while = true }
B.ICON_TRIGGERS = { item_while = true, aura_while = true, cd_ready_while = true, cd_cooldown_while = true }
B.SOURCES = {
  { value = "any", label = "From anyone" },
  { value = "mine", label = "Only mine" },
}
B.BAROPTS = {
  { value = "none", label = "No bar" },
  { value = "bar", label = "Countdown bar" },
}
B.AURATYPES = {
  { value = "HELPFUL", label = "Buff" },
  { value = "HARMFUL", label = "Debuff" },
}
B.UNITS = {
  { value = "player", label = "On me" },
  { value = "target", label = "On my target" },
  { value = "focus", label = "On my focus" },
  { value = "pet", label = "On my pet" },
}
B.RESOURCES = {
  { value = "COMBO_POINTS", label = "Combo Points", enum = "ComboPoints" },
  { value = "HOLY_POWER", label = "Holy Power", enum = "HolyPower" },
  { value = "SOUL_SHARDS", label = "Soul Shards", enum = "SoulShards" },
  { value = "CHI", label = "Chi", enum = "Chi" },
  { value = "ARCANE_CHARGES", label = "Arcane Charges", enum = "ArcaneCharges" },
  { value = "ESSENCE", label = "Essence", enum = "Essence" },
}
B.TRIGGERS = {
  { value = "always", label = "Always" },
  { value = "combat_start", label = "I enter combat", event = "PLAYER_REGEN_DISABLED" },
  { value = "combat_end", label = "I leave combat", event = "PLAYER_REGEN_ENABLED" },
  { value = "cast", label = "I cast a spell..." },
  { value = "resource_reach", label = "A class resource reaches a number..." },
  { value = "resource_gain", label = "I gain a class resource point..." },
  { value = "aura_while", label = "While a buff or debuff is active..." },
  { value = "aura_gain", label = "A buff or debuff appears..." },
  { value = "aura_lose", label = "A buff or debuff fades..." },
  { value = "cd_ready", label = "A spell comes off cooldown..." },
  { value = "cd_ready_while", label = "While a spell is ready..." },
  { value = "cd_cooldown_while", label = "While a spell is on cooldown..." },
  { value = "item_while", label = "While I have an item equipped..." },
  { value = "equip", label = "I equip an item..." },
  { value = "unequip", label = "I take off an item..." },
  { value = "timer", label = "Every few seconds..." },
  { value = "world", label = "A loading screen ends", event = "PLAYER_ENTERING_WORLD" },
  { value = "login", label = "I log in or reload", event = "PLAYER_LOGIN" },
  { value = "zone", label = "I change zone", event = "ZONE_CHANGED_NEW_AREA" },
  { value = "target", label = "I change target", event = "PLAYER_TARGET_CHANGED" },
  { value = "mount", label = "I mount or dismount", event = "PLAYER_MOUNT_DISPLAY_CHANGED" },
  { value = "group", label = "My group changes", event = "GROUP_ROSTER_UPDATE" },
  { value = "readycheck", label = "A ready check starts", event = "READY_CHECK" },
  { value = "quest_accept", label = "I accept a quest", event = "QUEST_ACCEPTED" },
  { value = "quest_done", label = "I turn in a quest", event = "QUEST_TURNED_IN" },
  { value = "levelup", label = "I level up", event = "PLAYER_LEVEL_UP" },
  { value = "dead", label = "I die", event = "PLAYER_DEAD" },
}
B.ACTIONS = {
  { value = "sound", label = "Play a sound" },
  { value = "text", label = "Show text on screen" },
  { value = "flash", label = "Flash the screen" },
  { value = "chat", label = "Print a chat message" },
}

function B.Find(list, value)
  for _, item in ipairs(list) do
    if item.value == value then return item end
  end
end
local Find = B.Find

function B.AuraDefaults(kind)
  return { type = kind, aura = "", auraType = "HELPFUL", unit = "player", stacks = 1, source = "any" }
end

function B.TriggerDefaults(kind)
  if kind == "cast" then return { type = kind } end
  if kind == "resource_reach" then return { type = kind, resource = "COMBO_POINTS", value = 5 } end
  if kind == "resource_gain" then return { type = kind, resource = "COMBO_POINTS" } end
  if kind == "timer" then return { type = kind, seconds = 10 } end
  if B.AURA_TRIGGERS[kind] then return B.AuraDefaults(kind) end
  return { type = kind }
end

function B.ActionDefaults(kind)
  if kind == "sound" then return { type = kind } end
  if kind == "text" then return { type = kind, text = "", color = "yellow", size = 36, duration = 3, pos = "top", icon = "icon", bar = "none" } end
  if kind == "flash" then return { type = kind, color = "red", duration = 1 } end
  return { type = "chat", text = "" }
end

function B.CondDefaults(kind)
  if B.AURA_CONDS[kind] then return B.AuraDefaults(kind) end
  return { type = kind }
end

function B.CondLabel(c)
  local def = c and c.type and Find(B.CONDITIONS, c.type)
  return def and (def.label:gsub("%.%.%.$", "")) or "Pick a condition"
end

function B.DefaultCfg()
  return { trigger = {}, conds = {}, condOp = "and", actions = {} }
end

function B.ExampleCfg()
  return {
    trigger = { type = "combat_start" },
    conds = {},
    condOp = "and",
    actions = { { type = "sound", sound = 8959 }, { type = "text", text = "In combat!", color = "red", size = 36, duration = 3, pos = "top" } },
  }
end

function B.EnsureCfg(snippet)
  local cfg = snippet.cfg
  if type(cfg) ~= "table" then cfg = B.DefaultCfg() snippet.cfg = cfg end
  if type(cfg.trigger) ~= "table" or (cfg.trigger.type and not Find(B.TRIGGERS, cfg.trigger.type)) then cfg.trigger = {} end
  -- Older saved rules had a single condition in cfg.cond / condItem / condAura.
  if type(cfg.conds) ~= "table" then
    cfg.conds = {}
    if cfg.cond and Find(B.CONDITIONS, cfg.cond) then
      local c = B.CondDefaults(cfg.cond)
      if B.ITEM_CONDS[cfg.cond] then c.item = cfg.condItem end
      if B.AURA_CONDS[cfg.cond] and type(cfg.condAura) == "table" then
        for _, key in ipairs({ "aura", "auraType", "unit", "stacks", "source" }) do c[key] = cfg.condAura[key] end
      end
      cfg.conds[1] = c
    end
  end
  cfg.cond, cfg.condItem, cfg.condAura = nil, nil, nil
  for i = #cfg.conds, 1, -1 do
    local c = cfg.conds[i]
    if type(c) ~= "table" or (c.type and not Find(B.CONDITIONS, c.type)) then table.remove(cfg.conds, i) end
  end
  while #cfg.conds > B.MAX_CONDS do table.remove(cfg.conds) end
  if cfg.condOp ~= "or" then cfg.condOp = "and" end
  if type(cfg.actions) ~= "table" then cfg.actions = {} end
  if not snippet.code or snippet.code == "" then snippet.code = B.Generate(cfg) end
  return cfg
end

function B.Validate(cfg)
  local t = cfg.trigger
  if not t.type then return "Pick when this should happen." end
  if (t.type == "cast" or B.CD_TRIGGERS[t.type]) and not (tonumber(t.spell) and tonumber(t.spell) > 0) then return "Fill in a spell ID." end
  if t.type == "resource_reach" and not tonumber(t.value) then return "Fill in the number to reach." end
  if t.type == "timer" and not (tonumber(t.seconds) and tonumber(t.seconds) >= 1) then return "Fill in the seconds (1 or more)." end
  if B.AURA_TRIGGERS[t.type] and (t.aura or ""):gsub("%s", "") == "" then return "Fill in the buff or debuff name (or spell ID)." end
  if B.ITEM_TRIGGERS[t.type] and not (tonumber(t.item) and tonumber(t.item) > 0) then return "Pick the item (ID, shift-click or drag)." end
  for i, c in ipairs(cfg.conds or {}) do
    if not c.type then return "Only if " .. i .. ": pick a condition (or remove it)." end
    if B.AURA_CONDS[c.type] and (c.aura or ""):gsub("%s", "") == "" then return "Only if " .. i .. ": fill in the buff or debuff name (or spell ID)." end
    if B.ITEM_CONDS[c.type] and not (tonumber(c.item) and tonumber(c.item) > 0) then return "Only if " .. i .. ": pick the item (ID, shift-click or drag)." end
  end
  if #cfg.actions == 0 then return "Add at least one action." end
  for i, a in ipairs(cfg.actions) do
    if not a.type then return "Action " .. i .. ": pick what should happen." end
    if a.type == "sound" and not a.sound then return "Action " .. i .. ": pick a sound." end
    if a.type == "sound" and a.sound == "custom" and not tonumber(a.custom) then return "Action " .. i .. ": fill in the sound ID." end
    if (a.type == "text" or a.type == "chat") and (a.text or "") == "" then return "Action " .. i .. ": type a message." end
  end
end
