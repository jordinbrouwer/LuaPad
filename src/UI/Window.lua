LuaPad = LuaPad or {}
local LP = LuaPad
local UI = LP.UI
local T = UI.THEME
local CE = LP.CodeEditor
local Simple = LP.SimpleMode
local Status = LP.StatusPanel
local List = LP.SnippetList
local Toolbar = LP.Toolbar

local Window = {}
LP.Window = Window

local frame, body, emptyText, simplePanel
local validateAt, needsRefresh

function Window.RequestRefresh()
  needsRefresh = true
end

function Window.SetSidebar(show)
  local right = show and -190 or -12
  CE.SetRightInset(right)
  simplePanel:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", right, 10)
end

local function ApplyMode(snippet)
  local simple = snippet and snippet.mode == "simple"
  CE.SetShown(not simple)
  simplePanel:SetShown(simple and true or false)
  Toolbar.SetSimple(simple)
  if simple then Simple.Load(snippet) end
end

local function UpdateDraft(snippet, plain)
  if not snippet or snippet.mode == "simple" then return end
  local had = snippet.draft ~= nil
  snippet.draft = plain ~= (snippet.code or "") and plain or nil
  if had ~= (snippet.draft ~= nil) then needsRefresh = true end
end

function LP.SelectSnippet(id)
  LuaPadDB.selected = id
  local snippet = LP.Get(id)
  if not snippet then
    body:Hide()
    emptyText:Show()
    List.Refresh()
    return
  end
  emptyText:Hide()
  body:Show()
  if snippet.mode == "simple" then snippet.draft = nil end
  Toolbar.Load(snippet)
  CE.Load(snippet.draft or snippet.code or "", true)
  ApplyMode(snippet)
  CE.Relayout()
  Status.Validate()
  List.Refresh()
end

-- Saving never switches a snippet on; one that is already on restarts with the new code.
function Window.Save()
  local snippet = LP.Current()
  if not snippet then return end
  local problem = snippet.enabled and LP.Incomplete(snippet)
  if problem then
    Toolbar.Refuse(problem)
    return
  end
  if snippet.mode ~= "simple" then
    snippet.code = CE.GetCode()
  else
    snippet.savedCode = snippet.code
    snippet.savedCfg = LP.DeepCopy(snippet.cfg)
  end
  snippet.draft = nil
  if snippet.enabled then
    LP.Run(snippet.id)
    LP.CheckReload(snippet.code)
  else
    LP.ClearError(snippet.id)
  end
  Toolbar.ShowSaved()
  Status.Validate()
  List.Refresh()
end

function Window.Revert()
  local s = LP.Current()
  if s and s.mode == "simple" then
    if not LP.IsDirty(s) or not s.savedCfg then return end
    s.cfg = LP.DeepCopy(s.savedCfg)
    s.code = s.savedCode
    ApplyMode(s)
    Simple.OnChanged(s)
    return
  end
  if not s or s.draft == nil then return end
  CE.Revert(s.id, s.code or "")
end

function Window.NewSnippet(mode)
  local snippet = LP.New(mode)
  LP.SelectSnippet(snippet.id)
  Toolbar.FocusName()
  List.ScrollToEnd()
end

CE.OnLayout = Toolbar.UpdateInfo
CE.OnSave = Window.Save
CE.OnEdited = function(plain, delay)
  UpdateDraft(LP.Current(), plain)
  Toolbar.UpdateInfo()
  validateAt = GetTime() + delay
end

Simple.OnChanged = function(snippet)
  if snippet.id ~= LuaPadDB.selected then return end
  CE.Load(snippet.code or "")
  CE.Relayout()
  Status.Validate()
  List.Refresh()
  needsRefresh = true
end

local function OnUpdate()
  CE.ScrollToCursor()
  Toolbar.OnUpdate()
  if validateAt and GetTime() >= validateAt then
    validateAt = nil
    Status.Validate()
    List.Refresh()
  end
  if needsRefresh then
    needsRefresh = false
    List.Refresh()
    Status.Refresh()
  end
end

local function BuildTitleBar()
  local titleBar = CreateFrame("Frame", nil, frame)
  titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
  titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
  titleBar:SetHeight(30)
  titleBar:EnableMouse(true)
  titleBar:RegisterForDrag("LeftButton")
  titleBar:SetScript("OnDragStart", function() frame:StartMoving() end)
  titleBar:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
  local tbg = titleBar:CreateTexture(nil, "BACKGROUND")
  tbg:SetAllPoints(titleBar)
  tbg:SetColorTexture(unpack(T.TITLE))
  local logo = titleBar:CreateTexture(nil, "ARTWORK")
  logo:SetSize(18, 18)
  logo:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
  logo:SetTexture("Interface\\AddOns\\LuaPad\\LuaPad")
  local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("LEFT", logo, "RIGHT", 6, 0)
  title:SetText("LuaPad")
  title:SetTextColor(unpack(T.GOLD))
  local close = UI.CreateButton(titleBar, "X", 28, false, function() frame:Hide() end)
  close:SetPoint("RIGHT", titleBar, "RIGHT", -6, 0)
  close:SetSize(18, 18)
  local tline = titleBar:CreateTexture(nil, "ARTWORK")
  tline:SetColorTexture(0.9, 0.2, 0.25, 0.6)
  tline:SetHeight(2)
  tline:SetPoint("BOTTOMLEFT", titleBar, "BOTTOMLEFT", 0, 0)
  tline:SetPoint("BOTTOMRIGHT", titleBar, "BOTTOMRIGHT", 0, 0)
  return titleBar
end

local function BuildSide(titleBar)
  local side = CreateFrame("Frame", nil, frame)
  side:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, 0)
  side:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
  side:SetWidth(180)
  local sbg = side:CreateTexture(nil, "BACKGROUND")
  sbg:SetAllPoints(side)
  sbg:SetColorTexture(unpack(T.INSET))
  local sline = side:CreateTexture(nil, "ARTWORK")
  sline:SetColorTexture(unpack(T.LINE))
  sline:SetWidth(1)
  sline:SetPoint("TOPRIGHT", side, "TOPRIGHT", 0, 0)
  sline:SetPoint("BOTTOMRIGHT", side, "BOTTOMRIGHT", 0, 0)
  List.Build(side)
  return side
end

local function Build()
  frame = CreateFrame("Frame", "LuaPadFrame", UIParent)
  frame:SetSize(940, 540)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("DIALOG")
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:Hide()
  tinsert(UISpecialFrames, "LuaPadFrame")
  local bg = frame:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(frame)
  bg:SetColorTexture(unpack(T.WINDOW))
  UI.AddBorder(frame, T.BORDER)

  local side = BuildSide(BuildTitleBar())

  local main = CreateFrame("Frame", nil, frame)
  main:SetPoint("TOPLEFT", side, "TOPRIGHT", 0, 0)
  main:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
  emptyText = main:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  emptyText:SetPoint("CENTER", main, "CENTER", 0, 0)
  emptyText:SetText("Create a snippet to get started")
  emptyText:SetTextColor(unpack(T.GRAY))
  emptyText:Hide()
  body = CreateFrame("Frame", nil, main)
  body:SetAllPoints(main)

  Toolbar.Build(body, main)
  local area = CE.Build(frame, body, main)
  Status.Build(body, main, area)
  simplePanel = Simple.Build(body, main)
  simplePanel:Hide()

  local driver = CreateFrame("Frame", nil, frame)
  driver:SetScript("OnUpdate", OnUpdate)

  frame:SetScript("OnShow", function()
    CE.MeasureLineHeight()
    local id = LuaPadDB.selected
    if not LP.Get(id) then
      local first = LuaPadDB.snippets[1]
      id = first and first.id or nil
    end
    LP.SelectSnippet(id)
  end)
  frame:SetScript("OnHide", function()
    CE.ClearFocus()
    UI.CloseMenu()
    Simple.OnHide()
    List.ResetDelete()
  end)

  LP.OnStateChanged = Window.RequestRefresh
end

function LP.OpenSnippet(id)
  if not frame then Build() end
  if LP.Get(id) then LuaPadDB.selected = id end
  if frame:IsShown() then LP.SelectSnippet(LuaPadDB.selected) else frame:Show() end
end

function LP.IsShowingSnippet(id)
  return frame and frame:IsShown() and LuaPadDB and LuaPadDB.selected == id or false
end

function LP.ToggleEditor()
  if not frame then Build() end
  if frame:IsShown() then frame:Hide() else frame:Show() end
end
