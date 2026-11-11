LuaPad = LuaPad or {}
local LP = LuaPad
local UI = LP.UI
local B = LP.Builder
local S = LP.SimpleMode
local Small, NumEdit = S.Small, S.NumEdit

local W = {}

local function IsSpellTrigger(kind)
  return kind == "cast" or (B.CD_TRIGGERS[kind] or false)
end

local function UpdateSpellInfo()
  local id = tonumber(W.spellEdit:GetText())
  local name, icon
  if id and id > 0 and C_Spell and C_Spell.GetSpellInfo then
    local info = C_Spell.GetSpellInfo(id)
    if info then name, icon = info.name, info.iconID end
  end
  W.spellIcon:SetTexture(icon)
  W.spellIcon:SetShown(icon ~= nil)
  W.spellName:SetText(name or (id and "|cffff6b6bUnknown spell|r" or ""))
end

function S.RefreshTrigger()
  local t = S.cfg.trigger
  local kind = t.type
  local isSpell = IsSpellTrigger(kind)
  local isReach, isGain, isTimer = kind == "resource_reach", kind == "resource_gain", kind == "timer"
  local isItem = B.ITEM_TRIGGERS[kind] or false
  local isAura = B.AURA_TRIGGERS[kind] or false
  W.itemT:SetShown(isItem)
  W.spellLabel:SetShown(isSpell)
  W.spellEdit:SetShown(isSpell)
  W.spellName:SetShown(isSpell)
  W.resDD:SetShown(isReach or isGain)
  W.valLabel:SetShown(isReach)
  W.valEdit:SetShown(isReach)
  W.secLabel:SetShown(isTimer)
  W.secEdit:SetShown(isTimer)
  W.secUnit:SetShown(isTimer)
  W.auraT:SetShown(isAura)
  S.loading = true
  W.trigDD:SetValue(kind)
  if isAura then W.auraT:Load(t) end
  if isSpell then
    W.spellEdit:SetText(t.spell and tostring(t.spell) or "")
    UpdateSpellInfo()
  else
    W.spellIcon:Hide()
  end
  if isReach or isGain then W.resDD:SetValue(t.resource) end
  if isReach then W.valEdit:SetText(t.value and tostring(t.value) or "") end
  if isTimer then W.secEdit:SetText(t.seconds and tostring(t.seconds) or "") end
  if isItem then W.itemT:Set(t.item) end
  S.loading = false
end

function S.WhenHeight()
  local kind = S.cfg.trigger.type
  local hasParams = IsSpellTrigger(kind) or kind == "resource_reach" or kind == "resource_gain" or kind == "timer"
    or B.ITEM_TRIGGERS[kind]
  return (B.AURA_TRIGGERS[kind] and 134 or (hasParams and 98 or 64)) + 6
end

function S.TriggerText()
  local t = S.cfg.trigger
  if not t.type then return "|cffff6b6bPick when this should happen|r" end
  local def = B.Find(B.TRIGGERS, t.type)
  local text = def and (def.label:gsub("%.%.%.$", "")) or "?"
  local detail
  if B.AURA_TRIGGERS[t.type] and strtrim(t.aura or "") ~= "" then
    detail = strtrim(t.aura)
  elseif IsSpellTrigger(t.type) and tonumber(t.spell) then
    local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(tonumber(t.spell))
    detail = info and info.name or ("spell " .. t.spell)
  elseif B.ITEM_TRIGGERS[t.type] and tonumber(t.item) then
    local name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(tonumber(t.item))
    detail = name or ("item " .. t.item)
  elseif t.type == "timer" and tonumber(t.seconds) then
    detail = t.seconds .. "s"
  end
  return detail and (text .. ": " .. detail) or text
end

local function NumberField(edit, key, after)
  edit:SetScript("OnTextChanged", function(self, user)
    if S.loading or not user then return end
    S.cfg.trigger[key] = tonumber(self:GetText())
    if after then after() end
    S.Commit()
  end)
end

function S.BuildWhen(card)
  W.trigDD = UI.CreateDropdown(card, 330, B.TRIGGERS, function(value)
    S.cfg.trigger = B.TriggerDefaults(value)
    S.RefreshTrigger()
    S.RefreshActions()
    S.Commit()
  end)
  W.trigDD:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -28)

  W.spellLabel = Small(card, "Spell ID")
  W.spellLabel:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -67)
  W.spellEdit = NumEdit(card, 100)
  W.spellEdit:SetPoint("TOPLEFT", card, "TOPLEFT", 76, -62)
  NumberField(W.spellEdit, "spell", UpdateSpellInfo)
  W.spellIcon = card:CreateTexture(nil, "ARTWORK")
  W.spellIcon:SetSize(22, 22)
  W.spellIcon:SetPoint("TOPLEFT", card, "TOPLEFT", 190, -63)
  W.spellIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  W.spellName = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  W.spellName:SetPoint("LEFT", W.spellIcon, "RIGHT", 8, 0)

  W.resDD = UI.CreateDropdown(card, 200, B.RESOURCES, function(value)
    S.cfg.trigger.resource = value
    S.Commit()
  end)
  W.resDD:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -62)
  W.valLabel = Small(card, "reaches at least")
  W.valLabel:SetPoint("TOPLEFT", card, "TOPLEFT", 226, -67)
  W.valEdit = NumEdit(card, 60)
  W.valEdit:SetPoint("TOPLEFT", card, "TOPLEFT", 326, -62)
  W.valEdit:SetMaxLetters(2)
  NumberField(W.valEdit, "value")

  W.secLabel = Small(card, "Every")
  W.secLabel:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -67)
  W.secEdit = NumEdit(card, 60)
  W.secEdit:SetPoint("TOPLEFT", card, "TOPLEFT", 56, -62)
  NumberField(W.secEdit, "seconds")
  W.secUnit = Small(card, "seconds")
  W.secUnit:SetPoint("TOPLEFT", card, "TOPLEFT", 124, -67)

  W.auraT = S.AuraForm(card, function() return S.cfg and S.cfg.trigger end)

  W.itemT = S.ItemPicker(card, -62, function(id)
    S.cfg.trigger.item = id
    S.Commit()
  end)
end
