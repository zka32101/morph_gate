import 'package:purchases_flutter/purchases_flutter.dart';

class IAPService {
  static final IAPService _instance = IAPService._();
  factory IAPService() => _instance;
  IAPService._();

  // Product IDs (must match RevenueCat configuration)
  static const String _premiumPassId = 'premium_pass';
  static const String _characterPackId = 'character_pack';
  static const String _removeAdsId = 'remove_ads';

  // Entitlement IDs
  static const String _premiumEntitlement = 'premium';
  static const String _noAdsEntitlement = 'no_ads';

  static Future<void> init(String apiKey) async {
    try {
      await Purchases.configure(
        PurchasesConfiguration(apiKey),
      );
      print('RevenueCat initialized');
    } catch (e) {
      print('RevenueCat init error: $e');
    }
  }

  /// Check if user has premium subscription
  static Future<bool> hasPremium() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all
          .containsKey(_premiumEntitlement);
    } catch (e) {
      print('Premium check error: $e');
      return false;
    }
  }

  /// Check if ads are removed (purchased)
  static Future<bool> hasNoAds() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all
          .containsKey(_noAdsEntitlement);
    } catch (e) {
      print('No ads check error: $e');
      return false;
    }
  }

  /// Get available offerings
  static Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      print('Get offerings error: $e');
      return null;
    }
  }

  /// Purchase premium pass
  static Future<bool> purchasePremiumPass() async {
    try {
      final offerings = await Purchases.getOfferings();
      final package = offerings?.current?.getPackage(_premiumPassId);

      if (package == null) {
        print('Premium pass package not found');
        return false;
      }

      try {
        await Purchases.purchasePackage(package);
        print('Premium pass purchased');
        return true;
      } on PurchasesErrorCode catch (e) {
        if (e.code == PurchasesErrorCode.purchaseCancelledError) {
          print('Purchase cancelled by user');
        } else {
          print('Purchase error: ${e.message}');
        }
        return false;
      }
    } catch (e) {
      print('Purchase premium pass error: $e');
      return false;
    }
  }

  /// Purchase character pack
  static Future<bool> purchaseCharacterPack() async {
    try {
      final offerings = await Purchases.getOfferings();
      final package = offerings?.current?.getPackage(_characterPackId);

      if (package == null) {
        print('Character pack not found');
        return false;
      }

      try {
        await Purchases.purchasePackage(package);
        print('Character pack purchased');
        return true;
      } on PurchasesErrorCode catch (e) {
        if (e.code == PurchasesErrorCode.purchaseCancelledError) {
          print('Purchase cancelled');
        }
        return false;
      }
    } catch (e) {
      print('Purchase character pack error: $e');
      return false;
    }
  }

  /// Purchase remove ads
  static Future<bool> purchaseRemoveAds() async {
    try {
      final offerings = await Purchases.getOfferings();
      final package = offerings?.current?.getPackage(_removeAdsId);

      if (package == null) {
        print('Remove ads package not found');
        return false;
      }

      try {
        await Purchases.purchasePackage(package);
        print('Remove ads purchased');
        return true;
      } on PurchasesErrorCode catch (e) {
        if (e.code == PurchasesErrorCode.purchaseCancelledError) {
          print('Purchase cancelled');
        }
        return false;
      }
    } catch (e) {
      print('Purchase remove ads error: $e');
      return false;
    }
  }

  /// Restore purchases
  static Future<bool> restorePurchases() async {
    try {
      await Purchases.restorePurchases();
      print('Purchases restored');
      return true;
    } catch (e) {
      print('Restore purchases error: $e');
      return false;
    }
  }
}
