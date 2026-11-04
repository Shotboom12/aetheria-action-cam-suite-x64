DialogUI 1.0.2 - BOOK ONLY / IMMERSION COMPATIBILITY EDITION (experimental)
===========================================================================
Purpose
- Immersion retains 100% ownership of quest/gossip UI; Immersion files are unchanged.
- DialogUI still renders the book, letter, sign, plaque, and gravestone reader.
- DialogUI book font face, text size, frame scale, and background dimmer
  remain configurable via Interface > AddOns > DialogUI.
- Book's default dimming and its smooth open/close effect remain enabled.
- Reader page controls, scroll, ESC, and temporary SPACE binding are retained.

Installation
1. Exit WoW completely.
2. BACK UP your existing Interface/AddOns/DialogUI directory. Keep its original ZIP.
3. Replace the entire DialogUI directory (do NOT merge old and new source files).
4. Leave Interface/AddOns/Immersion untouched.
5. In Immersion settings, keep book reading DISABLED (as already configured).
6. Restart WoW, confirm both addons are enabled, test quests, gossip and a book.

Changes/compatibility
- TOC no longer loads DialogUI's quest, gossip, money frame, dialog focus,
  quest/gossip bindings, or quest/gossip compatibility code.
- Original quest/gossip source files are present but intentionally inert.
- Root Bindings.xml is empty; it is auto-read by WoW even if not listed in TOC.
  Important: the special SPACE/ESC actions for quests/gossip are removed.
  The book-only per-frame SPACE override still operates while a book is visible.
- Original DialogUISettings SavedVariables remain in place. Quest-only values
  such as dimMode, framePosition and disableAnim are preserved but inactive.
- New independent bookDimEnabled defaults TRUE so existing readers still darken
  the background even if the old quest/gossip dimMode option was false.
- The addon no longer modifies the global QUEST_FADING_DISABLE setting.
- This is NOT a new addon; folder name remains exactly DialogUI.

Rollback
1. Exit WoW.
2. Replace this DialogUI folder with your unmodified original DialogUI.zip.
3. Do not delete DialogUISettings in WTF/Account; originals can read legacy keys.
4. Immersion should still have book reading disabled; change it only intentionally.

Validation level
- Offline/source-based compatibility and packaging checks only.
- User in-game acceptance not yet performed.
- Test quest accept/complete, gossip options, book/letter/sign pages, ESC,
  Space next-page, font sliders, frame scale, dimmer toggle, reload and relog.
