LuaPad = LuaPad or {}
local LP = LuaPad
local UI = LP.UI
local T = UI.THEME
local B = LP.Builder
local S = LP.SimpleMode

function S.Small(parent, text, color)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  fs:SetText(text)
  fs:SetTextColor(unpack(color or T.GRAY))
  return fs
end
local Small = S.Small

function S.NumEdit(parent, width)
  local edit = UI.CreateEdit(parent, width, 24)
  edit:SetNumeric(true)
  edit:SetMaxLetters(7)
  edit:SetTextInsets(8, 8, 0, 0)
  return edit
end
local NumEdit = S.NumEdit

function S.At(widget, point, relative, relPoint, x, y)
  widget:ClearAllPoints()
  widget:SetPoint(point, relative, relPoint, x, y)
end

-- Returns the card's body frame; body.outer is the card and body.head its clickable header.
function S.MakeCard(parent, title, index, onToggle)
  local outer = CreateFrame("Frame", nil, parent)
  local bg = outer:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(outer)
  bg:SetColorTexture(unpack(T.INSET))
  UI.AddBorder(outer, T.LINE)

  local head = CreateFrame("Button", nil, outer)
  head:SetPoint("TOPLEFT", outer, "TOPLEFT", 0, 0)
  head:SetPoint("TOPRIGHT", outer, "TOPRIGHT", 0, 0)
  head:SetHeight(36)
  head.hl = head:CreateTexture(nil, "BACKGROUND")
  head.hl:SetAllPoints(head)
  head.hl:SetColorTexture(1, 1, 1, 0)
  head:SetScript("OnEnter", function(self) self.hl:SetColorTexture(1, 1, 1, 0.04) end)
  head:SetScript("OnLeave", function(self) self.hl:SetColorTexture(1, 1, 1, 0) end)
  head:SetScript("OnClick", function() onToggle(index) end)
  head.dot = head:CreateTexture(nil, "ARTWORK")
  head.dot:SetSize(20, 20)
  head.dot:SetPoint("LEFT", head, "LEFT", 10, 0)
  head.num = head:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  head.num:SetPoint("CENTER", head.dot, "CENTER", 0, 0)
  head.num:SetText(tostring(index))
  head.title = head:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  head.title:SetPoint("LEFT", head.dot, "RIGHT", 10, 0)
  head.title:SetText(title)
  head.title:SetTextColor(unpack(T.GOLD))
  head.chev = head:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  head.chev:SetPoint("RIGHT", head, "RIGHT", -12, 0)
  head.sum = head:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  head.sum:SetPoint("LEFT", head.title, "RIGHT", 14, 0)
  head.sum:SetPoint("RIGHT", head.chev, "LEFT", -12, 0)
  head.sum:SetJustifyH("LEFT")
  head.sum:SetWordWrap(false)
  head.sum:SetTextColor(unpack(T.GRAY))

  local body = CreateFrame("Frame", nil, outer)
  body:SetPoint("TOPLEFT", outer, "TOPLEFT", 0, -6)
  body:SetPoint("BOTTOMRIGHT", outer, "BOTTOMRIGHT", 0, 0)
  body.outer, body.head = outer, head
  return body
end

local pickers = {}

function S.ItemPicker(parent, y, onChange)
  local p = { shown = false }
  p.label = Small(parent, "Item ID")
  p.label:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y - 5)
  p.edit = NumEdit(parent, 100)
  p.edit:SetMaxLetters(9)
  p.edit:SetPoint("TOPLEFT", parent, "TOPLEFT", 76, y)
  p.icon = parent:CreateTexture(nil, "ARTWORK")
  p.icon:SetSize(22, 22)
  p.icon:SetPoint("TOPLEFT", parent, "TOPLEFT", 190, y - 1)
  p.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  p.name = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  p.name:SetPoint("LEFT", p.icon, "RIGHT", 8, 0)
  p.tip = Small(parent, "or shift-click / drag an item here")
  p.tip:SetPoint("TOPLEFT", parent, "TOPLEFT", 190, y - 5)

  function p.Refresh()
    local id = tonumber(p.edit:GetText())
    local name, icon, quality
    if id and id > 0 and C_Item then
      name = C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)
      if name then
        icon = C_Item.GetItemIconByID and C_Item.GetItemIconByID(id)
        quality = C_Item.GetItemQualityByID and C_Item.GetItemQualityByID(id)
      elseif C_Item.DoesItemExistByID and C_Item.DoesItemExistByID(id) then
        name = "|cff6b7280Loading...|r"
        if C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
      else
        name = "|cffff6b6bUnknown item|r"
      end
      local color = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
      if color and color.hex and icon then name = color.hex .. name .. "|r" end
    end
    p.icon:SetTexture(icon)
    p.icon:SetShown(p.shown and icon ~= nil)
    p.name:SetText(name or "")
    p.name:SetShown(p.shown and name ~= nil)
    p.tip:SetShown(p.shown and not id)
  end

  function p.SetShown(_, show)
    p.shown = show and true or false
    p.label:SetShown(p.shown)
    p.edit:SetShown(p.shown)
    if not p.shown then p.edit:ClearFocus() end
    p.Refresh()
  end

  function p.Set(_, id)
    p.edit:SetText(id and tostring(id) or "")
    p.Refresh()
  end

  function p.Pick(id)
    p.edit:SetText(tostring(id))
    p.edit:ClearFocus()
    onChange(id)
    p.Refresh()
  end

  p.edit:SetScript("OnTextChanged", function(self, user)
    if S.loading or not user then return end
    onChange(tonumber(self:GetText()))
    p.Refresh()
  end)
  local function TakeFromCursor()
    local kind, id = GetCursorInfo()
    if kind == "item" and id then
      ClearCursor()
      p.Pick(id)
    end
  end
  p.edit:SetScript("OnReceiveDrag", TakeFromCursor)
  p.edit:HookScript("OnMouseDown", TakeFromCursor)

  pickers[#pickers + 1] = p
  p:SetShown(false)
  return p
end

local function OnInsertLink(link)
  if type(link) ~= "string" then return end
  local id = tonumber(link:match("item:(%d+)"))
  if not id then return end
  for _, p in ipairs(pickers) do
    if p.shown and p.edit:HasFocus() then p.Pick(id) return end
  end
end
if ChatEdit_InsertLink then hooksecurefunc("ChatEdit_InsertLink", OnInsertLink) end
if ChatFrameUtil and ChatFrameUtil.InsertLink then hooksecurefunc(ChatFrameUtil, "InsertLink", OnInsertLink) end

local itemWatch = CreateFrame("Frame")
itemWatch:RegisterEvent("GET_ITEM_INFO_RECEIVED")
itemWatch:SetScript("OnEvent", function()
  for _, p in ipairs(pickers) do
    if p.shown then p.Refresh() end
  end
end)

-- Settings of one aura check, shared by the aura triggers and the aura conditions.
-- getSpec returns the table to edit; top is the y offset of the first line.
function S.AuraForm(parent, getSpec, top)
  top = top or -62
  local f = { shown = false }
  local function Change(key, value)
    local spec = getSpec()
    if not spec then return end
    spec[key] = value
    S.Commit()
  end
  f.label = Small(parent, "Name or ID")
  f.label:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, top - 5)
  f.edit = UI.CreateEdit(parent, 150, 24)
  f.edit:SetMaxLetters(60)
  f.edit:SetTextInsets(8, 8, 0, 0)
  f.edit:SetPoint("TOPLEFT", parent, "TOPLEFT", 84, top)
  f.typeDD = UI.CreateDropdown(parent, 90, B.AURATYPES, function(value) Change("auraType", value) end)
  f.typeDD:SetPoint("TOPLEFT", parent, "TOPLEFT", 242, top)
  f.unitDD = UI.CreateDropdown(parent, 140, B.UNITS, function(value) Change("unit", value) end)
  f.unitDD:SetPoint("TOPLEFT", parent, "TOPLEFT", 340, top)
  f.stackLabel = Small(parent, "At least")
  f.stackLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, top - 39)
  f.stackEdit = NumEdit(parent, 44)
  f.stackEdit:SetMaxLetters(3)
  f.stackEdit:SetPoint("TOPLEFT", parent, "TOPLEFT", 84, top - 34)
  f.stackHint = Small(parent, "stack(s)")
  f.stackHint:SetPoint("LEFT", f.stackEdit, "RIGHT", 8, 0)
  f.srcDD = UI.CreateDropdown(parent, 110, B.SOURCES, function(value) Change("source", value) end)
  f.srcDD:SetPoint("TOPLEFT", parent, "TOPLEFT", 190, top - 34)
  f.icon = parent:CreateTexture(nil, "ARTWORK")
  f.icon:SetSize(22, 22)
  f.icon:SetPoint("TOPLEFT", parent, "TOPLEFT", 316, top - 35)
  f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  f.name = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  f.name:SetPoint("LEFT", f.icon, "RIGHT", 8, 0)

  -- The game only knows the names of spells it has already seen.
  function f.UpdateInfo()
    local text = strtrim(f.edit:GetText() or "")
    local icon, name
    if text ~= "" and C_Spell and C_Spell.GetSpellInfo then
      local info = C_Spell.GetSpellInfo(tonumber(text) or text)
      if info then icon, name = info.iconID, info.name end
    end
    f.icon:SetTexture(icon)
    f.icon:SetShown(f.shown and icon ~= nil)
    f.name:SetText(name or "")
    f.name:SetShown(f.shown and name ~= nil)
  end

  f.edit:SetScript("OnTextChanged", function(self, user)
    if S.loading or not user then return end
    Change("aura", self:GetText())
    f.UpdateInfo()
  end)
  f.stackEdit:SetScript("OnTextChanged", function(self, user)
    if S.loading or not user then return end
    Change("stacks", tonumber(self:GetText()) or 1)
  end)

  local parts = { "label", "edit", "typeDD", "unitDD", "stackLabel", "stackEdit", "stackHint", "srcDD" }
  function f.SetShown(_, show)
    f.shown = show and true or false
    for _, key in ipairs(parts) do f[key]:SetShown(f.shown) end
    if not f.shown then f.edit:ClearFocus() f.stackEdit:ClearFocus() end
    f.UpdateInfo()
  end
  function f.Load(_, spec)
    f.edit:SetText(spec.aura or "")
    f.typeDD:SetValue(spec.auraType or "HELPFUL")
    f.unitDD:SetValue(spec.unit or "player")
    f.stackEdit:SetText(tostring(spec.stacks or 1))
    f.srcDD:SetValue(spec.source or "any")
    f.UpdateInfo()
  end
  f:SetShown(false)
  return f
end
