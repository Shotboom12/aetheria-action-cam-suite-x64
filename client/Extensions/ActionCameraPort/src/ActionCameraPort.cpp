#include "Extensions/WxlHost/src/WxlHost.hpp"

#include "Engine/Source/ConsoleBase/ConsoleVar.h"
#include "Engine/Source/FrameScript/FrameScript.h"
#include "Engine/Source/Os/TimeManager.h"
#include "Engine/Source/lua-5.1/src/lua.h"
#include "WoW/Source/DB/DBClient/DBClient.h"
#include "WoW/Source/DB/Rec/ItemRec.h"
#include "WoW/Source/Extension/ExtensionMgr.h"
#include "WoW/Source/UIUtil/ActionCameraSettings.h"
#include "WoW/Source/UIUtil/Camera.h"
#include "WoW/Source/Ui/WorldFrame.h"

#include <cstdio>
#include <cstring>

namespace ActionCamera {
    void RegisterWaistLantern();
    void UpdateWaistLantern();
    void DrawWaistLantern(const WXL_Api* api);
    void UpdateHunterQuiver();
    void DrawHunterQuiver(const WXL_Api* api);
    const char* LocalFootIKRig();
    const char* ProbeLocalFootGround();
    void RegisterFootPlacement();
    void EnableFootPlacement(bool enabled);
    void EnableMovingFootPlacement(bool enabled);
    void EnableFootSlopeAlignment(bool enabled);
    void EnableFootPelvisCompensation(bool enabled);
    void EnableFootprintProbes(bool enabled);
}

namespace
{
    int ReadRangedFeedback(lua_State* state)
    {
        lua_pushnumber(state, ActionCamera::rangedShotSerial);
        const auto* item = lua_isnumber(state, 1) ? g_itemDB.GetRecord(lua_tointeger(state, 1)) : nullptr;
        if (item && item->m_classID == 2)
            lua_pushinteger(state, item->m_subclassID);
        else
            lua_pushnil(state);
        return 2;
    }
    constexpr int kFirstEditableView = 1; // Native camera view A.
    constexpr int kLastEditableView = 5;  // Native camera view E.
    constexpr float kRadiansToDegrees = 57.29577951308232f;
    constexpr const char* kViewNames[] = { "", "A", "B", "C", "D", "E" };

    const WXL_Api* s_api = nullptr;
    int s_selectedView = 2;
    bool s_overlayWasOpen = false;
    constexpr const char* kReticleShapes[] = {
        "simple", "arc", "brackets", "compass", "diamond", "dot", "leaf",
        "nexus", "ring", "runic", "spire", "split", "star"
    };
    constexpr const char* kReticleThemes[] = { "neutral", "bronze" };
    constexpr int kShapeCount = sizeof(kReticleShapes) / sizeof(kReticleShapes[0]);
    constexpr int kThemeCount = sizeof(kReticleThemes) / sizeof(kReticleThemes[0]);
    int s_reticleShape = 8;
    int s_reticleTheme = 0;
    bool s_reticleAvailable = false;
    bool s_reticlePending = false;

    bool ReadReticleChoice(lua_State* state, const char* name, const char* const* choices, int count, int& index)
    {
        lua_getglobal(state, name);
        const char* value = lua_type(state, -1) == LUA_TSTRING ? lua_tostring(state, -1) : nullptr;
        bool found = false;
        for (int i = 0; value && i < count; ++i) {
            if (std::strcmp(value, choices[i]) == 0) {
                index = i;
                found = true;
                break;
            }
        }
        lua_pop(state, 1);
        return found;
    }

    void __cdecl OnUpdate(void*, const void*)
    {
        const bool open = wxlhost::OverlayOpen();
        ActionCamera::UpdateWaistLantern();
        ActionCamera::UpdateHunterQuiver();
        ActionCamera::suppressDialogueVisuals = false;
        if (ActionCamera::cleanDialogueVisuals && CGWorldFrame::GetActiveCamera()) {
            if (auto* state = FrameScript_GetContext()) {
                lua_pushliteral(state, "AetheriaActionCameraDialogueOpen");
                lua_rawget(state, LUA_GLOBALSINDEX);
                ActionCamera::suppressDialogueVisuals = lua_isboolean(state, -1) && lua_toboolean(state, -1);
                lua_pop(state, 1);
            }
        }
        if (open && !s_overlayWasOpen && CGWorldFrame::GetActiveCamera() && FrameScript_GetContext())
            FrameScript_Execute(
                "if AetheriaActionCameraReleaseMouseLook then AetheriaActionCameraReleaseMouseLook() end",
                "AetheriaActionCamera", nullptr);
        s_overlayWasOpen = open;
        auto* state = open && CGWorldFrame::GetActiveCamera() ? FrameScript_GetContext() : nullptr;
        if (state && s_reticlePending) {
            char script[220];
            std::snprintf(script, sizeof(script),
                "if SlashCmdList and SlashCmdList.AETHERIARETICLE then SlashCmdList.AETHERIARETICLE('%s %s') end",
                kReticleShapes[s_reticleShape], kReticleThemes[s_reticleTheme]);
            FrameScript_Execute(script, "AetheriaActionCamera", nullptr);
        }
        s_reticlePending = false;
        s_reticleAvailable = state &&
            ReadReticleChoice(state, "AetheriaActionCameraReticleShape", kReticleShapes, kShapeCount, s_reticleShape) &&
            ReadReticleChoice(state, "AetheriaActionCameraReticleTheme", kReticleThemes, kThemeCount, s_reticleTheme);
    }

    const WXL_PluginInfo s_pluginInfo = {
        sizeof(WXL_PluginInfo),
        WXL_API_VERSION,
        "Aetheria Action Camera Profiles",
        0x00010000,
        WXL_CLIENT_BUILD,
    };

    CVar* ViewSetting(int view, int component)
    {
        if (view < kFirstEditableView || view > kLastEditableView || component < 0 || component >= 3)
            return nullptr;

        return s_cvCameraViewData[view][component];
    }

    bool StoreSetting(CVar* setting, float value)
    {
        if (!setting)
            return false;

        char text[32];
        std::snprintf(text, sizeof(text), "%.3f", static_cast<double>(value));
        return setting->Set(text, true, false, false, true);
    }

    void DrawPanel(void*)
    {
        if (!s_api)
            return;

        ActionCamera::DrawWaistLantern(s_api);
        ActionCamera::DrawHunterQuiver(s_api);
        if (s_api->UiCollapsingHeader("Foot IK rig diagnostics")) {
            static int footPlacement = 0;
            if (s_api->UiCheckbox("Experimental standing foot placement", &footPlacement))
                ActionCamera::EnableFootPlacement(footPlacement != 0);
            static int movingFootPlacement = 0;
            if (footPlacement && s_api->UiCheckbox("Experimental walking and running foot placement", &movingFootPlacement))
                ActionCamera::EnableMovingFootPlacement(movingFootPlacement != 0);
            static int slopeAlignment = 0;
            if (footPlacement && s_api->UiCheckbox("Experimental standing slope alignment", &slopeAlignment))
                ActionCamera::EnableFootSlopeAlignment(slopeAlignment != 0);
            static int pelvisCompensation = 0;
            if (footPlacement && s_api->UiCheckbox("Experimental standing pelvis compensation", &pelvisCompensation))
                ActionCamera::EnableFootPelvisCompensation(pelvisCompensation != 0);
            static int footprintProbes = 0;
            if (footPlacement && s_api->UiCheckbox("Experimental standing sole edge probes", &footprintProbes))
                ActionCamera::EnableFootprintProbes(footprintProbes != 0);
            static const char* probe = "No ground sample yet.";
            static int liveProbe = 0;
            static uint32_t lastProbe = 0;
            s_api->UiText(ActionCamera::LocalFootIKRig());
            s_api->UiCheckbox("Live ground samples", &liveProbe);
            const uint32_t now = OsGetAsyncTimeMs();
            if (s_api->UiButton("Sample ground under feet") || (liveProbe && now - lastProbe >= 100)) {
                probe = ActionCamera::ProbeLocalFootGround();
                lastProbe = now;
            }
            s_api->UiText(probe);
        }

        if (s_reticleAvailable) {
            if (s_api->UiCombo("Reticle shape", &s_reticleShape, kReticleShapes, kShapeCount))
                s_reticlePending = true;
            if (s_api->UiCombo("Reticle color", &s_reticleTheme, kReticleThemes, kThemeCount))
                s_reticlePending = true;
        } else {
            s_api->UiText("Reticle controls require the Aetheria Action Camera addon in game.");
        }
        s_api->UiSeparator();
        int cleanDialogue = ActionCamera::cleanDialogueVisuals ? 1 : 0;
        if (s_api->UiCheckbox("Hide NPC overhead names and selection rings in dialogue", &cleanDialogue))
            ActionCamera::cleanDialogueVisuals = cleanDialogue != 0;
        int preciseHover = ActionCamera::preciseUnitHover ? 1 : 0;
        if (s_api->UiCheckbox("Tighter character hover", &preciseHover))
            ActionCamera::preciseUnitHover = preciseHover != 0;
        if (ActionCamera::preciseUnitHover)
            s_api->UiSliderInt("Character hover width (%)", &ActionCamera::unitHoverWidth, 40, 140);
        int preciseObjectHover = ActionCamera::preciseObjectHover ? 1 : 0;
        if (s_api->UiCheckbox("Tighter world-object hover", &preciseObjectHover))
            ActionCamera::preciseObjectHover = preciseObjectHover != 0;
        if (ActionCamera::preciseObjectHover)
            s_api->UiSliderInt("World-object hover width (%)", &ActionCamera::objectHoverWidth, 30, 140);
        s_api->UiText("Edit the built-in camera views A-E. Changes are saved to this client's camera CVars.");
        int shoulderEnabled = ActionCamera::shoulderEnabled ? 1 : 0;
        if (s_api->UiCheckbox("Shoulder framing (this session)", &shoulderEnabled))
            ActionCamera::shoulderEnabled = shoulderEnabled != 0;
        if (ActionCamera::shoulderEnabled) {
            s_api->UiSliderFloat("Shoulder offset", &ActionCamera::shoulderOffset, -1.5f, 1.5f);
            const auto drawProfile = [](const char* toggle, const char* slider, bool& enabled, float& offset) {
                int value = enabled ? 1 : 0;
                if (s_api->UiCheckbox(toggle, &value))
                    enabled = value != 0;
                if (enabled)
                    s_api->UiSliderFloat(slider, &offset, -1.5f, 1.5f);
            };
            drawProfile("Combat framing", "Combat offset", ActionCamera::combatEnabled, ActionCamera::combatOffset);
            drawProfile("Dialogue framing", "Dialogue offset", ActionCamera::dialogueEnabled, ActionCamera::dialogueOffset);
            drawProfile("Ground mount framing", "Ground mount offset",
                ActionCamera::groundMountEnabled, ActionCamera::groundMountOffset);
            drawProfile("Flying mount framing", "Flying mount offset",
                ActionCamera::flyingMountEnabled, ActionCamera::flyingMountOffset);
            drawProfile("Vehicle framing", "Vehicle offset", ActionCamera::vehicleEnabled, ActionCamera::vehicleOffset);
        }
        s_api->UiSeparator();

        if (s_api->UiSliderInt("Camera view (A-E)", &s_selectedView, kFirstEditableView, kLastEditableView))
            s_selectedView = s_selectedView < kFirstEditableView ? kFirstEditableView : s_selectedView;
        s_api->UiText(kViewNames[s_selectedView]);

        CVar* distance = ViewSetting(s_selectedView, 0);
        CVar* pitch = ViewSetting(s_selectedView, 1);
        CVar* yaw = ViewSetting(s_selectedView, 2);
        if (!distance || !pitch || !yaw)
        {
            s_api->UiText("Camera settings are not initialized yet.");
            return;
        }

        float distanceValue = distance->m_floatValue;
        if (s_api->UiSliderFloat("Distance##ActionCamera", &distanceValue, 0.0f, 50.0f))
            StoreSetting(distance, distanceValue);

        const float pitchMin = MIN_PITCH_ANGLE * kRadiansToDegrees;
        const float pitchMax = MAX_PITCH_ANGLE * kRadiansToDegrees;
        float pitchValue = pitch->m_floatValue;
        if (s_api->UiSliderFloat("Pitch##ActionCamera", &pitchValue, pitchMin, pitchMax))
            StoreSetting(pitch, pitchValue);

        float yawValue = yaw->m_floatValue;
        if (s_api->UiSliderFloat("Yaw##ActionCamera", &yawValue, 0.0f, 360.0f))
            StoreSetting(yaw, yawValue);

        s_api->UiSeparator();
        if (s_api->UiButton("Apply selected view"))
        {
            CGCamera* camera = CGWorldFrame::GetActiveCamera();
            if (camera)
            {
                const int blendStyle = s_cvCameraViewBlendStyle ? s_cvCameraViewBlendStyle->m_intValue : 1;
                camera->InitializeView();
                camera->SetView(s_selectedView, blendStyle, 0);
            }
            else
            {
                s_api->UiText("Enter the world before applying a camera view.");
            }
        }
    }

    const WXL_PluginInfo* __cdecl QueryPlugin()
    {
        return &s_pluginInfo;
    }

    int __cdecl LoadPlugin(const WXL_Api* api)
    {
        if (!api || api->apiVersion != WXL_API_VERSION || api->structSize < sizeof(WXL_Api) || !api->Log ||
            !api->UiAddPanel || !api->UiText || !api->UiSliderFloat || !api->UiSliderInt ||
            !api->UiButton || !api->UiSeparator || !api->UiCheckbox || !api->Subscribe || !api->UiCombo ||
            !api->UiCollapsingHeader)
            return 0;

        s_api = api;
        s_api->Subscribe(static_cast<uint32_t>(wxl::events::Event::OnUpdate), OnUpdate, nullptr);
        s_api->UiAddPanel("Action Camera Profiles", DrawPanel, nullptr);
        s_api->Log(WXL_LOG_INFO, "ActionCameraPort", "Native camera profile controls registered");
        return 1;
    }
}

void AddActionCameraNamePlateCompatibility();

void AddActionCameraPortExtension()
{
    sExtensionMgr->RegisterLuaFunction("AetheriaReadRangedFeedback", ReadRangedFeedback, FRAMESCRIPT_CONTEXTS_GAME);
    ActionCamera::RegisterWaistLantern();
    ActionCamera::RegisterFootPlacement();
    AddActionCameraNamePlateCompatibility();
    wxlhost::RegisterPlugin("aetheria-action-camera-profiles", &QueryPlugin, &LoadPlugin);
}
