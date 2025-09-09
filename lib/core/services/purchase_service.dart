import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import '../utils/pro_utils.dart';

class PurchaseService {
  static const String _proProductId = 'calc_recisao_pro_monthly';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _purchasePending = false;
  String? _queryProductError;

  // Singleton
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  bool get isAvailable => _isAvailable;
  bool get purchasePending => _purchasePending;
  String? get queryProductError => _queryProductError;
  List<ProductDetails> get products => _products;

  Future<void> initialize() async {
    // Verificar se compras in-app estão disponíveis
    _isAvailable = await _inAppPurchase.isAvailable();

    if (!_isAvailable) {
      debugPrint('In-app purchases not available');
      return;
    }

    // Configurar para Android (não é mais necessário na versão atual)
    // final InAppPurchaseAndroidPlatformAddition androidAddition = _inAppPurchase
    //     .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();

    // Configurar listener para compras
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('Purchase stream error: $error'),
    );

    // Carregar produtos
    await _loadProducts();

    // Restaurar compras anteriores
    await _restorePurchases();
  }

  Future<void> _loadProducts() async {
    const Set<String> productIds = {_proProductId};

    try {
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      _queryProductError = response.error?.message;

      debugPrint('Loaded ${_products.length} products');
    } catch (e) {
      debugPrint('Error loading products: $e');
      _queryProductError = e.toString();
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      await _handlePurchase(purchaseDetails);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.pending) {
      _purchasePending = true;
      debugPrint('Purchase pending: ${purchaseDetails.productID}');
    } else {
      _purchasePending = false;

      if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) {
        // Verificar se a compra é válida
        if (await _verifyPurchase(purchaseDetails)) {
          // Ativar PRO
          await ProUtils.setProUser(true);
          debugPrint('PRO activated for product: ${purchaseDetails.productID}');
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${purchaseDetails.error}');
      }

      // Finalizar a compra
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // Em produção, você deve verificar a compra com seu servidor
    // Por enquanto, vamos aceitar todas as compras
    return true;
  }

  Future<bool> purchasePro() async {
    if (!_isAvailable || _products.isEmpty) {
      debugPrint('Cannot purchase: not available or no products');
      return false;
    }

    final ProductDetails productDetails = _products.first;

    try {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
      final bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

      if (success) {
        _purchasePending = true;
        debugPrint('Purchase initiated for: ${productDetails.id}');
      }

      return success;
    } catch (e) {
      debugPrint('Error initiating purchase: $e');
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    if (!_isAvailable) {
      debugPrint('Cannot restore: in-app purchases not available');
      return false;
    }

    try {
      await _inAppPurchase.restorePurchases();
      debugPrint('Restore purchases initiated');
      return true;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return false;
    }
  }

  Future<void> _restorePurchases() async {
    // Verificar compras ativas
    try {
      await _inAppPurchase.restorePurchases();
      debugPrint('Restore purchases completed');
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
    }
  }

  // Método para simular compra (apenas para testes)
  Future<bool> simulatePurchase() async {
    if (kDebugMode) {
      debugPrint('Simulating PRO purchase...');
      await ProUtils.setProUser(true);
      return true;
    }
    return false;
  }

  // Método para simular restauração (apenas para testes)
  Future<bool> simulateRestore() async {
    if (kDebugMode) {
      debugPrint('Simulating PRO restore...');
      await ProUtils.setProUser(true);
      return true;
    }
    return false;
  }

  void dispose() {
    _subscription?.cancel();
  }
}
