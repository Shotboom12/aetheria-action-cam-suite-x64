-- Action Camera Suite 1.0.4.2: BUILT-IN addon defaults from current live player settings.
-- This file loads as the first file INSIDE Immersion_DialogUITheme, not as a separate importer.
-- Existing account SavedVariables are left alone.
local cameraSuiteCreatedDefault = type(_G["DUIImmersionParchment"]) ~= "table"
if cameraSuiteCreatedDefault then
  _G["DUIImmersionParchment"] = {
  ["enabled"] = true,
  ["font"] = "default",
  ["fontSize"] = 0,
  ["scope"] = "all",
}
end
