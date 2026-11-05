-- Action Camera Suite 1.0.4.2: BUILT-IN addon defaults from current live player settings.
-- This file loads as the first file INSIDE DragonUI, not as a separate importer.
-- Existing account SavedVariables are left alone.
local cameraSuiteCreatedDefault = type(_G["DragonUIDB"]) ~= "table"
if cameraSuiteCreatedDefault then
  _G["DragonUIDB"] = {
  ["global"] = {
    ["defaultProfile"] = "MAIN UI",
  },
  ["profiles"] = {
    ["Default"] = {
      ["actionbars"] = {
        ["bag_show_in_combat"] = true,
        ["bag_show_on_hover"] = true,
        ["bag_visibility_fade_out_delay"] = 1,
        ["bag_visibility_fade_out_duration"] = 0.199999988079071,
        ["bag_visibility_logic"] = "or",
        ["bottom_left_show_in_combat"] = true,
        ["bottom_left_show_on_hover"] = true,
        ["bottom_left_show_with_target"] = true,
        ["bottom_left_visibility_logic"] = "or",
        ["bottom_right_show_in_combat"] = true,
        ["bottom_right_show_on_hover"] = true,
        ["bottom_right_show_with_target"] = true,
        ["bottom_right_visibility_logic"] = "or",
        ["left_show_in_combat"] = true,
        ["left_show_on_hover"] = true,
        ["left_show_with_target"] = true,
        ["left_visibility_logic"] = "or",
        ["main_show_in_combat"] = true,
        ["main_show_on_hover"] = true,
        ["main_show_with_target"] = true,
        ["main_visibility_logic"] = "or",
        ["micro_show_on_hover"] = true,
        ["micro_visibility_fade_out_delay"] = 1,
        ["right_show_in_combat"] = true,
        ["right_show_on_hover"] = true,
        ["right_show_with_target"] = true,
        ["right_visibility_logic"] = "or",
        ["visibility_fade_out_delay"] = 1,
        ["visibility_fade_out_duration"] = 1,
      },
      ["additional"] = {
        ["extrabar1"] = {
          ["show_in_combat"] = true,
          ["show_on_hover"] = true,
          ["show_with_target"] = false,
          ["spacing_visual_v2"] = true,
          ["visibility_logic"] = "or",
        },
        ["stance"] = {
          ["anchor"] = "BOTTOMLEFT",
          ["button_size"] = 21,
          ["hide_in_combat"] = false,
          ["manual_position"] = true,
          ["posX"] = 0,
          ["posY"] = 0,
          ["show_in_combat"] = true,
          ["show_on_hover"] = true,
          ["visibility_logic"] = "or",
          ["x_position"] = 353,
          ["y_offset"] = -194,
        },
        ["totem"] = {
          ["anchor"] = "CENTER",
          ["posX"] = 0,
          ["posY"] = 0,
        },
      },
      ["bags"] = {
        ["scale"] = 0.7900000214576721,
      },
      ["buffs"] = {
        ["buff_scale"] = 0.7,
        ["buffs_per_row"] = 8,
        ["debuff_scale"] = 0.7,
        ["debuffs_per_row"] = 4,
        ["show_in_combat"] = true,
        ["show_on_hover"] = true,
        ["show_with_target"] = true,
        ["visibility_fade_out_delay"] = 1,
        ["visibility_fade_out_duration"] = 1,
      },
      ["castbar"] = {
        ["scale"] = 1.5,
        ["target"] = {
          ["override"] = true,
          ["scale"] = 2,
        },
      },
      ["mainbars"] = {
        ["scale_bottomleft"] = 0.699999988079071,
        ["scale_bottomright"] = 0.699999988079071,
        ["spacing_migrated"] = true,
      },
      ["micromenu"] = {
        ["grayscale"] = {
          ["icon_spacing"] = 1,
        },
        ["normal"] = {
          ["icon_spacing"] = -6,
        },
        ["spacing_is_padding"] = true,
      },
      ["minimap"] = {
        ["addon_button_fade"] = true,
        ["blip_skin"] = false,
        ["border_alpha"] = 0,
        ["clock_font_size"] = 11,
        ["collector_style"] = "classic",
        ["hide_in_combat"] = true,
        ["player_arrow_size"] = 50,
        ["scale"] = 0.7300000190734863,
        ["settings_button_angle"] = 180.9546427077609,
        ["show_on_hover"] = true,
        ["style"] = "forever",
      },
      ["modules"] = {
        ["altmoney"] = {
          ["enabled"] = false,
          ["show_all_realms"] = false,
        },
        ["bagster"] = {
          ["db"] = {
            ["bank"] = {
              ["bags"] = {
                [1] = -1,
                [2] = 5,
                [3] = 6,
                [4] = 7,
                [5] = 8,
                [6] = 9,
                [7] = 10,
                [8] = 11,
              },
              ["exclude"] = {},
              ["h"] = 512,
              ["hiddenBags"] = {},
              ["position"] = {
                [1] = "CENTER",
                [3] = "CENTER",
                [4] = 3.137759186782716,
                [5] = -8.627481371145002,
              },
              ["sets"] = {
                [1] = "All",
                [2] = "Equipment",
                [3] = "Usable",
                [4] = "Quest",
                [5] = "Trade Goods",
                [6] = "Miscellaneous",
              },
              ["showBags"] = true,
              ["w"] = 512,
            },
            ["guild"] = {
              ["h"] = 512,
              ["position"] = {
                [1] = "LEFT",
                [3] = "LEFT",
                [4] = 24,
                [5] = 0,
              },
              ["w"] = 512,
            },
            ["inventory"] = {
              ["bags"] = {
                [1] = 0,
                [2] = 1,
                [3] = 2,
                [4] = 3,
                [5] = 4,
                [6] = -2,
              },
              ["exclude"] = {},
              ["h"] = 983.0000445200928,
              ["hiddenBags"] = {},
              ["leftSideFilter"] = true,
              ["position"] = {
                [1] = "RIGHT",
                [3] = "RIGHT",
                [4] = -17.92167486367517,
                [5] = -13.59799614446421,
              },
              ["sets"] = {
                [1] = "All",
                [2] = "Equipment",
                [3] = "Usable",
                [4] = "Quest",
                [5] = "Miscellaneous",
                [6] = "Trade Goods",
              },
              ["showBags"] = true,
              ["w"] = 567.9999972645104,
            },
          },
          ["enabled"] = true,
          ["item_spacing"] = 3,
        },
        ["characterpanel"] = {
          ["dark_background"] = true,
          ["grey_model_backdrop"] = false,
          ["stats_collapsed"] = {},
          ["stats_order"] = {
            [1] = "itemlevel",
            [2] = "gearscore",
            [3] = "PLAYERSTAT_BASE_STATS",
            [4] = "PLAYERSTAT_MELEE_COMBAT",
            [5] = "PLAYERSTAT_SPELL_COMBAT",
            [6] = "PLAYERSTAT_DEFENSES",
            [7] = "resistance",
            [8] = "PLAYERSTAT_RANGED_COMBAT",
          },
        },
        ["chatmods"] = {
          ["chatStyle"] = "dragon",
        },
        ["extrabar1"] = {
          ["enabled"] = true,
        },
        ["hp_low_alert"] = {
          ["flashEnabled"] = false,
        },
        ["itemlevel"] = {
          ["auction"] = false,
          ["bags"] = false,
          ["bank"] = false,
          ["character"] = false,
          ["guildbank"] = false,
          ["inspect"] = false,
          ["loot"] = false,
          ["lootroll"] = false,
          ["mail"] = false,
          ["merchant"] = false,
          ["show_average"] = false,
          ["tooltip_cvar"] = true,
          ["trade"] = false,
        },
        ["keypress"] = {
          ["enabled"] = true,
        },
        ["loot_skin"] = {
          ["positionX"] = 128,
          ["positionY"] = 2,
        },
        ["nameplates"] = {
          ["barHeight"] = 4,
          ["barWidth"] = 118,
          ["centerNameOnly"] = true,
          ["debuffIconSize"] = 10,
          ["fontSize"] = 1,
          ["friendlyNPCNameOnly"] = true,
          ["friendlyNPCNameOnlyTitle"] = true,
          ["friendlyNameOnly"] = true,
          ["healthTextFormat"] = "none",
          ["nameplateAlphaCompat"] = true,
          ["opacityFullNoTarget"] = false,
          ["opacityNonTarget"] = 0,
          ["retailStackingEnabled"] = true,
          ["showCastBarSpellName"] = true,
          ["showDebuffs"] = false,
          ["showLevelAlways"] = false,
        },
        ["ne_AuctionHouse"] = {
          ["enabled"] = true,
        },
        ["ne_EncounterJournal"] = {
          ["enabled"] = false,
        },
        ["ne_Guild"] = {
          ["enabled"] = true,
        },
        ["ne_LFG"] = {
          ["enabled"] = true,
        },
        ["ne_Professions"] = {
          ["enabled"] = true,
        },
        ["ne_Social"] = {
          ["enabled"] = true,
        },
        ["spellbook"] = {
          ["forceWide"] = true,
        },
        ["tooltip"] = {
          ["anchor_cursor"] = true,
        },
        ["unitframe_layers"] = {
          ["enabled"] = true,
        },
        ["worldmap"] = {
          ["maximized"] = true,
          ["position"] = {
            ["x"] = 300.3921551356321,
            ["y"] = -138.5097159460782,
          },
        },
      },
      ["newera"] = {
        ["cooldownviewer"] = {
          ["customLists"] = {},
          ["customListsV2"] = true,
          ["frames"] = {},
          ["specLayouts"] = {
            ["spec1"] = {
              ["customLists"] = {
                ["essential"] = {},
                ["utility"] = {},
              },
              ["trackedAura"] = {
                ["PALADIN"] = {},
              },
            },
          },
        },
        ["enabled"] = true,
        ["modules"] = {
          ["AuctionHouse"] = {
            ["enabled"] = false,
          },
          ["EncounterJournal"] = {
            ["enabled"] = true,
          },
          ["Guild"] = {
            ["enabled"] = true,
          },
          ["LFG"] = {
            ["enabled"] = false,
          },
          ["MerchantFrame"] = {
            ["enabled"] = false,
          },
          ["Professions"] = {
            ["enabled"] = false,
          },
          ["Social"] = {
            ["enabled"] = false,
          },
        },
      },
      ["personalresource"] = {
        ["bar_width"] = 80,
        ["health_height"] = 10,
        ["opacity"] = 71,
        ["power_height"] = 10,
        ["visibility"] = "combat",
      },
      ["questtracker"] = {
        ["custom_height"] = true,
        ["height"] = 580,
        ["show_on_hover"] = true,
        ["x"] = -5,
        ["y"] = -4,
      },
      ["style"] = {
        ["gryphons"] = "forever",
      },
      ["unitframe"] = {
        ["boss"] = {
          ["hide_in_combat"] = false,
          ["override"] = true,
          ["show_in_combat"] = true,
          ["show_on_hover"] = true,
          ["visibility_logic"] = "or",
        },
        ["dragon_style"] = "forever",
        ["focus"] = {
          ["show_in_combat"] = true,
          ["show_on_hover"] = true,
          ["visibility_logic"] = "or",
        },
        ["frame_style"] = "forever",
        ["level_style"] = "dragonui",
        ["party"] = {
          ["show_in_combat"] = true,
          ["show_on_hover"] = true,
          ["visibility_logic"] = "or",
        },
        ["pet"] = {
          ["override"] = true,
        },
        ["player"] = {
          ["alternativeClassIcons"] = true,
          ["hide_in_combat"] = false,
          ["manabar_texture"] = "aluminium",
          ["pvp_icon_style"] = "forever",
          ["scale"] = 1.110000014305115,
          ["showHealthTextAlways"] = true,
          ["showManaTextAlways"] = true,
          ["show_in_combat"] = true,
          ["show_on_hover"] = true,
          ["show_pvp_icon"] = false,
          ["show_with_target"] = true,
          ["visibility_fade_out_delay"] = 1,
          ["visibility_fade_out_duration"] = 1,
          ["visibility_logic"] = "or",
        },
        ["target"] = {
          ["alternativeClassIcons"] = true,
          ["scale"] = 1.559999942779541,
          ["showHealthTextAlways"] = true,
          ["showManaTextAlways"] = true,
          ["show_name_background"] = false,
        },
      },
      ["version"] = 3,
      ["widgets"] = {
        ["bagsbar"] = {
          ["posX"] = -6.001307974341929,
          ["posY"] = -2.68706594191694,
        },
        ["boss"] = {
          ["anchor"] = "LEFT",
          ["posX"] = 136.9987015314844,
          ["posY"] = 189.2742925322981,
        },
        ["bottombarleft"] = {
          ["posX"] = 7.002853320792026e-05,
          ["posY"] = 65.67999668458663,
        },
        ["bottombarright"] = {
          ["posY"] = 102.0000075225963,
        },
        ["buffs"] = {
          ["anchor"] = "CENTER",
          ["custom_position"] = true,
          ["posX"] = -822.9599159821731,
          ["posY"] = 457.7059328187011,
        },
        ["combopoints"] = {
          ["anchor"] = "CENTER",
          ["posX"] = 0,
          ["posY"] = 0,
        },
        ["debuffs"] = {
          ["anchor"] = "TOPLEFT",
          ["custom_position"] = true,
          ["posX"] = 273.1182473499432,
          ["posY"] = -36.45088226719565,
        },
        ["durability"] = {
          ["anchor"] = "CENTER",
          ["posX"] = 897.9713994990361,
          ["posY"] = -506.1017767620297,
        },
        ["errorMessages"] = {
          ["custom_position"] = true,
          ["posX"] = -3,
          ["posY"] = 205,
        },
        ["extrabar1"] = {
          ["anchor"] = "BOTTOMLEFT",
          ["posX"] = 289.7156399770192,
          ["posY"] = 51.5842255531519,
        },
        ["focus"] = {
          ["posX"] = 424.9021518797156,
          ["posY"] = 1.176410697104642,
        },
        ["fot"] = {
          ["posY"] = 0,
        },
        ["leftbar"] = {
          ["anchor"] = "CENTER",
          ["posX"] = 942.7214529607605,
          ["posY"] = -29.99979470150714,
        },
        ["levelup"] = {
          ["anchor"] = "CENTER",
          ["posX"] = -7.002853320792026e-05,
          ["posY"] = 322.7058368714041,
        },
        ["levelupenhance"] = {
          ["posX"] = 1.568570483068995,
          ["posY"] = -205.8823119892884,
        },
        ["lfgframe"] = {
          ["anchor"] = "LEFT",
          ["posX"] = 1.31372051133686,
          ["posY"] = -205.8541255046722,
        },
        ["mainbar"] = {
          ["posY"] = 22.00000109419583,
        },
        ["micromenu"] = {
          ["anchor"] = "BOTTOMLEFT",
          ["posX"] = -0.7917066931480294,
          ["posY"] = -1.70691964656654,
        },
        ["minimap"] = {
          ["anchor"] = "BOTTOMRIGHT",
          ["posX"] = 20.00001340389893,
          ["posY"] = 68.21512245658454,
        },
        ["neCooldownViewerBuffBar-ACAS_AUTHOR_CHARACTER-ACAS_AUTHOR_REALM"] = {
          ["anchor"] = "BOTTOM",
          ["posX"] = 420.0000144980947,
          ["posY"] = 429.9999489831193,
        },
        ["neCooldownViewerBuffIcon-ACAS_AUTHOR_CHARACTER-ACAS_AUTHOR_REALM"] = {
          ["anchor"] = "BOTTOM",
          ["posX"] = 0,
          ["posY"] = 370.0000269445724,
        },
        ["neCooldownViewerEssential-ACAS_AUTHOR_CHARACTER-ACAS_AUTHOR_REALM"] = {
          ["anchor"] = "BOTTOM",
          ["posX"] = 0,
          ["posY"] = 309.9999998632255,
        },
        ["neCooldownViewerUtility-ACAS_AUTHOR_CHARACTER-ACAS_AUTHOR_REALM"] = {
          ["anchor"] = "BOTTOM",
          ["posX"] = 0,
          ["posY"] = 240.0000032825875,
        },
        ["party"] = {
          ["anchor"] = "LEFT",
          ["posX"] = 6.078428537830898,
          ["posY"] = 189.1176562106453,
        },
        ["personalresource"] = {
          ["posX"] = -377.2552630990457,
          ["posY"] = -3.627924178520512,
        },
        ["pet"] = {
          ["anchor"] = "CENTER",
          ["posX"] = -953.0000309794194,
          ["posY"] = -19.00000157290651,
        },
        ["petbar"] = {
          ["anchor"] = "BOTTOMLEFT",
          ["posX"] = 335.8624475478422,
          ["posY"] = 15.1562305801611,
        },
        ["player"] = {
          ["posX"] = 10.00000013677448,
          ["posY"] = -9.000000341936197,
        },
        ["playerCastbar"] = {
          ["anchor"] = "CENTER",
          ["posX"] = 0.7843195719287068,
          ["posY"] = -394.1963207528395,
        },
        ["positionPresetPanel"] = {
          ["anchor"] = "TOPLEFT",
          ["custom_position"] = true,
          ["posX"] = 1348,
          ["posY"] = 1014,
          ["relativePoint"] = "BOTTOMLEFT",
        },
        ["repbar"] = {
          ["posY"] = 6.999999658063802,
        },
        ["rightbar"] = {
          ["anchor"] = "CENTER",
          ["posX"] = 982.721541043525,
          ["posY"] = -29.9997027890573,
        },
        ["target"] = {
          ["anchor"] = "CENTER",
          ["posX"] = 38.96113601052507,
          ["posY"] = 497.0095521244462,
        },
        ["targetCastbar"] = {
          ["posX"] = -1,
          ["posY"] = 374.0000217471422,
        },
        ["tooltip"] = {
          ["anchor"] = "BOTTOM",
          ["posX"] = 406.0340840633728,
          ["posY"] = 24.70608839967089,
        },
        ["vehicleExit"] = {
          ["posX"] = -272.1763985925633,
          ["posY"] = 94.01943332828863,
        },
        ["xpbar"] = {
          ["posY"] = 6.999999658063802,
        },
      },
      ["xprepbar"] = {
        ["show_in_combat"] = true,
        ["show_on_hover"] = true,
        ["show_xp_percent"] = true,
        ["visibility_logic"] = "or",
      },
    },
    ["MAIN UI"] = {
      ["actionbars"] = {
        ["bag_show_in_combat"] = true,
        ["bag_show_on_hover"] = true,
        ["bag_visibility_fade_out_delay"] = 1,
        ["bag_visibility_fade_out_duration"] = 0.199999988079071,
        ["bag_visibility_logic"] = "or",
        ["bottom_left_show_in_combat"] = true,
        ["bottom_left_show_on_hover"] = true,
        ["bottom_left_show_with_target"] = true,
        ["bottom_left_visibility_logic"] = "or",
        ["bottom_right_show_in_combat"] = true,
        ["bottom_right_show_on_hover"] = true,
        ["bottom_right_show_with_target"] = true,
        ["bottom_right_visibility_logic"] = "or",
        ["left_show_in_combat"] = true,
        ["left_show_on_hover"] = true,
        ["left_show_with_target"] = true,
        ["left_visibility_logic"] = "or",
        ["main_show_in_combat"] = true,
        ["main_show_on_hover"] = true,
        ["main_show_with_target"] = true,
        ["main_visibility_logic"] = "or",
        ["micro_show_on_hover"] = true,
        ["micro_visibility_fade_out_delay"] = 1,
        ["right_show_in_combat"] = true,
        ["right_show_on_hover"] = true,
        ["right_show_with_target"] = true,
        ["right_visibility_logic"] = "or",
        ["visibility_fade_out_delay"] = 1,
        ["visibility_fade_out_duration"] = 1,
      },
      ["additional"] = {
        ["extrabar1"] = {
          ["show_in_combat"] = true,
          ["show_on_hover"] = true,
          ["show_with_target"] = false,
          ["spacing_visual_v2"] = true,
          ["visibility_logic"] = "or",
        },
        ["stance"] = {
          ["anchor"] = "BOTTOMLEFT",
          ["button_size"] = 21,
          ["hide_in_combat"] = false,
          ["manual_position"] = true,
          ["posX"] = 0,
          ["posY"] = 0,
          ["show_in_combat"] = true,
          ["show_on_hover"] = true,
          ["visibility_logic"] = "or",
          ["x_position"] = 353,
          ["y_offset"] = -194,
        },
        ["totem"] = {
          ["anchor"] = "CENTER",
          ["posX"] = 0,
          ["posY"] = 0,
        },
      },
      ["bags"] = {
        ["scale"] = 0.7900000214576721,
      },
      ["buffs"] = {
        ["buff_scale"] = 0.7,
        ["buffs_per_row"] = 8,
        ["debuff_scale"] = 0.7,
        ["debuffs_per_row"] = 4,
        ["show_in_combat"] = true,
        ["show_on_hover"] = true,
        ["show_with_target"] = true,
        ["visibility_fade_out_delay"] = 1,
        ["visibility_fade_out_duration"] = 1,
      },
      ["castbar"] = {
        ["scale"] = 1.5,
        ["target"] = {
          ["override"] = true,
          ["scale"] = 2,
        },
      },
      ["mainbars"] = {
        ["scale_bottomleft"] = 0.699999988079071,
        ["scale_bottomright"] = 0.699999988079071,
        ["spacing_migrated"] = true,
      },
      ["micromenu"] = {
        ["grayscale"] = {
          ["icon_spacing"] = 1,
        },
        ["normal"] = {
          ["icon_spacing"] = -6,
        },
        ["spacing_is_padding"] = true,
      },
      ["minimap"] = {
        ["addon_button_fade"] = true,
        ["blip_skin"] = false,
        ["border_alpha"] = 0,
        ["clock_font_size"] = 11,
        ["collector_style"] = "classic",
        ["hide_in_combat"] = true,
        ["player_arrow_size"] = 50,
        ["scale"] = 0.7300000190734863,
        ["settings_button_angle"] = 180.9546427077609,
        ["show_on_hover"] = true,
        ["style"] = "forever",
      },
      ["modules"] = {
        ["altmoney"] = {
          ["enabled"] = false,
          ["show_all_realms"] = false,
        },
        ["bagster"] = {
          ["db"] = {
            ["bank"] = {
              ["bags"] = {
                [1] = -1,
                [2] = 5,
                [3] = 6,
                [4] = 7,
                [5] = 8,
                [6] = 9,
                [7] = 10,
                [8] = 11,
              },
              ["exclude"] = {},
              ["h"] = 512,
              ["hiddenBags"] = {},
              ["position"] = {
                [1] = "CENTER",
                [3] = "CENTER",
                [4] = 3.137759186782716,
                [5] = -8.627481371145002,
              },
              ["sets"] = {
                [1] = "All",
                [2] = "Equipment",
                [3] = "Usable",
                [4] = "Quest",
                [5] = "Trade Goods",
                [6] = "Miscellaneous",
              },
              ["showBags"] = true,
              ["w"] = 512,
            },
            ["guild"] = {
              ["h"] = 512,
              ["position"] = {
                [1] = "LEFT",
                [3] = "LEFT",
                [4] = 24,
                [5] = 0,
              },
              ["w"] = 512,
            },
            ["inventory"] = {
              ["bags"] = {
                [1] = 0,
                [2] = 1,
                [3] = 2,
                [4] = 3,
                [5] = 4,
                [6] = -2,
              },
              ["exclude"] = {},
              ["h"] = 983.0000445200928,
              ["hiddenBags"] = {},
              ["leftSideFilter"] = true,
              ["position"] = {
                [1] = "RIGHT",
                [3] = "RIGHT",
                [4] = -17.92167486367517,
                [5] = -13.59799614446421,
              },
              ["sets"] = {
                [1] = "All",
                [2] = "Equipment",
                [3] = "Usable",
                [4] = "Quest",
                [5] = "Miscellaneous",
                [6] = "Trade Goods",
              },
              ["showBags"] = true,
              ["w"] = 567.9999972645104,
            },
          },
          ["enabled"] = true,
          ["item_spacing"] = 3,
        },
        ["characterpanel"] = {
          ["dark_background"] = true,
          ["grey_model_backdrop"] = false,
          ["stats_collapsed"] = {},
          ["stats_order"] = {
            [1] = "itemlevel",
            [2] = "gearscore",
            [3] = "PLAYERSTAT_BASE_STATS",
            [4] = "PLAYERSTAT_MELEE_COMBAT",
            [5] = "PLAYERSTAT_SPELL_COMBAT",
            [6] = "PLAYERSTAT_DEFENSES",
            [7] = "resistance",
            [8] = "PLAYERSTAT_RANGED_COMBAT",
          },
        },
        ["chatmods"] = {
          ["chatStyle"] = "dragon",
        },
        ["extrabar1"] = {
          ["enabled"] = true,
        },
        ["hp_low_alert"] = {
          ["flashEnabled"] = false,
        },
        ["itemlevel"] = {
          ["auction"] = false,
          ["bags"] = false,
          ["bank"] = false,
          ["character"] = false,
          ["guildbank"] = false,
          ["inspect"] = false,
          ["loot"] = false,
          ["lootroll"] = false,
          ["mail"] = false,
          ["merchant"] = false,
          ["show_average"] = false,
          ["tooltip_cvar"] = true,
          ["trade"] = false,
        },
        ["keypress"] = {
          ["enabled"] = true,
        },
        ["loot_skin"] = {
          ["positionX"] = 128,
          ["positionY"] = 2,
        },
        ["nameplates"] = {
          ["barHeight"] = 4,
          ["barWidth"] = 118,
          ["centerNameOnly"] = true,
          ["debuffIconSize"] = 10,
          ["fontSize"] = 1,
          ["friendlyNPCNameOnly"] = true,
          ["friendlyNPCNameOnlyTitle"] = true,
          ["friendlyNameOnly"] = true,
          ["healthTextFormat"] = "none",
          ["nameplateAlphaCompat"] = true,
          ["opacityFullNoTarget"] = false,
          ["opacityNonTarget"] = 0,
          ["retailStackingEnabled"] = true,
          ["showCastBarSpellName"] = true,
          ["showDebuffs"] = false,
          ["showLevelAlways"] = false,
        },
        ["ne_AuctionHouse"] = {
          ["enabled"] = true,
        },
        ["ne_EncounterJournal"] = {
          ["enabled"] = false,
        },
        ["ne_Guild"] = {
          ["enabled"] = true,
        },
        ["ne_LFG"] = {
          ["enabled"] = true,
        },
        ["ne_Professions"] = {
          ["enabled"] = true,
        },
        ["ne_Social"] = {
          ["enabled"] = true,
        },
        ["spellbook"] = {
          ["forceWide"] = true,
        },
        ["tooltip"] = {
          ["anchor_cursor"] = true,
        },
        ["unitframe_layers"] = {
          ["enabled"] = true,
        },
        ["worldmap"] = {
          ["maximized"] = true,
          ["position"] = {
            ["x"] = 300.3921551356321,
            ["y"] = -138.5097159460782,
          },
        },
      },
      ["newera"] = {
        ["cooldownviewer"] = {
          ["customLists"] = {},
          ["customListsV2"] = true,
          ["frames"] = {},
          ["specLayouts"] = {
            ["spec1"] = {
              ["customLists"] = {
                ["essential"] = {},
                ["utility"] = {},
              },
              ["trackedAura"] = {
                ["PALADIN"] = {},
              },
            },
          },
        },
        ["enabled"] = true,
        ["modules"] = {
          ["AuctionHouse"] = {
            ["enabled"] = false,
          },
          ["EncounterJournal"] = {
            ["enabled"] = true,
          },
          ["Guild"] = {
            ["enabled"] = true,
          },
          ["LFG"] = {
            ["enabled"] = false,
          },
          ["MerchantFrame"] = {
            ["enabled"] = false,
          },
          ["Professions"] = {
            ["enabled"] = false,
          },
          ["Social"] = {
            ["enabled"] = false,
          },
        },
      },
      ["personalresource"] = {
        ["bar_width"] = 80,
        ["health_height"] = 10,
        ["opacity"] = 71,
        ["power_height"] = 10,
        ["visibility"] = "combat",
      },
      ["questtracker"] = {
        ["custom_height"] = true,
        ["height"] = 580,
        ["show_on_hover"] = true,
        ["x"] = -5,
        ["y"] = -4,
      },
      ["style"] = {
        ["gryphons"] = "forever",
      },
      ["unitframe"] = {
        ["boss"] = {
          ["hide_in_combat"] = false,
          ["override"] = true,
          ["show_in_combat"] = true,
          ["show_on_hover"] = true,
          ["visibility_logic"] = "or",
        },
        ["dragon_style"] = "forever",
        ["focus"] = {
          ["show_in_combat"] = true,
          ["show_on_hover"] = true,
          ["visibility_logic"] = "or",
        },
        ["frame_style"] = "forever",
        ["level_style"] = "dragonui",
        ["party"] = {
          ["show_in_combat"] = true,
          ["show_on_hover"] = true,
          ["visibility_logic"] = "or",
        },
        ["pet"] = {
          ["override"] = true,
        },
        ["player"] = {
          ["alternativeClassIcons"] = true,
          ["hide_in_combat"] = false,
          ["manabar_texture"] = "aluminium",
          ["pvp_icon_style"] = "forever",
          ["scale"] = 1.110000014305115,
          ["showHealthTextAlways"] = true,
          ["showManaTextAlways"] = true,
          ["show_in_combat"] = true,
          ["show_on_hover"] = true,
          ["show_pvp_icon"] = false,
          ["show_with_target"] = true,
          ["visibility_fade_out_delay"] = 1,
          ["visibility_fade_out_duration"] = 1,
          ["visibility_logic"] = "or",
        },
        ["target"] = {
          ["alternativeClassIcons"] = true,
          ["scale"] = 1.559999942779541,
          ["showHealthTextAlways"] = true,
          ["showManaTextAlways"] = true,
          ["show_name_background"] = false,
        },
      },
      ["version"] = 3,
      ["widgets"] = {
        ["bagsbar"] = {
          ["posX"] = -6.001307974341929,
          ["posY"] = -2.68706594191694,
        },
        ["boss"] = {
          ["anchor"] = "LEFT",
          ["posX"] = 136.9987015314844,
          ["posY"] = 189.2742925322981,
        },
        ["bottombarleft"] = {
          ["posX"] = 7.002853320792026e-05,
          ["posY"] = 65.67999668458663,
        },
        ["bottombarright"] = {
          ["posY"] = 102.0000075225963,
        },
        ["buffs"] = {
          ["anchor"] = "CENTER",
          ["custom_position"] = true,
          ["posX"] = -822.9599159821731,
          ["posY"] = 457.7059328187011,
        },
        ["combopoints"] = {
          ["anchor"] = "CENTER",
          ["posX"] = 0,
          ["posY"] = 0,
        },
        ["debuffs"] = {
          ["anchor"] = "TOPLEFT",
          ["custom_position"] = true,
          ["posX"] = 273.1182473499432,
          ["posY"] = -36.45088226719565,
        },
        ["durability"] = {
          ["anchor"] = "CENTER",
          ["posX"] = 897.9713994990361,
          ["posY"] = -506.1017767620297,
        },
        ["errorMessages"] = {
          ["custom_position"] = true,
          ["posX"] = -3,
          ["posY"] = 205,
        },
        ["extrabar1"] = {
          ["anchor"] = "BOTTOMLEFT",
          ["posX"] = 289.7156399770192,
          ["posY"] = 51.5842255531519,
        },
        ["focus"] = {
          ["posX"] = 424.9021518797156,
          ["posY"] = 1.176410697104642,
        },
        ["fot"] = {
          ["posY"] = 0,
        },
        ["leftbar"] = {
          ["anchor"] = "CENTER",
          ["posX"] = 942.7214529607605,
          ["posY"] = -29.99979470150714,
        },
        ["levelup"] = {
          ["anchor"] = "CENTER",
          ["posX"] = -7.002853320792026e-05,
          ["posY"] = 322.7058368714041,
        },
        ["levelupenhance"] = {
          ["posX"] = 1.568570483068995,
          ["posY"] = -205.8823119892884,
        },
        ["lfgframe"] = {
          ["anchor"] = "LEFT",
          ["posX"] = 1.31372051133686,
          ["posY"] = -205.8541255046722,
        },
        ["mainbar"] = {
          ["posY"] = 22.00000109419583,
        },
        ["micromenu"] = {
          ["anchor"] = "BOTTOMLEFT",
          ["posX"] = -0.7917066931480294,
          ["posY"] = -1.70691964656654,
        },
        ["minimap"] = {
          ["anchor"] = "BOTTOMRIGHT",
          ["posX"] = 20.00001340389893,
          ["posY"] = 68.21512245658454,
        },
        ["neCooldownViewerBuffBar-ACAS_AUTHOR_CHARACTER-ACAS_AUTHOR_REALM"] = {
          ["anchor"] = "BOTTOM",
          ["posX"] = 420.0000144980947,
          ["posY"] = 429.9999489831193,
        },
        ["neCooldownViewerBuffIcon-ACAS_AUTHOR_CHARACTER-ACAS_AUTHOR_REALM"] = {
          ["anchor"] = "BOTTOM",
          ["posX"] = 0,
          ["posY"] = 370.0000269445724,
        },
        ["neCooldownViewerEssential-ACAS_AUTHOR_CHARACTER-ACAS_AUTHOR_REALM"] = {
          ["anchor"] = "BOTTOM",
          ["posX"] = 0,
          ["posY"] = 309.9999998632255,
        },
        ["neCooldownViewerUtility-ACAS_AUTHOR_CHARACTER-ACAS_AUTHOR_REALM"] = {
          ["anchor"] = "BOTTOM",
          ["posX"] = 0,
          ["posY"] = 240.0000032825875,
        },
        ["party"] = {
          ["anchor"] = "LEFT",
          ["posX"] = 6.078428537830898,
          ["posY"] = 189.1176562106453,
        },
        ["personalresource"] = {
          ["posX"] = -377.2552630990457,
          ["posY"] = -3.627924178520512,
        },
        ["pet"] = {
          ["anchor"] = "CENTER",
          ["posX"] = -953.0000309794194,
          ["posY"] = -19.00000157290651,
        },
        ["petbar"] = {
          ["anchor"] = "BOTTOMLEFT",
          ["posX"] = 335.8624475478422,
          ["posY"] = 15.1562305801611,
        },
        ["player"] = {
          ["posX"] = 10.00000013677448,
          ["posY"] = -9.000000341936197,
        },
        ["playerCastbar"] = {
          ["anchor"] = "CENTER",
          ["posX"] = 0.7843195719287068,
          ["posY"] = -394.1963207528395,
        },
        ["positionPresetPanel"] = {
          ["anchor"] = "TOPLEFT",
          ["custom_position"] = true,
          ["posX"] = 1348,
          ["posY"] = 1014,
          ["relativePoint"] = "BOTTOMLEFT",
        },
        ["repbar"] = {
          ["posY"] = 6.999999658063802,
        },
        ["rightbar"] = {
          ["anchor"] = "CENTER",
          ["posX"] = 982.721541043525,
          ["posY"] = -29.9997027890573,
        },
        ["target"] = {
          ["anchor"] = "CENTER",
          ["posX"] = 38.96113601052507,
          ["posY"] = 497.0095521244462,
        },
        ["targetCastbar"] = {
          ["posX"] = -1,
          ["posY"] = 374.0000217471422,
        },
        ["tooltip"] = {
          ["anchor"] = "BOTTOM",
          ["posX"] = 406.0340840633728,
          ["posY"] = 24.70608839967089,
        },
        ["vehicleExit"] = {
          ["posX"] = -272.1763985925633,
          ["posY"] = 94.01943332828863,
        },
        ["xpbar"] = {
          ["posY"] = 6.999999658063802,
        },
      },
      ["xprepbar"] = {
        ["show_in_combat"] = true,
        ["show_on_hover"] = true,
        ["show_xp_percent"] = true,
        ["visibility_logic"] = "or",
      },
    },
  },
}
end

-- Camera Suite authored DragonUI default: this is normal addon-internal
-- configuration. There is NO separate profile importer/addon dependency.
local function ResolveCameraSuiteWidgetOwners()
  local db = _G.DragonUIDB
  if type(db) ~= "table" or type(db.profiles) ~= "table" then return false end
  if type(UnitName) ~= "function" or type(GetRealmName) ~= "function" then return false end
  local player, realm = UnitName("player"), GetRealmName()
  if type(player) ~= "string" or player == "" or
     type(realm) ~= "string" or realm == "" then return false end
  local suffix = "-ACAS_AUTHOR_CHARACTER-ACAS_AUTHOR_REALM"
  for _, profile in pairs(db.profiles) do
    if type(profile) == "table" and type(profile.widgets) == "table" then
      local widgets = profile.widgets
      local changed = {}
      for key, value in pairs(widgets) do
        if type(key) == "string" and key:sub(-#suffix) == suffix then
          local target = key:sub(1, -#suffix-1) .. "-" .. player .. "-" .. realm
          if widgets[target] == nil then changed[target] = value end
          changed[key] = false
        end
      end
      for key, value in pairs(changed) do
        if value == false then widgets[key] = nil else widgets[key] = value end
      end
    end
  end
  return true
end
if cameraSuiteCreatedDefault then
  if not ResolveCameraSuiteWidgetOwners() then
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:SetScript("OnEvent", function(self)
      ResolveCameraSuiteWidgetOwners()
      self:UnregisterEvent("PLAYER_LOGIN")
    end)
  end
end
