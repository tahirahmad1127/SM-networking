import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../infrastructure/model/cart.dart';
import '../infrastructure/model/coupon.dart';

class CartProvider extends ChangeNotifier {
  List<CartModel> _cartList = [];

  void setCartList(List<CartModel> list) {
    _cartList = list;
    notifyListeners();
  }

  void addItem(CartModel model) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool flag = false;
    for (var e in _cartList) {
      if (e.id == model.id) {
        flag = true;
        break;
      }
    }
    if (!flag) {
      _cartList.add(model);
      prefs.setString('CART_DATA', cartModelToJson(_cartList));
      notifyListeners();
    } else {
      increment(model.id, model.quantity);
    }
  }

  int getItemQuantity(String id) {
    int quantity = 0;
    for (var e in _cartList) {
      if (e.id == id) {
        quantity = e.quantity;
        break;
      }
    }
    return quantity;
  }

  void removeItem(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _cartList.removeWhere((e) {
      return e.id == id;
    });
    prefs.setString('CART_DATA', cartModelToJson(_cartList));
    notifyListeners();
  }

  void increment(String id, int quantity) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (var e in _cartList) {
      if (e.id == id) {
        e.quantity = quantity;
        break;
      }
    }

    prefs.setString('CART_DATA', cartModelToJson(_cartList));
    notifyListeners();
  }

  void decrement(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (var e in _cartList) {
      if (e.id == id) {
        if (e.quantity == 1) {
          removeItem(id);
        } else {
          e.quantity--;
        }
        break;
      }
    }

    prefs.setString('CART_DATA', cartModelToJson(_cartList));
    notifyListeners();
  }

  // ============ BULK DISCOUNT METHODS ============

  // Get bulk discount value and type for a specific cart item
  Map<String, dynamic> getBulkDiscountInfo(CartModel cartItem) {
    if (cartItem.productDetails.bulkDiscountQuantity == null ||
        cartItem.productDetails.bulkDiscount == null ||
        cartItem.productDetails.bulkDiscountType == null ||
        cartItem.productDetails.bulkDiscountQuantity!.isEmpty ||
        cartItem.productDetails.bulkDiscount!.isEmpty ||
        cartItem.productDetails.bulkDiscountType!.isEmpty) {
      return {'value': 0, 'type': 'Percentage'};
    }

    num currentQuantity = cartItem.quantity;

    if (cartItem.type.toString().toLowerCase() == 'piece') {
      if (cartItem.productDetails.cortanSize != null &&
          cartItem.productDetails.cortanSize! > 0) {
        currentQuantity =
            cartItem.quantity / cartItem.productDetails.cortanSize!;
      }
    }

    num applicableDiscount = 0;
    String applicableType = 'Percentage';

    for (int i = 0;
    i < cartItem.productDetails.bulkDiscountQuantity!.length;
    i++) {
      num requiredQty = cartItem.productDetails.bulkDiscountQuantity![i];

      if (currentQuantity >= requiredQty) {
        applicableDiscount = cartItem.productDetails.bulkDiscount![i];
        applicableType = cartItem.productDetails.bulkDiscountType![i];
      }
    }

    return {'value': applicableDiscount, 'type': applicableType};
  }

  // Calculate bulk discount percentage for a specific cart item (for backward compatibility)
  num getBulkDiscountPercentage(CartModel cartItem) {
    var discountInfo = getBulkDiscountInfo(cartItem);
    if (discountInfo['type'] == 'Percentage') {
      return discountInfo['value'];
    }
    return 0;
  }

  // ============ PRICE CALCULATION METHODS ============

  // Get original price (per unit) for an item
  // IMPORTANT: cartItem.price should NEVER be modified by coupons
  num getItemOriginalUnitPrice(CartModel cartItem) {
    return num.tryParse(cartItem.price.trim()) ?? 0;
  }

  // Get original total price (without any discounts)
  num getItemOriginalPrice(CartModel cartItem) {
    num originalPrice = getItemOriginalUnitPrice(cartItem);
    return originalPrice * cartItem.quantity;
  }

  // Get price after bulk discount (but before coupon)
  num getItemPriceAfterBulkDiscount(CartModel cartItem) {
    num originalPrice = getItemOriginalPrice(cartItem);
    var discountInfo = getBulkDiscountInfo(cartItem);
    num bulkDiscountValue = discountInfo['value'];
    String bulkDiscountType = discountInfo['type'];

    if (bulkDiscountValue <= 0) return originalPrice;

    if (bulkDiscountType == 'Percentage') {
      num discountAmount = (originalPrice * bulkDiscountValue) / 100;
      return originalPrice - discountAmount;
    }
    else if (bulkDiscountType == 'Flat') {
      // FLAT DISCOUNT: Apply only ONCE if threshold met
      num currentQuantity = cartItem.quantity;
      if (cartItem.type.toString().toLowerCase() == 'piece') {
        if (cartItem.productDetails.cortanSize != null && cartItem.productDetails.cortanSize! > 0) {
          currentQuantity = cartItem.quantity / cartItem.productDetails.cortanSize!;
        }
      }

      // Check if ANY bulk tier is satisfied
      bool qualifies = false;
      for (int i = 0; i < cartItem.productDetails.bulkDiscountQuantity!.length; i++) {
        if (currentQuantity >= cartItem.productDetails.bulkDiscountQuantity![i]) {
          qualifies = true;
          break;
        }
      }

      if (qualifies) {
        return originalPrice - bulkDiscountValue; // Apply flat discount ONCE
      }
    }

    return originalPrice;
  }

  // Get bulk discount amount for an item
  num getItemBulkDiscountAmount(CartModel cartItem) {
    num originalPrice = getItemOriginalPrice(cartItem);
    num priceAfterBulk = getItemPriceAfterBulkDiscount(cartItem);
    return originalPrice - priceAfterBulk;
  }

  // Get coupon discounted unit price (if coupon applied)
  num getItemCouponUnitPrice(CartModel cartItem) {
    if (cartItem.discountedPrice != null &&
        cartItem.discountedPrice!.isNotEmpty) {
      return num.tryParse(cartItem.discountedPrice!.trim()) ?? getItemOriginalUnitPrice(cartItem);
    }
    return getItemOriginalUnitPrice(cartItem);
  }

  // Get price after coupon discount (but before bulk discount)
  num getItemPriceAfterCouponOnly(CartModel cartItem) {
    num couponUnitPrice = getItemCouponUnitPrice(cartItem);
    return couponUnitPrice * cartItem.quantity;
  }

  // Get coupon discount amount (calculated from original price)
  num getItemCouponDiscountAmount(CartModel cartItem) {
    return getItemOriginalPrice(cartItem) - getItemPriceAfterCouponOnly(cartItem);
  }

  // Calculate final price with SEQUENTIAL discounts: First Bulk, Then Coupon
  num calculateItemFinalPrice(CartModel cartItem) {
    // If coupon is applied (via API), use the stored discounted price directly
    // The API method already calculated: bulk discount + coupon discount
    if (cartItem.discountedPrice != null && cartItem.discountedPrice!.isNotEmpty) {
      num discountedPerUnit = num.tryParse(cartItem.discountedPrice!.trim()) ?? 0;
      return discountedPerUnit * cartItem.quantity;
    }

    // No coupon applied - just calculate with bulk discount
    num price = getItemOriginalPrice(cartItem);

    // Apply bulk discount
    var discountInfo = getBulkDiscountInfo(cartItem);
    num bulkDiscountValue = discountInfo['value'];
    String bulkDiscountType = discountInfo['type'];

    if (bulkDiscountValue > 0) {
      if (bulkDiscountType == 'Percentage') {
        num bulkDiscountAmount = (price * bulkDiscountValue) / 100;
        price = price - bulkDiscountAmount;
      }
      else if (bulkDiscountType == 'Flat') {
        num currentQuantity = cartItem.quantity;
        if (cartItem.type.toString().toLowerCase() == 'piece') {
          if (cartItem.productDetails.cortanSize != null && cartItem.productDetails.cortanSize! > 0) {
            currentQuantity = cartItem.quantity / cartItem.productDetails.cortanSize!;
          }
        }

        bool qualifies = false;
        for (int i = 0; i < cartItem.productDetails.bulkDiscountQuantity!.length; i++) {
          if (currentQuantity >= cartItem.productDetails.bulkDiscountQuantity![i]) {
            qualifies = true;
            break;
          }
        }

        if (qualifies) {
          price = price - bulkDiscountValue; // Apply once
        }
      }
    }

    return price;
  }

  // ============ BACKWARD COMPATIBILITY METHODS ============

  // Get item price without bulk discount (but with regular discount if exists)
  // Used in CartCard and other existing files
  num getItemPriceWithoutBulkDiscount(CartModel cartItem) {
    num basePrice = cartItem.discountedPrice != null &&
        cartItem.discountedPrice!.isNotEmpty
        ? num.tryParse(cartItem.discountedPrice!.trim()) ?? 0
        : num.tryParse(cartItem.price.trim()) ?? 0;

    return basePrice * cartItem.quantity;
  }

  // ============ CART TOTAL METHODS ============

  /// Get subtotal without any discounts (original prices only)
  num getSubTotalWithoutAnyDiscount() {
    num total = 0;
    for (var e in _cartList) {
      total += getItemOriginalPrice(e);
    }
    return total;
  }

  /// Get subtotal without bulk discount (for display purposes)
  num getSubTotalWithoutBulkDiscount() {
    num total = 0;
    for (var e in _cartList) {
      total += getItemPriceWithoutBulkDiscount(e);
    }
    return total;
  }

  /// Get total bulk discount amount across all items
  num getTotalBulkDiscount() {
    num total = 0;
    for (var e in _cartList) {
      total += getItemBulkDiscountAmount(e);
    }
    return total;
  }

  /// Get total coupon discount amount (applied after bulk discount)
  num getTotalCouponDiscount() {
    num total = 0;
    for (var e in _cartList) {
      total += getItemActualCouponDiscount(e);
    }
    return total;
  }

  // Get the actual coupon discount applied after bulk discount
  num getItemActualCouponDiscount(CartModel cartItem) {
    if (!itemHasCoupon(cartItem)) return 0;

    num priceAfterBulk = getItemPriceAfterBulkDiscount(cartItem);
    num finalPrice = calculateItemFinalPrice(cartItem);

    return priceAfterBulk - finalPrice;
  }

  /// Get final subtotal (after all discounts)
  num getSubTotal() {
    num total = 0;
    for (var e in _cartList) {
      total += calculateItemFinalPrice(e);
    }
    return total;
  }

  // ============ COUPON MANAGEMENT ============

  /// Clear all coupon discounts from cart items
  void clearCoupons() {
    for (var item in _cartList) {
      item.discountedPrice = null;
    }
    notifyListeners();
  }

  /// Apply all-products coupon
  /// CRITICAL: Only modifies discountedPrice, NEVER touches cartItem.price
  void applyAllProductsCoupon(String discountType, double discountValue) {
    for (var cartItem in _cartList) {
      // Get the ORIGINAL per-piece/per-carton price (never modified)
      double originalPerUnit = double.tryParse(cartItem.price) ?? 0.0;
      double discountedPerUnit;

      if (discountType.toLowerCase() == 'percentage') {
        // Apply percentage discount to original price
        discountedPerUnit = originalPerUnit * (1 - discountValue / 100);
      } else if (discountType.toLowerCase() == 'flat') {
        // For flat discount on all products, distribute evenly
        int totalItems = _cartList.length;
        double discountPerItem = discountValue / totalItems;
        discountedPerUnit = originalPerUnit - (discountPerItem / cartItem.quantity);
        // Ensure price doesn't go negative
        if (discountedPerUnit < 0) discountedPerUnit = 0;
      } else {
        discountedPerUnit = originalPerUnit;
      }

      // CRITICAL: Only set discountedPrice, NEVER modify cartItem.price
      // The original price must remain unchanged for bulk discount calculations
      cartItem.discountedPrice = discountedPerUnit.toStringAsFixed(2);
    }

    notifyListeners();
  }

  /// Apply specific-products coupon
  /// CRITICAL: Only modifies discountedPrice for matching products
  void applySpecificProductsCoupon(List<CouponProduct> products) {
    for (var cartItem in _cartList) {
      final matching = products.firstWhere(
            (p) => p.productId == cartItem.productDetails.id.toString(),
        orElse: () => CouponProduct(),
      );

      if (matching.discountedPrice == null) {
        // Product not in coupon list - skip (leave prices intact)
        continue;
      }

      // Get discounted price from coupon API (per piece)
      double discountedPerPiece = double.tryParse(
          matching.discountedPrice?.toString() ?? "0"
      ) ?? 0.0;

      int cortanSize = cartItem.productDetails.cortanSize ?? 1;

      // For cartons, multiply by carton size
      double finalDiscountedPrice = cartItem.type == "ctn"
          ? discountedPerPiece * cortanSize
          : discountedPerPiece;

      // CRITICAL: Only set discountedPrice, NEVER modify cartItem.price
      cartItem.discountedPrice = finalDiscountedPrice.toStringAsFixed(2);
    }

    notifyListeners();
  }

  /// NEW METHOD: Apply coupon from API response
  /// This handles the new API structure where discountedPrice is the total price per item
  /// IMPORTANT: API calculates coupon on ORIGINAL prices, not bulk-discounted prices
  void applyCouponFromAPI(List<CouponProduct> products) {
    log('📦 Applying coupon from API with ${products.length} products');

    for (var cartItem in _cartList) {
      // Find matching product from API response by productId (which matches cartItem.id)
      final matching = products.firstWhere(
            (p) => p.productId == cartItem.id,
        orElse: () => CouponProduct(),
      );

      if (matching.discountedPrice == null) {
        log('⚠️ No coupon discount for: ${cartItem.name} (${cartItem.id})');
        continue;
      }

      // API returns prices based on ORIGINAL prices (without bulk discount)
      // originalPrice = what API sees (without bulk)
      // discountedPrice = after coupon applied by API (without bulk)

      double apiOriginalPrice = matching.originalPrice?.toDouble() ?? 0.0;
      double apiDiscountedPrice = matching.discountedPrice!.toDouble();

      // Calculate coupon discount percentage from API
      double couponDiscountPercent = 0;
      if (apiOriginalPrice > 0) {
        couponDiscountPercent = ((apiOriginalPrice - apiDiscountedPrice) / apiOriginalPrice) * 100;
      }

      // Get our bulk-discounted price per unit
      num priceAfterBulk = getItemPriceAfterBulkDiscount(cartItem);
      num priceAfterBulkPerUnit = priceAfterBulk / cartItem.quantity;

      // Apply the coupon percentage to the bulk-discounted price
      double finalDiscountedPerUnit = priceAfterBulkPerUnit * (1 - couponDiscountPercent / 100);

      log('✅ Applied coupon to ${cartItem.name}:');
      log('   API original total: $apiOriginalPrice');
      log('   API discounted total: $apiDiscountedPrice');
      log('   Coupon discount %: ${couponDiscountPercent.toStringAsFixed(2)}%');
      log('   Our bulk-discounted per unit: $priceAfterBulkPerUnit');
      log('   Final per unit (bulk + coupon): $finalDiscountedPerUnit');
      log('   Quantity: ${cartItem.quantity}, Type: ${cartItem.type}');

      // Store the per-unit price with coupon applied to bulk-discounted price
      cartItem.discountedPrice = finalDiscountedPerUnit.toStringAsFixed(2);
    }

    notifyListeners();
  }

  /// Get total savings from coupon (for UI display)
  num getTotalCouponSavings() {
    num total = 0;
    for (var e in _cartList) {
      if (itemHasCoupon(e)) {
        num originalUnitPrice = getItemOriginalUnitPrice(e);
        num couponUnitPrice = getItemCouponUnitPrice(e);
        num savingsPerUnit = originalUnitPrice - couponUnitPrice;
        total += savingsPerUnit * e.quantity;
      }
    }
    return total;
  }

  /// Check if coupon is applicable to specific item
  bool isItemEligibleForCoupon(CartModel item, List<CouponProduct>? products) {
    if (products == null || products.isEmpty) {
      return true; // All-products coupon
    }

    return products.any((p) =>
    p.productId == item.id &&
        p.discountedPrice != null
    );
  }

  // ============ HELPER METHODS ============

  // Check if item has coupon applied
  bool itemHasCoupon(CartModel cartItem) {
    return cartItem.discountedPrice != null &&
        cartItem.discountedPrice!.isNotEmpty &&
        cartItem.discountedPrice != cartItem.price;
  }

  /// Check if any item has coupon applied
  bool hasCouponApplied() {
    return _cartList.any((item) => itemHasCoupon(item));
  }

  // Get bulk discount display text
  String getBulkDiscountDisplayText(CartModel cartItem) {
    var discountInfo = getBulkDiscountInfo(cartItem);
    num value = discountInfo['value'];
    String type = discountInfo['type'];

    if (value == 0) return '';

    if (type == 'Percentage') {
      return '${value.toInt()}% OFF';
    } else {
      return '${value.toStringAsFixed(0)} Rs OFF';
    }
  }

  List<CartModel> get cartItems => _cartList;

  void emptyCart() async {
    _cartList.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('CART_DATA');
    notifyListeners();
  }

  /// Call this on logout to wipe all cart state (in-memory + persisted)
  Future<void> clearData() async {
    _cartList.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('CART_DATA');
    notifyListeners();
  }
}