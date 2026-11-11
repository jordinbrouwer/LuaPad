std = "lua51"
max_line_length = false
exclude_files = { ".git/**" }

globals = { "LuaPad", "LuaPadDB", "SLASH_LUAPAD1", "SLASH_LUAPAD2", "SlashCmdList" }

read_globals = {
  "CreateFrame", "CreateFont", "UIParent", "UIErrorsFrame", "STANDARD_TEXT_FONT", "ITEM_QUALITY_COLORS",
  "hooksecurefunc", "wipe", "tinsert", "strtrim", "date", "debugstack", "GetTime", "C_Timer", "C_Item", "C_Spell", "C_EventUtils",
  "GameTooltip", "GameTooltip_Hide", "Settings", "SettingsPanel", "HideUIPanel", "ReloadUI", "PlaySound",
  "ChatFrameUtil", "ChatEdit_InsertLink", "GetCurrentKeyBoardFocus", "GetCursorPosition", "GetCursorInfo", "ClearCursor",
  "IsShiftKeyDown", "IsControlKeyDown", "LuaPadFrame", "UISpecialFrames",
}