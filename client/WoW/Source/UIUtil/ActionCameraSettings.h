#pragma once
#include <cstdint>

namespace ActionCamera {
    inline uint32_t rangedShotSerial = 0;
    // Session settings controlled by the Action Camera Profiles panel.
    inline bool shoulderEnabled = false;
    inline float shoulderOffset = 0.75f;
    inline bool combatEnabled = false;
    inline float combatOffset = 1.0f;
    inline bool dialogueEnabled = false;
    inline float dialogueOffset = 0.35f;
    inline bool groundMountEnabled = false;
    inline float groundMountOffset = 0.75f;
    inline bool flyingMountEnabled = false;
    inline float flyingMountOffset = 0.75f;
    inline bool vehicleEnabled = false;
    inline float vehicleOffset = 0.5f;
    inline bool cleanDialogueVisuals = false;
    inline bool suppressDialogueVisuals = false;
    inline bool preciseUnitHover = false;
    inline int unitHoverWidth = 80;
    inline bool preciseObjectHover = false;
    inline int objectHoverWidth = 75;
}
