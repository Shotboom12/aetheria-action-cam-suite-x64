-- Action Camera Suite 1.0.4.2: BUILT-IN addon defaults from current live player settings.
-- This file loads as the first file INSIDE DialogUI, not as a separate importer.
-- Existing account SavedVariables are left alone.
local cameraSuiteCreatedDefault = type(_G["DialogUISettings"]) ~= "table"
if cameraSuiteCreatedDefault then
  _G["DialogUISettings"] = {
  ["autoSelect"] = false,
  ["bookDimEnabled"] = true,
  ["darkMode"] = false,
  ["dimMode"] = true,
  ["disableAnim"] = false,
  ["focusMode"] = false,
  ["fontFace"] = "friz",
  ["fontScale"] = 1.2,
  ["framePosition"] = "LEFT",
  ["frameScale"] = 1.3,
  ["frameSide"] = "LEFT",
}
end
