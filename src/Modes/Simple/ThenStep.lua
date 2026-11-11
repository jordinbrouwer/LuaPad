LuaPad = LuaPad or {}
local LP = LuaPad
local UI = LP.UI
local B = LP.Builder
local S = LP.SimpleMode
local At = S.At

local MAX_ACTIONS = 3
local ACTION_NAMES = { sound = "Sound", text = "Text", flash = "Flash", chat = "Chat message" }
local PARAMS = { "soundDD", "custom", "msg", "color", "size", "dur", "durUnit", "pos", "iconDD", "barDD", "move" }

local rows = {}
local addButton, tokenHint
local moving

function S.ShowPreview()
  if not moving then return end
  LP.Fx.Preview(moving, moving.icon ~= "text" and S.TriggerIcon() or nil, S.Commit)
end

function S.StopMoving()
  if not moving then return end
  moving = nil
  LP.Fx.Preview(nil)
end

local function TwoLines(a)
  return a ~= nil and a.type == "text" and S.Persistent() and B.ICON_TRIGGERS[S.cfg.trigger.type] or false
end

local function RowHeight(a)
  return TwoLines(a) and 92 or 60
end

local function ShowParams(row, keys)
  for _, key in ipairs(keys) do row[key]:Show() end
end

local function PlaceParams(row, a)
  for _, key in ipairs(PARAMS) do row[key]:Hide() end
  local y = -30
  if not a.type then return end
  if a.type == "sound" then
    At(row.soundDD, "TOPLEFT", row, "TOPLEFT", 0, y)
    row.soundDD:Show()
    if a.sound == "custom" then
      At(row.custom, "LEFT", row.soundDD, "RIGHT", 8, 0)
      row.custom:Show()
    end
  elseif a.type == "text" and S.Persistent() then
    if TwoLines(a) then
      row.msg:SetWidth(330)
      At(row.msg, "TOPLEFT", row, "TOPLEFT", 0, y)
      At(row.move, "LEFT", row.msg, "RIGHT", 8, 0)
      At(row.color, "TOPLEFT", row, "TOPLEFT", 0, y - 32)
      At(row.size, "LEFT", row.color, "RIGHT", 8, 0)
      At(row.iconDD, "LEFT", row.size, "RIGHT", 8, 0)
      ShowParams(row, { "msg", "move", "color", "size", "iconDD" })
      if B.TIMER_TRIGGERS[S.cfg.trigger.type] then
        At(row.barDD, "LEFT", row.iconDD, "RIGHT", 8, 0)
        row.barDD:Show()
      end
    else
      row.msg:SetWidth(150)
      At(row.msg, "TOPLEFT", row, "TOPLEFT", 0, y)
      At(row.color, "LEFT", row.msg, "RIGHT", 8, 0)
      At(row.size, "LEFT", row.color, "RIGHT", 8, 0)
      At(row.move, "LEFT", row.size, "RIGHT", 8, 0)
      ShowParams(row, { "msg", "color", "size", "move" })
    end
  elseif a.type == "text" then
    row.msg:SetWidth(150)
    At(row.msg, "TOPLEFT", row, "TOPLEFT", 0, y)
    At(row.color, "LEFT", row.msg, "RIGHT", 8, 0)
    At(row.size, "LEFT", row.color, "RIGHT", 8, 0)
    At(row.dur, "LEFT", row.size, "RIGHT", 8, 0)
    At(row.durUnit, "LEFT", row.dur, "RIGHT", 6, 0)
    At(row.pos, "LEFT", row.durUnit, "RIGHT", 10, 0)
    ShowParams(row, { "msg", "color", "size", "dur", "durUnit", "pos" })
  elseif a.type == "flash" then
    At(row.color, "TOPLEFT", row, "TOPLEFT", 0, y)
    At(row.dur, "LEFT", row.color, "RIGHT", 8, 0)
    At(row.durUnit, "LEFT", row.dur, "RIGHT", 6, 0)
    ShowParams(row, { "color", "dur", "durUnit" })
  else
    row.msg:SetWidth(360)
    At(row.msg, "TOPLEFT", row, "TOPLEFT", 0, y)
    row.msg:Show()
  end
end

local function UpdateTest(row, a)
  local ok = a and a.type ~= nil
  if ok and a.type == "sound" then
    ok = a.sound ~= nil and (a.sound ~= "custom" or tonumber(a.custom) ~= nil)
  end
  row.test:SetShown(ok and true or false)
end

function S.RefreshActions()
  local cfg = S.cfg
  if moving then
    local keep = false
    for _, a in ipairs(cfg.actions) do
      if a == moving and a.type == "text" and S.Persistent() then keep = true end
    end
    if not keep then S.StopMoving() end
  end
  S.loading = true
  for i = 1, MAX_ACTIONS do
    local a, row = cfg.actions[i], rows[i]
    if a then
      row:Show()
      row.iconDD:SetValue(a.icon or "icon")
      row.barDD:SetValue(a.bar or "none")
      row.move.Label:SetText(moving == a and "Done" or "Move")
      row.typeDD:SetValue(a.type)
      row.soundDD:SetValue(a.sound)
      row.custom:SetText(a.custom and tostring(a.custom) or "")
      row.msg:SetText(a.text or "")
      row.color:SetValue(a.color)
      row.size:SetValue(a.size)
      row.dur:SetText(a.duration and tostring(a.duration) or "")
      row.pos:SetValue(a.pos)
      PlaceParams(row, a)
      UpdateTest(row, a)
    else
      row:Hide()
    end
  end
  S.loading = false
  addButton:SetShown(#cfg.actions < MAX_ACTIONS)
  tokenHint:SetShown(B.TIMER_TRIGGERS[cfg.trigger.type] or false)
  S.Layout()
end

function S.ActionText()
  local actions = S.cfg.actions
  if #actions == 0 then return "|cffff6b6bNo actions yet|r" end
  local parts = {}
  for _, a in ipairs(actions) do parts[#parts + 1] = ACTION_NAMES[a.type] or "?" end
  return table.concat(parts, ", ")
end

function S.LayoutActions(card)
  local actions = S.cfg.actions
  local y = 32
  for i = 1, MAX_ACTIONS do
    local row = rows[i]
    local h = RowHeight(actions[i])
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -y)
    row:SetPoint("TOPRIGHT", card, "TOPRIGHT", -14, -y)
    row:SetHeight(h - 4)
    if i <= #actions then y = y + h end
  end
  At(addButton, "TOPLEFT", card, "TOPLEFT", 14, -y)
  return y + 6 + (#actions < MAX_ACTIONS and 34 or 8)
end

local function BuildRow(card, i)
  local row = CreateFrame("Frame", nil, card)
  row:SetHeight(56)
  local function Action() return S.cfg and S.cfg.actions[i] end
  local function Set(key, value)
    local a = Action()
    if a then a[key] = value S.Commit() end
  end

  row.typeDD = UI.CreateDropdown(row, 200, B.ACTIONS, function(value)
    S.cfg.actions[i] = B.ActionDefaults(value)
    S.RefreshActions()
    S.Commit()
  end)
  row.typeDD:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
  row.test = UI.CreateButton(row, "Test", 54, false, function()
    if Action() then B.RunAction(Action(), S.TriggerIcon(), S.Persistent()) end
  end, "Try this action right now.")
  row.test:SetPoint("LEFT", row.typeDD, "RIGHT", 8, 0)
  row.remove = UI.CreateButton(row, "X", 24, false, function()
    table.remove(S.cfg.actions, i)
    S.RefreshActions()
    S.Commit()
  end, "Remove this action")
  row.remove:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)

  row.soundDD = UI.CreateDropdown(row, 200, B.SOUNDS, function(value)
    local a = Action()
    if not a then return end
    a.sound = value
    S.RefreshActions()
    S.Commit()
  end)
  row.custom = S.NumEdit(row, 100)
  row.custom:SetScript("OnTextChanged", function(self, user)
    if user and Action() then Action().custom = tonumber(self:GetText()) UpdateTest(row, Action()) S.Commit() end
  end)
  row.msg = UI.CreateEdit(row, 150, 24)
  row.msg:SetMaxLetters(120)
  row.msg:SetScript("OnTextChanged", function(self, user)
    if user then Set("text", self:GetText()) end
  end)
  row.color = UI.CreateDropdown(row, 90, B.COLORS, function(value) Set("color", value) end)
  row.size = UI.CreateDropdown(row, 80, B.SIZES, function(value) Set("size", value) end)
  row.dur = S.NumEdit(row, 44)
  row.dur:SetMaxLetters(2)
  row.dur:SetScript("OnTextChanged", function(self, user)
    if user then Set("duration", tonumber(self:GetText())) end
  end)
  row.durUnit = S.Small(row, "sec")
  row.pos = UI.CreateDropdown(row, 90, B.POSITIONS, function(value) Set("pos", value) end)
  row.iconDD = UI.CreateDropdown(row, 104, B.ICONOPTS, function(value) Set("icon", value) end)
  row.barDD = UI.CreateDropdown(row, 120, B.BAROPTS, function(value) Set("bar", value) end)
  row.move = UI.CreateButton(row, "Move", 60, false, function()
    local a = Action()
    if not a then return end
    if moving == a then
      S.StopMoving()
    else
      moving = a
      S.ShowPreview()
    end
    S.RefreshActions()
  end, "Shows the text on screen so you can drag it where you want. Click Done when finished.")
  rows[i] = row
end

function S.BuildThen(card)
  tokenHint = S.Small(card, "Tip: %time, %stacks and %name work in the text.")
  tokenHint:SetPoint("TOPLEFT", card, "TOPLEFT", 110, -6)
  for i = 1, MAX_ACTIONS do BuildRow(card, i) end
  addButton = UI.CreateButton(card, "+ Add action", 110, false, function()
    if #S.cfg.actions >= MAX_ACTIONS then return end
    S.cfg.actions[#S.cfg.actions + 1] = {}
    S.RefreshActions()
    S.Commit()
  end)
end
