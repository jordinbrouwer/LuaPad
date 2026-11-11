LuaPad = LuaPad or {}
local LP = LuaPad
local UI = LP.UI
local T = UI.THEME
local CE = LP.CodeEditor

local Toolbar = {}
LP.Toolbar = Toolbar

local nameEdit, toggle, convertBtn, revertBtn, simpleRevert, simpleInfo
local savedUntil, convertUntil

function Toolbar.Refuse(problem)
  UIErrorsFrame:AddMessage("LuaPad: can't switch on yet. " .. problem, 1, 0.42, 0.42)
end

function Toolbar.UpdateLock()
  if not toggle then return end
  local blocked = LP.Incomplete(LP.Current()) and not toggle.checked
  toggle:SetAlpha(blocked and 0.45 or 1)
end

local function SimpleInfoText(draft)
  if savedUntil then return "|cff66d97fSaved|r" end
  if draft then return "|cffffcc4dUnsaved changes|r" end
  return ""
end

function Toolbar.UpdateInfo()
  if not simpleInfo then return end
  local s = LP.Current()
  local isSimple = s and s.mode == "simple"
  local draft = LP.IsDirty(s)
  local info
  if savedUntil then
    info = "|cff66d97fSaved|r"
  elseif draft and not isSimple then
    info = "|cffffcc4dUnsaved changes|r|cff6b7280   ·   Ctrl+S save   ·   Ctrl+Z undo|r"
  else
    info = ("|cff6b7280%d lines   ·   Ctrl+S to save|r"):format(CE.LineCount())
  end
  CE.SetHeader(s and (((s.name and s.name ~= "") and s.name or "untitled") .. ".lua") or nil, info)
  revertBtn:SetShown((draft and not isSimple) and true or false)
  simpleRevert:SetShown((draft and isSimple) and true or false)
  simpleInfo:SetText(isSimple and SimpleInfoText(draft) or "")
end

function Toolbar.Load(snippet)
  nameEdit:SetText(snippet.name or "")
  toggle:SetChecked(snippet.enabled)
end

function Toolbar.SetSimple(simple)
  convertBtn:SetShown(simple and true or false)
end

function Toolbar.FocusName()
  nameEdit:SetFocus()
  nameEdit:HighlightText()
end

function Toolbar.ShowSaved()
  savedUntil = GetTime() + 2.5
  Toolbar.UpdateInfo()
end

function Toolbar.OnUpdate()
  if savedUntil and GetTime() >= savedUntil then
    savedUntil = nil
    Toolbar.UpdateInfo()
  end
end

local function ResetConvert()
  convertUntil = nil
  convertBtn.Label:SetText("Convert to code")
end

local function Convert()
  local snippet = LP.Current()
  if not snippet or snippet.mode ~= "simple" then return end
  if convertUntil and GetTime() < convertUntil then
    ResetConvert()
    snippet.mode, snippet.cfg = nil, nil
    snippet.savedCode, snippet.savedCfg = nil, nil
    LP.SelectSnippet(snippet.id)
    return
  end
  convertUntil = GetTime() + 3
  convertBtn.Label:SetText("Sure? One-way")
  convertBtn.Label:SetTextColor(unpack(T.RED))
  C_Timer.After(3.1, function()
    if convertUntil and GetTime() >= convertUntil then
      ResetConvert()
      convertBtn:Rest()
    end
  end)
end

local function OnToggle(checked)
  local snippet = LP.Current()
  if not snippet then return end
  local problem = checked and LP.Incomplete(snippet)
  if problem then
    toggle:SetChecked(false)
    Toolbar.UpdateLock()
    Toolbar.Refuse(problem)
    return
  end
  LP.SetEnabled(snippet.id, checked)
  if checked then LP.CheckReload(snippet.code) end
  LP.StatusPanel.Validate()
  LP.SnippetList.Refresh()
end

function Toolbar.Build(body, main)
  local Window = LP.Window
  nameEdit = UI.CreateEdit(body, 200, 24)
  nameEdit:SetPoint("TOPLEFT", main, "TOPLEFT", 12, -10)
  nameEdit:SetMaxLetters(60)
  nameEdit:SetScript("OnTextChanged", function(self, user)
    local snippet = LP.Current()
    if user and snippet then
      snippet.name = self:GetText()
      Toolbar.UpdateInfo()
      Window.RequestRefresh()
    end
  end)
  nameEdit:SetScript("OnEnterPressed", CE.Focus)

  toggle = UI.CreateToggle(body, "Enabled", OnToggle)
  toggle:SetPoint("LEFT", nameEdit, "RIGHT", 12, 0)
  UI.AddTooltip(toggle, function()
    local problem = LP.Incomplete(LP.Current())
    if problem and not toggle.checked then return "|cffff6b6bCan't switch on yet:|r " .. problem end
    return "Run this snippet automatically at every login."
  end)

  local save = UI.CreateButton(body, "Save", 80, true, Window.Save, "Saves the snippet. If it is switched on, it restarts with the new code. Shortcut: Ctrl+S inside the editor.")
  save:SetPoint("TOPRIGHT", main, "TOPRIGHT", -12, -10)

  convertBtn = UI.CreateButton(body, "Convert to code", 120, false, Convert, "Turns this rule into Lua code you can edit freely. You can't go back to Simple mode afterwards.")
  convertBtn:SetPoint("RIGHT", save, "LEFT", -8, 0)
  convertBtn:Hide()

  revertBtn = UI.CreateButton(body, "Revert", 80, false, Window.Revert, "Throws away unsaved changes and goes back to the last saved version. Ctrl+Z brings them back.")
  revertBtn:SetPoint("RIGHT", save, "LEFT", -8, 0)
  revertBtn:Hide()

  simpleRevert = UI.CreateButton(body, "Revert", 80, false, Window.Revert, "Throws away the changes you haven't saved and goes back to the last saved version of this rule.")
  simpleRevert:SetPoint("RIGHT", convertBtn, "LEFT", -8, 0)
  simpleRevert:Hide()
  simpleInfo = body:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  simpleInfo:SetPoint("RIGHT", simpleRevert, "LEFT", -14, 0)
end
