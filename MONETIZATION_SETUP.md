# Morph Gate - Monetization Setup (Phase C)

## Overview
Implement ads (Google Mobile Ads) and in-app purchases (RevenueCat) for revenue generation.

---

## A. GOOGLE MOBILE ADS (Advertising)

### Step 1: AdMob Setup
1. Go to **[admob.google.com](https://admob.google.com)**
2. Sign in with Google account
3. Click **"Start"**
4. Select **"Yes, I'm a new user"**
5. Country: **Japan**
6. Accept terms

### Step 2: Create Ad Units
1. Go to **Apps** → **Add app**
2. Select **Android**
3. App name: `Morph Gate`
4. App store URL: (leave blank for now)
5. Add app

#### Create Banner Ad Unit
1. **Ad format**: Banner
2. **Name**: `game_screen_banner`
3. Copy **Ad Unit ID**: `ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyyyy`

#### Create Rewarded Ad Unit
1. **Ad format**: Rewarded
2. **Name**: `game_reward_video`
3. Copy **Ad Unit ID**

#### Create Interstitial Ad Unit
1. **Ad format**: Interstitial
2. **Name**: `game_over_interstitial`
3. Copy **Ad Unit ID**

### Step 3: Add google_mobile_ads Package
Already in `pubspec.yaml`:
```yaml
dependencies:
  google_mobile_ads: ^5.3.0
```

### Step 4: Update AndroidManifest.xml
Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest ...>
  <uses-permission android:name="android.permission.INTERNET"/>
  <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
  
  <application ...>
    <!-- Add AdMob App ID -->
    <meta-data
      android:name="com.google.android.gms.ads.APPLICATION_ID"
      android:value="ca-app-pub-xxxxxxxxxxxxxxxxxxxxxxxx"/>
  </application>
</manifest>
```

### Step 5: Initialize Google Mobile Ads
Edit `lib/main.dart`:

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Google Mobile Ads
  await MobileAds.instance.initialize();
  
  // Firebase init...
  await Firebase.initializeApp(...);
  
  runApp(const MyApp());
}
```

### Step 6: Implement Ad Services
Create `lib/services/ads_service.dart`:

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  static final _instance = AdsService._internal();
  
  factory AdsService() => _instance;
  AdsService._internal();
  
  // Ad Unit IDs (replace with your IDs)
  static const String _bannerAdUnitId = 
      'ca-app-pub-3940256099942544/6300978111'; // Test ID
  static const String _rewardedAdUnitId = 
      'ca-app-pub-3940256099942544/5224354917'; // Test ID
  static const String _interstitialAdUnitId = 
      'ca-app-pub-3940256099942544/1033173712'; // Test ID
  
  BannerAd? _bannerAd;
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  
  // ── Banner Ad (Game Screen Bottom)
  Future<void> loadBannerAd() async {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) => print('Banner loaded'),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('Banner failed: $error');
        },
      ),
    )..load();
  }
  
  BannerAd? getBannerAd() => _bannerAd;
  
  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }
  
  // ── Rewarded Ad (Get Extra Lives)
  Future<void> loadRewardedAd() async {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          print('Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          print('Rewarded ad failed: $error');
        },
      ),
    );
  }
  
  Future<bool> showRewardedAd({
    required Function(RewardItem) onUserEarnedReward,
  }) async {
    if (_rewardedAd == null) {
      print('Rewarded ad not loaded');
      return false;
    }
    
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {},
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        print('Rewarded ad failed to show: $error');
        loadRewardedAd(); // Reload
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardedAd(); // Reload
      },
    );
    
    _rewardedAd!.show(
      onUserEarnedReward: onUserEarnedReward,
    );
    
    _rewardedAd = null;
    return true;
  }
  
  // ── Interstitial Ad (Game Over Screen)
  Future<void> loadInterstitialAd() async {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          print('Interstitial loaded');
        },
        onAdFailedToLoad: (error) {
          print('Interstitial failed: $error');
        },
      ),
    );
  }
  
  Future<void> showInterstitialAd() async {
    if (_interstitialAd == null) return;
    
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {},
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        print('Interstitial failed: $error');
        loadInterstitialAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadInterstitialAd();
      },
    );
    
    _interstitialAd!.show();
    _interstitialAd = null;
  }
}
```

### Step 7: Integration Points

#### game_screen.dart - Banner Ad Bottom
```dart
import '../services/ads_service.dart';

@override
void initState() {
  super.initState();
  AdsService().loadBannerAd();
}

@override
Widget build(BuildContext context) {
  final bannerAd = AdsService().getBannerAd();
  
  return Scaffold(
    body: Stack(
      children: [
        // Game content...
        
        // Bottom banner ad
        if (bannerAd != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 50,
              child: AdWidget(ad: bannerAd),
            ),
          ),
      ],
    ),
  );
}
```

#### game_over_screen.dart - Show Interstitial
```dart
import '../services/ads_service.dart';

// After showing game over screen:
await AdsService().showInterstitialAd();
```

#### home_screen.dart - Rewarded Ad for Bonus Lives
```dart
import '../services/ads_service.dart';

// Add button to watch ad for bonus life:
TextButton(
  onPressed: () async {
    final success = await AdsService().showRewardedAd(
      onUserEarnedReward: (reward) {
        // Give player bonus life/currency
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You earned ${reward.amount} ${reward.type}')),
        );
      },
    );
  },
  child: const Text('Watch Ad for Bonus Life'),
)
```

---

## B. REVENUECAT (In-App Purchases)

### Step 1: Create RevenueCat Account
1. Go to **[revenuecat.com](https://revenuecat.com)**
2. Sign up
3. Create new project: `Morph Gate`

### Step 2: Configure Products
1. Go to **Offerings**
2. Create offering: `Premium`

#### Product 1: Premium Pass
- Product ID: `premium_pass`
- Price: ¥499
- Description: "Unlock premium features"

#### Product 2: Character Pack
- Product ID: `character_pack`
- Price: ¥299
- Description: "4 exclusive characters"

#### Product 3: Remove Ads
- Product ID: `remove_ads`
- Price: ¥99
- Description: "Play without ads"

### Step 3: Setup Google Play Store
1. In RevenueCat, go to **Platform Configuration**
2. Select **Android**
3. Add **Google Play Billing Key**:
   - Go to [Google Play Console](https://play.google.com/apps/publish)
   - Select your app
   - Go to **Monetization setup** → **Google Play Billing**
   - Copy **Base64-encoded public key**
   - Paste in RevenueCat

### Step 4: Add RevenueCat Package
Edit `pubspec.yaml`:
```yaml
dependencies:
  purchases_flutter: ^7.14.0
```

### Step 5: Initialize RevenueCat
Edit `lib/main.dart`:

```dart
import 'package:purchases_flutter/purchases_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize RevenueCat
  PurchasesConfiguration configuration = PurchasesConfiguration(
    "pkg_xxxxxxxx", // Replace with your API key from RevenueCat
  );
  await Purchases.configure(configuration);
  
  // Initialize other services...
}
```

### Step 6: Create IAP Service
Create `lib/services/iap_service.dart`:

```dart
import 'package:purchases_flutter/purchases_flutter.dart';

class IAPService {
  static Future<bool> isPremium() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all.containsKey('premium');
    } catch (e) {
      print('Error checking premium: $e');
      return false;
    }
  }
  
  static Future<void> purchasePremium() async {
    try {
      final offerings = await Purchases.getOfferings();
      final package = offerings?.current?.getPackage('premium_pass');
      
      if (package != null) {
        await Purchases.purchasePackage(package);
      }
    } catch (e) {
      print('Purchase error: $e');
    }
  }
  
  static Future<void> purchaseRemoveAds() async {
    try {
      final offerings = await Purchases.getOfferings();
      final package = offerings?.current?.getPackage('remove_ads');
      
      if (package != null) {
        await Purchases.purchasePackage(package);
      }
    } catch (e) {
      print('Purchase error: $e');
    }
  }
  
  static Future<List<Package>> getAvailablePackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings?.current?.availablePackages ?? [];
    } catch (e) {
      print('Error fetching offerings: $e');
      return [];
    }
  }
}
```

### Step 7: Integration Points

#### home_screen.dart - Show Premium Features
```dart
import '../services/iap_service.dart';

// Check if premium
final isPremium = await IAPService.isPremium();

if (!isPremium) {
  // Show purchase button
  TextButton(
    onPressed: () => IAPService.purchasePremium(),
    child: const Text('Unlock Premium'),
  )
}
```

#### game_screen.dart - Show Ads Only for Non-Premium
```dart
final isPremium = await IAPService.isPremium();

if (!isPremium) {
  // Show banner ads
  AdsService().loadBannerAd();
} else {
  // Premium user - no ads
}
```

---

## C. MONETIZATION STRATEGY

### Free Players
- ✅ Standard gameplay with ads
- ✅ Banner ads at bottom of game screen
- ✅ Interstitial ads on game over
- ✅ Rewarded video ads for bonus features
- ❌ No ad removal option

### Premium Players (¥499)
- ✅ All ad removal
- ✅ 2x score multiplier
- ✅ Unlock 4 exclusive characters
- ✅ Daily bonus lives
- ✅ Cloud save sync

### Revenue Split
- Google Ads: ~40% from ad revenue
- In-app purchases: ~70% (Google takes 30%)
- Target: $500-2000/month

---

## Testing Checklist

- [ ] AdMob account created
- [ ] Ad units created (banner, rewarded, interstitial)
- [ ] Test ad unit IDs configured
- [ ] google_mobile_ads package added
- [ ] Google Mobile Ads initialized
- [ ] Banner ads display correctly
- [ ] Rewarded ads work
- [ ] Interstitial ads show
- [ ] RevenueCat account created
- [ ] Products configured
- [ ] RevenueCat API key added
- [ ] purchases_flutter package added
- [ ] IAP service working
- [ ] Purchase flow tested
- [ ] Premium features gated correctly
- [ ] Analytics tracking IAP events

---

## Timeline
- AdMob setup: 30 min
- RevenueCat setup: 30 min
- Ad service implementation: 60 min
- IAP service implementation: 60 min
- Integration: 60 min
- Testing: 30 min
- **Total Phase C**: 4 hours

---

## Common Issues

### "Ads not showing"
- Check API key in AdMob
- Use test ad unit IDs during development
- Check network connectivity

### "Purchase failing"
- Verify billing setup in Google Play
- Check RevenueCat API key
- Test with sandbox account

### "Payment not processed"
- Check Google Play billing enabled
- Verify app version matches store listing
