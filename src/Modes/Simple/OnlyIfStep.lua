LuaPad = LuaPad or {}
local LP = LuaPad
local UI = LP.UI
local B = LP.Builder
local S = LP.SimpleMode
local MAX_CONDS = B.MAX_CONDS

local rows = {}
local emptyText, addButton

local function RowHeight(c)
  if not c then return 0 end
  if B.AURA_CONDS[c.type] then return 100 end
  if B.ITEM_CONDS[c.type] then return 68 end
  return 32
end

function S.RefreshConds()
  local cfg = S.cfg
  S.loading = true
  for i = 1, MAX_CONDS do
    local c, row = cfg.conds[i], rows[i]
    if c then
      row:Show()
      row.typeDD:SetValue(c.type)
      row.op:SetShown(i > 1)
      row.opText:SetShown(i == 1)
      if i > 1 then row.op.Label:SetText(cfg.condOp == "or" and "OR" or "AND") end
      local isItem, isAura = B.ITEM_CONDS[c.type] or false, B.AURA_CONDS[c.type] or false
      row.item:SetShown(isItem)
      if isItem then row.item:Set(c.item) end
      row.aura:SetShown(isAura)
      if isAura then row.aura:Load(c) end
    else
      row:Hide()
    end
  end
  S.loading = false
  emptyText:SetShown(#cfg.conds == 0)
  addButton:SetShown(#cfg.conds < MAX_CONDS)
end

function S.CondText()
  local cfg = S.cfg
  if #cfg.conds == 0 then return "Always" end
  local parts = {}
  for _, c in ipairs(cfg.conds) do
    local text = B.CondLabel(c)
    if B.AURA_CONDS[c.type] and strtrim(c.aura or "") ~= "" then text = text .. " (" .. strtrim(c.aura) .. ")" end
    parts[#parts + 1] = text
  end
  return table.concat(parts, cfg.condOp == "or" and "  or  " or "  and  ")
end

function S.LayoutConds(card)
  local conds = S.cfg.conds
  local y = 30
  for i = 1, MAX_CONDS do
    local c, row = conds[i], rows[i]
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -y)
    row:SetPoint("TOPRIGHT", card, "TOPRIGHT", -14, -y)
    row:SetHeight(math.max(1, RowHeight(c)))
    if c then y = y + RowHeight(c) + 8 end
  end
  if #conds == 0 then
    S.At(emptyText, "TOPLEFT", card, "TOPLEFT", 14, -(y + 4))
    y = y + 26
  end
  S.At(addButton, "TOPLEFT", card, "TOPLEFT", 14, -y)
  return y + (#conds < MAX_CONDS and 40 or 8)
end

local function Changed()
  S.RefreshConds()
  S.Layout()
  S.Commit()
end

local function BuildRow(card, i)
  local row = CreateFrame("Frame", nil, card)
  row:SetHeight(32)
  local function Cond() return S.cfg and S.cfg.conds[i] end

  row.opText = S.Small(row, "If")
  row.opText:SetPoint("TOPLEFT", row, "TOPLEFT", 18, -7)
  row.op = UI.CreateButton(row, "AND", 54, false, function()
    S.cfg.condOp = (S.cfg.condOp == "or") and "and" or "or"
    S.RefreshConds()
    S.Commit()
  end, "Click to switch between AND (all must be true) and OR (any one is enough) for all the conditions.")
  row.op:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)

  row.typeDD = UI.CreateDropdown(row, 300, B.CONDITIONS, function(value)
    local c = Cond()
    if not c then return end
    -- Switching between two aura (or two item) conditions keeps what was filled in.
    if (B.AURA_CONDS[c.type] and B.AURA_CONDS[value]) or (B.ITEM_CONDS[c.type] and B.ITEM_CONDS[value]) then
      c.type = value
    else
      S.cfg.conds[i] = B.CondDefaults(value)
    end
    Changed()
  end)
  row.typeDD:SetPoint("TOPLEFT", row, "TOPLEFT", 62, 0)
  row.remove = UI.CreateButton(row, "X", 24, false, function()
    table.remove(S.cfg.conds, i)
    Changed()
  end, "Remove this condition")
  row.remove:SetPoint("LEFT", row.typeDD, "RIGHT", 8, 0)

  row.sub = CreateFrame("Frame", nil, row)
  row.sub:SetPoint("TOPLEFT", row, "TOPLEFT", 48, -34)
  row.sub:SetSize(560, 66)
  row.item = S.ItemPicker(row.sub, 0, function(id)
    local c = Cond()
    if c then c.item = id S.Commit() end
  end)
  row.aura = S.AuraForm(row.sub, Cond, 0)
  rows[i] = row
end

function S.BuildOnlyIf(card)
  emptyText = S.Small(card, "No conditions: this rule always applies.")
  for i = 1, MAX_CONDS do BuildRow(card, i) end
  addButton = UI.CreateButton(card, "+ Add condition", 140, false, function()
    if #S.cfg.conds >= MAX_CONDS then return end
    S.cfg.conds[#S.cfg.conds + 1] = {}
    Changed()
  end, "Add another condition. Switch between AND and OR with the chip in front of the second one.")
end
