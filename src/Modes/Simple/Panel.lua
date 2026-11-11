LuaPad = LuaPad or {}
local LP = LuaPad
local UI = LP.UI
local T = UI.THEME
local B = LP.Builder

local S = { loading = false }
LP.SimpleMode = S

local panel, scroll, content, vbar, hint
local cards = {}
local syncing = false
local openStep = 1

function S.Persistent()
  return S.cfg and B.STATE_TRIGGERS[S.cfg.trigger.type] or false
end

function S.TriggerIcon()
  local cfg = S.cfg
  if cfg and B.CD_TRIGGERS[cfg.trigger.type] then
    local id = tonumber(cfg.trigger.spell)
    local info = id and C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(id)
    return info and info.iconID
  end
  if cfg and B.AURA_TRIGGERS[cfg.trigger.type] then
    local name = strtrim(cfg.trigger.aura or "")
    if name ~= "" and C_Spell and C_Spell.GetSpellInfo then
      local info = C_Spell.GetSpellInfo(tonumber(name) or name)
      return info and info.iconID
    end
    return
  end
  local id = cfg and tonumber(cfg.trigger.item)
  if id and C_Item and C_Item.GetItemIconByID then return C_Item.GetItemIconByID(id) end
end

local function UpdateHint()
  if not S.cfg then return end
  local problem = B.Validate(S.cfg)
  hint:SetText(problem and ("|cffff6b6b" .. problem .. "|r") or "")
end

function S.Commit()
  if S.loading or not S.snippet then return end
  S.snippet.code = B.Generate(S.cfg)
  S.ShowPreview()
  UpdateHint()
  if cards.when then S.Layout() end
  if S.OnChanged then S.OnChanged(S.snippet) end
end

function S.Layout()
  if not S.cfg then return end
  local y = 2
  local function Place(card, idx, height)
    local outer = card.outer
    local open = openStep == idx
    outer:ClearAllPoints()
    outer:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
    outer:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -y)
    local h = open and height or 36
    outer:SetHeight(h)
    card:SetShown(open)
    card.head.sum:SetShown(not open)
    card.head.chev:SetText(open and "^" or "v")
    card.head.chev:SetTextColor(unpack(open and T.GOLD or T.GRAY))
    card.head.dot:SetColorTexture(unpack(open and T.RED or T.LINE))
    y = y + h + 8
  end
  cards.when.head.sum:SetText(S.TriggerText())
  cards.cond.head.sum:SetText(S.CondText())
  cards.act.head.sum:SetText(S.ActionText())
  Place(cards.when, 1, S.WhenHeight())
  Place(cards.cond, 2, S.LayoutConds(cards.cond))
  Place(cards.act, 3, S.LayoutActions(cards.act))
  S.At(hint, "TOPLEFT", content, "TOPLEFT", 2, -y)
  content:SetHeight(y + 30)
  if scroll.UpdateScrollChildRect then scroll:UpdateScrollChildRect() end
  local needBar = scroll:GetVerticalScrollRange() > 1
  vbar:SetShown(needBar)
  scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", needBar and -12 or 0, 0)
end

function S.Load(snippet)
  S.StopMoving()
  S.snippet = snippet
  S.cfg = B.EnsureCfg(snippet)
  if snippet.savedCode == nil then
    snippet.savedCode = snippet.code
    snippet.savedCfg = LP.DeepCopy(S.cfg)
  end
  content:SetWidth(math.max(scroll:GetWidth(), 100))
  openStep = (S.cfg.trigger.type and #S.cfg.actions == 0) and 3 or 1
  S.RefreshConds()
  S.RefreshTrigger()
  S.RefreshActions()
  UpdateHint()
  scroll:SetVerticalScroll(0)
end

function S.OnHide()
  S.StopMoving()
  if S.cfg then S.RefreshActions() end
end

local function ToggleStep(index)
  if openStep == 3 and index ~= 3 then S.StopMoving() end
  openStep = (openStep == index) and 0 or index
  if S.cfg then S.RefreshActions() end
end

function S.Build(parent, main)
  panel = CreateFrame("Frame", nil, parent)
  panel:SetPoint("TOPLEFT", main, "TOPLEFT", 12, -44)
  panel:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", -190, 10)

  scroll = CreateFrame("ScrollFrame", nil, panel)
  scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
  scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
  content = CreateFrame("Frame", nil, scroll)
  content:SetSize(10, 10)
  scroll:SetScrollChild(content)
  scroll:SetScript("OnSizeChanged", function(_, width) content:SetWidth(width) end)

  vbar = UI.CreateScrollbar(panel, true)
  vbar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -2, -2)
  vbar:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -2, 2)
  vbar:Hide()
  scroll:SetScript("OnScrollRangeChanged", function(self, _, yrange)
    syncing = true
    vbar:SetMinMaxValues(0, yrange)
    syncing = false
    vbar:SetShown(yrange > 1)
    local h = self:GetHeight()
    vbar:SetThumbLength(UI.Clamp(h * h / (h + yrange), 24, math.max(24, h)))
  end)
  scroll:SetScript("OnVerticalScroll", function(_, offset)
    syncing = true
    vbar:SetValue(offset)
    syncing = false
  end)
  vbar:SetScript("OnValueChanged", function(_, value) if not syncing then scroll:SetVerticalScroll(value) end end)
  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel", function(self, delta)
    self:SetVerticalScroll(UI.Clamp(self:GetVerticalScroll() - delta * 50, 0, self:GetVerticalScrollRange()))
  end)

  cards.when = S.MakeCard(content, "WHEN", 1, ToggleStep)
  cards.cond = S.MakeCard(content, "ONLY IF", 2, ToggleStep)
  cards.act = S.MakeCard(content, "THEN", 3, ToggleStep)
  S.BuildWhen(cards.when)
  S.BuildOnlyIf(cards.cond)
  S.BuildThen(cards.act)

  hint = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  hint:SetJustifyH("LEFT")

  return panel
end
