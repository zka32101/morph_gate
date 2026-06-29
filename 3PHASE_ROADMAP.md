# Morph Gate - 3 Phase Implementation Roadmap

## Summary

| Phase | Feature | Duration | Status |
|-------|---------|----------|--------|
| **A** | UI/Visual Enhancement | 2-3h | ✅ COMPLETE |
| **B** | Firebase Integration | 4-5h | 📋 READY |
| **C** | Monetization | 4-5h | 📋 READY |

---

## Phase A: UI/Visual Enhancement ✅ DONE

**v1.5 APK** (51.8MB)

### Completed:
- ✅ Leonardo AI 33 images generated
- ✅ Splash screen background integrated
- ✅ Character jelly variants displayed (4 characters)
- ✅ Rank badges (F, S) with Leonardo AI images
- ✅ 28+ reference images in assets

### Assets Folder:
```
assets/images/
├── app_icon/
├── characters/
├── jelly_variants/
├── rank_badges/ (with F, S images)
├── splash/
├── walls/
├── backgrounds/
├── ui/
├── effects/
├── achievements/
└── buttons_ui/
```

**Next**: Phase B Firebase or skip to Phase C Monetization?

---

## Phase B: Firebase Integration 📋 READY

### 3 Firebase Features:

#### 1️⃣ Leaderboard (Firestore)
- Global high score rankings
- Top 10 players display
- Player name + score + rank + jellify level
- Implementation: `leaderboard_service.dart`

#### 2️⃣ Cloud Save (Realtime Database)
- Save game progress to cloud
- High score, jellify level, unlocked characters
- Load on app restart
- Implementation: `cloud_save_service.dart`

#### 3️⃣ Analytics (Firebase Analytics)
- Track game starts, game overs, character selects
- Analyze player behavior
- Monitor retention, DAU, ARPU metrics
- Implementation: `analytics_service.dart`

### Setup Steps:
1. Create Firebase project (30 min)
2. Add Android app, download google-services.json
3. Add Firebase packages to pubspec.yaml
4. Run `flutterfire configure`
5. Implement 3 services
6. Integrate in game code
7. Test & APK build

### Timeline: **3-4 hours**

**Documentation**: See `FIREBASE_SETUP.md`

---

## Phase C: Monetization 📋 READY

### 2 Monetization Systems:

#### 1️⃣ Google Mobile Ads
- Banner ads (game screen bottom)
- Rewarded video ads (bonus lives)
- Interstitial ads (game over)
- Revenue: ~40% from ad impressions

#### 2️⃣ RevenueCat (In-App Purchases)
- Premium Pass (¥499) — remove ads, 2x multiplier
- Character Pack (¥299) — 4 exclusive characters
- Remove Ads (¥99) — ad-free gameplay
- Revenue: ~70% from purchases

### Setup Steps:
1. Create AdMob account, setup ad units (30 min)
2. Create RevenueCat account, add products (30 min)
3. Implement ads service
4. Implement IAP service
5. Gate premium features
6. Test purchase flow
7. APK build & submit

### Timeline: **4 hours**

**Documentation**: See `MONETIZATION_SETUP.md`

---

## How Phases Integrate

```
Phase A (UI)
    ↓
Phase B (Firebase)
    ├→ Leaderboard display on home screen
    ├→ Cloud save on app exit
    └→ Analytics tracking game events
    ↓
Phase C (Monetization)
    ├→ Show ads to free players
    ├→ Offer IAP for premium features
    └→ Track revenue events in analytics
```

---

## Implementation Order (Recommended)

### Option 1: Sequential (Safe)
1. **Phase A** ✅ (Already done)
2. **Phase B** → Firebase (3-4h)
3. **Phase C** → Monetization (4h)
4. **Total**: ~8 hours, Full-featured release

### Option 2: B then C (Faster Revenue)
1. **Phase A** ✅ (Already done)
2. **Phase C** → Monetization (4h) — Start earning immediately
3. **Phase B** → Firebase (3-4h) — Add leaderboards later
4. **Total**: ~8 hours, Revenue-first approach

### Option 3: Just B or Just C (Minimum)
- **Phase B Only**: Leaderboards + analytics (no revenue)
- **Phase C Only**: Ads + IAP (no leaderboards)

---

## Which Should We Do Next?

### Choose Based On:

🎮 **Want Leaderboards First?**
→ Go with **Phase B (Firebase)**
- Players compete on global rankings
- Better engagement metrics
- Then monetize in Phase C

💰 **Want Revenue ASAP?**
→ Go with **Phase C (Monetization)**
- AdMob ads running immediately
- IAP available for early adopters
- Then add leaderboards in Phase B

---

## Pre-Implementation Checklist

Before starting either phase:

- [ ] Verify H:\マイドライブ\apps\morph_gate\FIREBASE_SETUP.md content
- [ ] Verify H:\マイドライブ\apps\morph_gate\MONETIZATION_SETUP.md content
- [ ] Ensure flutter 3.44+ installed
- [ ] Ensure Android SDK 21+ configured
- [ ] Backup current morph_gate project
- [ ] Create git branch for phase (optional)

---

## Q&A

**Q: Can we skip Phase B and C?**
A: Yes, Phase A is complete and fully playable. B+C are optional enhancements.

**Q: Can we do A+B+C together?**
A: Not recommended — too many changes at once. Sequential is cleaner.

**Q: How much does Firebase/RevenueCat cost?**
A: Firebase free tier sufficient for 1000+ DAU. RevenueCat free unless revenue > $10k/month.

**Q: Can we implement Phase B without C?**
A: Yes! Leaderboards + analytics without ads/IAP is fine.

**Q: How do we test Firebase locally?**
A: Use Firebase Emulator Suite or test with actual Firebase project.

**Q: Can we change pricing (¥499 → ¥299)?**
A: Yes, anytime in RevenueCat dashboard. Changes take effect immediately.

---

## Files Available

- `FIREBASE_SETUP.md` — Complete Firebase implementation guide
- `MONETIZATION_SETUP.md` — Complete AdMob + RevenueCat guide
- `3PHASE_ROADMAP.md` — This file (overview & decision help)

---

## Decision Time 🎯

**Which phase next?**

1. **Phase B** (Firebase) → Leaderboards + Analytics
2. **Phase C** (Monetization) → Ads + In-App Purchases
3. **Both together** → Full implementation push
4. **Pause** → Keep Phase A as-is

**Your choice?** 👇
