import 'package:shared_preferences/shared_preferences.dart';
import '../services/purchase_service.dart';

class ProUtils {
  static const String _proKey = 'is_pro_user';
  static const String _proPurchaseDateKey = 'pro_purchase_date';
  static const String _proPurchaseIdKey = 'pro_purchase_id';
  static const String _proPurchaseTokenKey = 'pro_purchase_token';

  static final PurchaseService _purchaseService = PurchaseService();

  static Future<bool> isProUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_proKey) ?? false;
  }

  static Future<void> setProUser(bool isPro, {String? purchaseId, String? purchaseToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_proKey, isPro);
    
    if (isPro) {
      await prefs.setString(_proPurchaseDateKey, DateTime.now().toIso8601String());
      if (purchaseId != null) {
        await prefs.setString(_proPurchaseIdKey, purchaseId);
      }
      if (purchaseToken != null) {
        await prefs.setString(_proPurchaseTokenKey, purchaseToken);
      }
    } else {
      await prefs.remove(_proPurchaseDateKey);
      await prefs.remove(_proPurchaseIdKey);
      await prefs.remove(_proPurchaseTokenKey);
    }
  }

  static Future<DateTime?> getProPurchaseDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_proPurchaseDateKey);
    
    if (dateString != null) {
      return DateTime.tryParse(dateString);
    }
    
    return null;
  }

  static Future<String?> getProPurchaseId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_proPurchaseIdKey);
  }

  static Future<String?> getProPurchaseToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_proPurchaseTokenKey);
  }

  static Future<bool> shouldShowAds() async {
    final isPro = await isProUser();
    return !isPro;
  }

  static Future<bool> upgradeToPro() async {
    try {
      // Tentar compra real primeiro
      final success = await _purchaseService.purchasePro();
      if (success) {
        return true;
      }
      
      // Se falhar, simular para testes (apenas em debug)
      return await _purchaseService.simulatePurchase();
    } catch (e) {
      // Em caso de erro, simular para testes (apenas em debug)
      return await _purchaseService.simulatePurchase();
    }
  }

  static Future<bool> restorePro() async {
    try {
      // Tentar restauração real primeiro
      final success = await _purchaseService.restorePurchases();
      if (success) {
        return true;
      }
      
      // Se falhar, simular para testes (apenas em debug)
      return await _purchaseService.simulateRestore();
    } catch (e) {
      // Em caso de erro, simular para testes (apenas em debug)
      return await _purchaseService.simulateRestore();
    }
  }

  static Future<void> initializePurchaseService() async {
    await _purchaseService.initialize();
  }

  static PurchaseService get purchaseService => _purchaseService;
}
