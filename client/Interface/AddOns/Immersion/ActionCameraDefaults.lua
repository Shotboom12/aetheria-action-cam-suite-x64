-- Action Camera Suite 1.0.4.2: BUILT-IN addon defaults from current live player settings.
-- This file loads as the first file INSIDE Immersion, not as a separate importer.
-- Existing account SavedVariables are left alone.
local cameraSuiteCreatedDefault = type(_G["ImmersionSetup"]) ~= "table"
if cameraSuiteCreatedDefault then
  _G["ImmersionSetup"] = {
  ["accept"] = "E",
  ["anidivisor"] = 10,
  ["bookreading"] = false,
  ["boxlock"] = false,
  ["boxoffsetX"] = 23.52938144904491,
  ["boxoffsetY"] = 15.68614791161443,
  ["boxpoint"] = "Bottom",
  ["boxscale"] = 1,
  ["camerarotationenabled"] = false,
  ["debuginfo"] = false,
  ["delaydivisor"] = 5,
  ["disableprogression"] = true,
  ["elementscale"] = 1,
  ["enablenumbers"] = true,
  ["flipshortcuts"] = false,
  ["gossipatcursor"] = false,
  ["gossipmode"] = true,
  ["hdmodels"] = true,
  ["hideminimap"] = true,
  ["hidetracker"] = true,
  ["hideui"] = true,
  ["immersivemode"] = true,
  ["inspect"] = "SHIFT",
  ["reset"] = "TAB",
  ["scale"] = 1,
  ["strata"] = "MEDIUM",
  ["titlelock"] = false,
  ["titleoffset"] = 837.9216488765242,
  ["titleoffsetY"] = -279.6077109753213,
  ["titlescale"] = 0.8,
}
end
