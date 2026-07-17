import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sm_networking/application/cart_provider.dart';
// import 'package:sm_networking/application/coupon_bloc/coupon_bloc.dart';
import 'package:sm_networking/application/offline_mode_provider.dart';
import 'package:sm_networking/application/retailer_provider.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/application/visit_provider.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/configurations/translation_helper.dart';
import 'package:sm_networking/infrastructure/model/create_order.dart';
import 'package:sm_networking/infrastructure/model/retailer.dart';
import 'package:sm_networking/infrastructure/services/retailer.dart';
import 'package:sm_networking/presentation/elements/flush_bar.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../application/connectivity_status.dart';
import '../../../../application/location.dart';
import '../../../../application/order_bloc/order_bloc.dart';
import '../../../../application/visit_bloc/visit_bloc.dart';
// import '../../../../infrastructure/model/coupon.dart';
import '../../../../infrastructure/model/pending_sync_order.dart';
import '../../../../infrastructure/model/visit.dart';
import '../../../../infrastructure/services/pending_sync.dart';
import '../../../../injection_container.dart';
import '../../../elements/app_button.dart';
import '../../../elements/custom_text.dart';
import '../../../elements/draft_saved_view.dart';
import '../../../elements/my_logger.dart';
import '../../order/order_placed_view.dart';
import 'widgets/items_card.dart';

class CheckOutBody extends StatefulWidget {
  const CheckOutBody({super.key});

  @override
  State<CheckOutBody> createState() => _CheckOutBodyState();
}

class _CheckOutBodyState extends State<CheckOutBody> {
  final TextEditingController couponController = TextEditingController();
  RetailerModel? selectedRetailer;
  List<RetailerModel> retailersList = [];

  // Remembers the order most recently sent to the live API, so that if it
  // fails (server unreachable, 500, timeout, etc.) it can be queued locally
  // instead of being lost outright.
  PendingSyncOrder? _lastAttemptedOrder;

  // "Place Order" does real async work (reverse geocoding, visit lookup,
  // connectivity check) before the OrderBloc ever gets CreateOrderEvent —
  // which is the only thing that flips the bloc-driven LoadingOverlay on.
  // Without this, that whole stretch shows zero feedback and a double-tap
  // could fire two orders.
  bool _isPlacingOrder = false;

  @override
  void initState() {
    var user = Provider.of<UserProvider>(context, listen: false);
    final zone = user.getSalesUserDetails()?.user?.zone;
    if (zone != null) {
      RetailerRepositoryImp().getRetailers(zone.toString()).then((val) {
        val.fold((e) {}, (r) {
          if (mounted) retailersList = r.data ?? [];
        });
      });
    }
    super.initState();
  }

  // ─── resolve a non-empty shipping address from RetailerModel ───────────────
  String _resolveShippingAddress(RetailerModel r) {
    final a1 = r.shopAddress1?.trim() ?? '';
    if (a1.isNotEmpty && a1 != 'null') return a1;

    final a2 = r.shopAddress2?.trim() ?? '';
    if (a2.isNotEmpty && a2 != 'null' && a2 != 'N/A') return a2;

    final shop = r.shopName?.trim() ?? '';
    if (shop.isNotEmpty && shop != 'null') return shop;

    return r.name?.trim().isNotEmpty == true ? r.name! : 'N/A';
  }

  // ─── Place Order (and, when offline, the sole "Add to Drafts" action) ──
  // [forceOfflineQueue] is true only when Offline Mode's "Add to Drafts"
  // button calls this — it always queues locally regardless of the live
  // connectivity check, so a whole offline session doesn't end up with some
  // orders going straight to the server and others queued. When false
  // (online-mode "Place Order"), behavior is byte-for-byte what it always
  // was: try the API, fall back to the local queue only if that fails.
  Future<void> _placeOrder({required bool forceOfflineQueue}) async {
    if (_isPlacingOrder) return;
    setState(() => _isPlacingOrder = true);
    try {
      final user = Provider.of<UserProvider>(context, listen: false);
      final retailer = Provider.of<RetailerProvider>(context, listen: false);
      final cart = Provider.of<CartProvider>(context, listen: false);
      final offlineMode =
          Provider.of<OfflineModeProvider>(context, listen: false);
      final visitProvider =
          Provider.of<VisitProvider>(context, listen: false);

      if (visitProvider.isVisitAutoLogged) {
        getFlushBar(context,
            title: "Cannot place order. You moved away from the location.");
        return;
      }

      if (retailer.getRetailer() == null) {
        getFlushBar(context, title: "Kindly select retailer in order to proceed.");
        return;
      }

      if (user.getSalesUserDetails()?.user == null) {
        getFlushBar(context, title: "Session expired. Please sign in again.");
        return;
      }

      // ── reverse geocode from retailer lat/lng ──
      String shippingAddress = _resolveShippingAddress(retailer.getRetailer()!);
      final rLat = retailer.getRetailer()!.lat;
      final rLng = retailer.getRetailer()!.lng;
      if (rLat != null && rLng != null) {
        try {
          final placemarks =
              await placemarkFromCoordinates(rLat.toDouble(), rLng.toDouble());
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final parts = [
              p.name,
              p.street,
              p.subLocality,
              p.locality,
              p.administrativeArea,
            ].where((s) => s != null && s.isNotEmpty).toList();
            final geocoded = parts.join(', ');
            if (geocoded.isNotEmpty) {
              shippingAddress = geocoded;
            }
            log("📍 Geocoded shipping address: $shippingAddress");
          }
        } catch (e) {
          log("⚠️ Geocoding failed, using fallback: $e");
        }
      }

      final userDetails = user.getSalesUserDetails()!.user!;
      final selectedRetailer = retailer.getRetailer()!;
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);

      final startVisit = await visitProvider.getStartVisit();
      final visitLocation = visitProvider.visitLocation;

      // Captured instead of dispatched immediately when offline, so it can
      // ride along with the queued order and sync (image upload included)
      // once the user taps Sync — see PendingSyncProvider.syncOne.
      PendingVisitInfo? capturedVisitInfo;

      if (startVisit != null && visitLocation != null) {
        if (visitProvider.isNewShop) {
          AppLogger.debug("🏪 New shop - logging visit without distance check");

          final visit = VisitModel(
              retailerId: selectedRetailer.id.toString(),
              salesPersonId: userDetails.id.toString(),
              shopName: selectedRetailer.shopName ?? '',
              retailerEmail: '',
              retailerImage: selectedRetailer.image ?? '',
              startTime: startVisit.toIso8601String(),
              endTime: DateTime.now().toIso8601String(),
              date: DateTime.now().toString().split(' ')[0],
              image: "");

          if (offlineMode.isOffline) {
            capturedVisitInfo = PendingVisitInfo(
              retailerId: visit.retailerId ?? '',
              salesPersonId: visit.salesPersonId ?? '',
              shopName: visit.shopName ?? '',
              startTime: visit.startTime ?? '',
              endTime: visit.endTime ?? '',
              date: visit.date ?? '',
              localImagePath: null,
            );
          } else {
            context.read<VisitBloc>().add(AddVisitEvent(visit));
          }
        } else {
          final currentLocation = locationProvider.getLatLng();

          if (currentLocation == null) {
            getFlushBar(context, title: "Current location not available");
            return;
          }

          final hasMovedAway = visitProvider.hasMovedBeyondThreshold(
              currentLocation,
              thresholdMeters: 20);

          final visit = VisitModel(
              retailerId: selectedRetailer.id.toString(),
              salesPersonId: userDetails.id.toString(),
              shopName: selectedRetailer.shopName ?? '',
              retailerEmail: '',
              retailerImage: selectedRetailer.image ?? '',
              startTime: startVisit.toIso8601String(),
              endTime: DateTime.now().toIso8601String(),
              date: DateTime.now().toString().split(' ')[0],
              image: visitProvider.visitImage ?? "");

          if (hasMovedAway) {
            // No order gets placed on this path either way — only bother
            // logging the visit itself when actually online; there's no
            // order to piggyback a queued visit-only record on offline.
            if (!offlineMode.isOffline) {
              context.read<VisitBloc>().add(AddVisitEvent(visit));
            }
            await visitProvider.clearVisitData();
            getFlushBar(context,
                title:
                    "Visit logged. You moved away from the location. Order not placed.");
            Navigator.pop(context);
            return;
          }

          if (offlineMode.isOffline) {
            capturedVisitInfo = PendingVisitInfo(
              retailerId: visit.retailerId ?? '',
              salesPersonId: visit.salesPersonId ?? '',
              shopName: visit.shopName ?? '',
              startTime: visit.startTime ?? '',
              endTime: visit.endTime ?? '',
              date: visit.date ?? '',
              localImagePath:
                  visitProvider.visitImage != null && visitProvider.visitImage!.isNotEmpty
                      ? visitProvider.visitImage
                      : null,
            );
          } else {
            context.read<VisitBloc>().add(AddVisitEvent(visit));
          }
        }
      }

      final couponCode = cart.hasCouponApplied() &&
              couponController.text.trim().isNotEmpty
          ? couponController.text.trim()
          : "";

      final orderModel = CreateOrderModel(
        retailerUser: selectedRetailer.id.toString(),
        saleUser: userDetails.id.toString(),
        orderType: selectedRetailer.customerType.toLowerCase() == 'distributor'
            ? 'company'
            : 'market_booking',
        phoneNumber: (selectedRetailer.phoneNumber == null ||
                selectedRetailer.phoneNumber!.isEmpty)
            ? "N/A"
            : selectedRetailer.phoneNumber!,
        city: userDetails.zone.toString(),
        paymentType: "cod",
        couponCode: couponCode,
        shippingAddress: shippingAddress,
        bulkDiscount: cart.getTotalBulkDiscount() > 0
            ? cart.getTotalBulkDiscount().toDouble()
            : null,
        couponDiscount: cart.hasCouponApplied()
            ? cart.getTotalCouponDiscount().toDouble()
            : null,
        items: cart.cartItems.map((e) {
          final totalFinalPrice = cart.calculateItemFinalPrice(e);
          final totalOriginalPrice = cart.getItemOriginalPrice(e);

          num finalPiecePrice;
          num originalPiecePrice;

          if (e.type.toLowerCase() == "ctn") {
            int cartonSize = e.productDetails.cortanSize ?? 1;
            int totalPieces = e.quantity * cartonSize;
            finalPiecePrice = totalFinalPrice / totalPieces;
            originalPiecePrice = totalOriginalPrice / totalPieces;
          } else {
            finalPiecePrice = totalFinalPrice / e.quantity;
            originalPiecePrice = totalOriginalPrice / e.quantity;
          }

          return OrderItem(
            productId: e.productDetails.id,
            quantity: e.quantity,
            cartonSize: e.productDetails.cortanSize,
            type: e.type,
            price: originalPiecePrice,
            discountedPrice: finalPiecePrice,
          );
        }).toList(),
      );

      final itemInfo = cart.cartItems
          .map((e) => PendingSyncItemInfo(
                productName: e.name,
                productImage: e.image,
              ))
          .toList();

      // ── Online/offline branch ──
      // Try a real reachability check (not just OS-level connectivity)
      // before deciding — unless forceOfflineQueue is set (Offline Mode's
      // Add to Drafts), which always queues regardless of what a live
      // connectivity probe says.
      final isOnline = forceOfflineQueue
          ? false
          : await InternetConnectivityHelper.checkConnectivityFast();

      if (isOnline) {
        _lastAttemptedOrder = PendingSyncOrder(
          localId: const Uuid().v4(),
          model: orderModel,
          customerName:
              selectedRetailer.shopName ?? selectedRetailer.name ?? 'Customer',
          total: cart.getSubTotal().toDouble(),
          createdAt: DateTime.now(),
          itemInfo: itemInfo,
        );
        BlocProvider.of<OrderBloc>(context).add(CreateOrderEvent(orderModel));
      } else {
        // No internet (or Offline Mode is on) — queue locally instead of
        // calling the API. The order still "punches" from the
        // salesperson's point of view; it just isn't on the server yet.
        await PendingSyncService.add(
          PendingSyncOrder(
            localId: const Uuid().v4(),
            model: orderModel,
            customerName:
                selectedRetailer.shopName ?? selectedRetailer.name ?? 'Customer',
            total: cart.getSubTotal().toDouble(),
            createdAt: DateTime.now(),
            itemInfo: itemInfo,
            visitInfo: capturedVisitInfo,
          ),
        );
        if (context.mounted) {
          cart.emptyCart();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OrderPlacedView()),
          );
        }
      }

      await visitProvider.clearVisitData();
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<UserProvider>(context);
    var retailer = Provider.of<RetailerProvider>(context);
    var cart = Provider.of<CartProvider>(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<OrderBloc>()),
        BlocProvider(create: (_) => sl<VisitBloc>()),
        // BlocProvider(create: (_) => sl<CouponBloc>()),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<OrderBloc, OrderState>(
            listener: (context, state) {
              if (state is DraftCreated) {
                cart.emptyCart();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const DraftSavedView()),
                  (route) => false,
                );
              } else if (state is OrderCreated) {
                _lastAttemptedOrder = null;
                cart.emptyCart();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const OrderPlacedView()),
                );
              } else if (state is OrderFailed) {
                final pending = _lastAttemptedOrder;
                final msg = state.message.toString();
                final looksLikeNetworkFailure =
                    msg.contains("not connected to the internet") ||
                        msg.contains("undergoing maintenance") ||
                        msg.contains("unable to complete your request") ||
                        msg.contains("unable to connect our servers");

                if (pending != null && looksLikeNetworkFailure) {
                  PendingSyncService.add(pending).then((_) {
                    if (context.mounted) {
                      cart.emptyCart();
                      _lastAttemptedOrder = null;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const OrderPlacedView()),
                      );
                    }
                  });
                } else {
                  _lastAttemptedOrder = null;
                  getFlushBar(context, title: msg);
                }
              }
            },
          ),
          BlocListener<VisitBloc, VisitState>(
            listener: (context, state) {
              if (state is VisitLoaded) {
                AppLogger.debug("Visit Added Successfully: ${state.model}");
              } else if (state is VisitFailed) {
                AppLogger.debug("Visit Add Failed: ${state.message}");
              }
            },
          ),
          /*
          BlocListener<CouponBloc, CouponState>(
            listener: (context, state) {
              if (state is CouponLoading) {
                setState(() => isLoading = true);
              } else if (state is CouponLoaded) {
                setState(() => isLoading = false);

                final couponData = state.model;
                var cart = Provider.of<CartProvider>(context, listen: false);

                cart.applyCouponFromAPI(couponData.products ?? []);

                bool isAllProductsCoupon = couponData.products == null ||
                    couponData.products!.isEmpty;

                if (isAllProductsCoupon) {
                  String discountText = couponData.discountType == 'percentage'
                      ? '${couponData.discountValue?.toStringAsFixed(0)}%'
                      : 'Rs ${couponData.discountValue?.toStringAsFixed(0)}';

                  getFlushBar(context,
                      title: "Coupon Applied! $discountText off on all items");
                } else {
                  int affectedItems = couponData.products!.length;
                  getFlushBar(context,
                      title: "Coupon Applied! Discount on $affectedItems item(s)");
                }
              } else if (state is CouponFailed) {
                setState(() => isLoading = false);
                getFlushBar(context, title: state.message);
              }
            },
          )
          */
        ],
        child: BlocBuilder<OrderBloc, OrderState>(
          builder: (context, state) {
            return LoadingOverlay(
              isLoading: state is OrderLoading || _isPlacingOrder,
              progressIndicator: const ProcessingWidget(),
              color: Colors.transparent,
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText(
                              text: TranslationHelper.getTranslatedText(
                                  'checkout'),
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      FrontendConfigs.appDivider,
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Customer Details",
                              style: FrontendConfigs.kTitleStyle.copyWith(
                                fontFamily: "Raleway",
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 11),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: FrontendConfigs.kAppBorder,
                            color: FrontendConfigs.kTextFieldColor,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.sizeOf(context).width *
                                          0.85,
                                      child: CustomText(
                                        text: retailer.getRetailer() == null
                                            ? "Select Retailer"
                                            : _resolveShippingAddress(
                                                retailer.getRetailer()!),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    CustomText(
                                      text: retailer
                                          .getRetailer()!
                                          .name
                                          .toString(),
                                      fontSize: 13,
                                      color: FrontendConfigs.kAuthTextColor,
                                    ),
                                    const SizedBox(height: 5),
                                    CustomText(
                                      text: retailer
                                          .getRetailer()!
                                          .shopName
                                          .toString(),
                                      fontSize: 13,
                                      color: FrontendConfigs.kAuthTextColor,
                                    ),
                                    const SizedBox(height: 5),
                                    CustomText(
                                      text: retailer
                                          .getRetailer()!
                                          .phoneNumber
                                          .toString(),
                                      fontSize: 13,
                                      color: FrontendConfigs.kAuthTextColor,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Items Detail",
                              style: FrontendConfigs.kTitleStyle.copyWith(
                                fontFamily: "Raleway",
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.builder(
                          itemCount: cart.cartItems.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, i) {
                            return ItemsCard(
                              model: cart.cartItems[i],
                            );
                          }),
                      const SizedBox(height: 5),
                      /*
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Coupon Code",
                              style: FrontendConfigs.kTitleStyle.copyWith(
                                fontFamily: "Raleway",
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      /// Coupon Field and button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                text: 'Enter Coupon',
                                onTap: () {
                                  if (cart.hasCouponApplied()) {
                                    getFlushBar(context,
                                        title: "Coupon already applied!");
                                  }
                                },
                                controller: couponController,
                                textInputAction: TextInputAction.done,
                                keyBoardType: TextInputType.text,
                                readOnly: cart.hasCouponApplied(),
                                suffixIcon: cart.hasCouponApplied()
                                    ? const Icon(Icons.check_circle,
                                    color: Colors.green)
                                    : null,
                                hintText: cart.hasCouponApplied()
                                    ? 'Coupon Applied'
                                    : 'Enter Coupon',
                              ),
                            ),
                            const SizedBox(width: 8),
                            AppButton(
                              onPressed: cart.hasCouponApplied()
                                  ? () {}
                                  : () {
                                final retailerData =
                                retailer.getRetailer();
                                if (retailerData == null) {
                                  getFlushBar(context,
                                      title:
                                      "Select a retailer first.");
                                  return;
                                }

                                final cartItems = cart.cartItems;
                                final orderPrice = cart.getSubTotal();

                                if (couponController.text
                                    .trim()
                                    .isEmpty) {
                                  getFlushBar(context,
                                      title: "Enter coupon code");
                                  return;
                                }

                                final products =
                                cartItems.map((item) {
                                  return {
                                    "productId": item.id,
                                    "productType": item.type,
                                    "productValue": item.quantity,
                                  };
                                }).toList();

                                final body = {
                                  "code":
                                  couponController.text.trim(),
                                  "orderPrice": orderPrice,
                                  "retailerId":
                                  retailerData.id.toString(),
                                  "products": products,
                                };

                                log('🎟️ Sending Coupon Apply Request: $body');
                                context
                                    .read<CouponBloc>()
                                    .add(ApplyCouponEvent(body));
                              },
                              btnLabel: cart.hasCouponApplied()
                                  ? "Applied"
                                  : "Apply",
                              btnColor: cart.hasCouponApplied()
                                  ? Colors.grey.shade400
                                  : Colors.black,
                              textColor: cart.hasCouponApplied()
                                  ? Colors.grey.shade700
                                  : Colors.white,
                            )
                          ],
                        ),
                      ),

                      if (cart.hasCouponApplied()) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 18.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border:
                              Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.green.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Coupon Applied",
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        "You saved ${cart.getTotalCouponDiscount().toStringAsFixed(2)} Rs",
                                        style: TextStyle(
                                          color: Colors.green.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    cart.clearCoupons();
                                    couponController.clear();
                                    getFlushBar(context,
                                        title: "Coupon removed");
                                  },
                                  child: Text(
                                    "Remove",
                                    style: TextStyle(
                                      color: Colors.red.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      */

                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 5),
                                Text(
                                  TranslationHelper.getTranslatedText(
                                      "Payment Methods"),
                                  style: FrontendConfigs.kTitleStyle,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Image.asset(
                                          'assets/images/cod.png',
                                          height: 50,
                                          width: 50,
                                        ),
                                        const SizedBox(width: 5),
                                        const Text(
                                          "Cash on Delivery",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                        onPressed: () {},
                                        icon: Icon(
                                          Icons.radio_button_checked,
                                          color: FrontendConfigs.kPrimaryColor,
                                        ))
                                  ],
                                ),
                                FrontendConfigs.appDivider
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              TranslationHelper.getTranslatedText('bill'),
                              style: FrontendConfigs.kTitleStyle,
                            ),
                            const SizedBox(height: 8),

                            if (cart.getTotalBulkDiscount() > 0) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  CustomText(
                                    text: "Subtotal (Original)",
                                    fontSize: 13,
                                    color: FrontendConfigs.kAuthTextColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  CustomText(
                                    text:
                                        "${cart.getSubTotalWithoutAnyDiscount().toStringAsFixed(2)} Rs",
                                    fontSize: 13,
                                    color: FrontendConfigs.kAuthTextColor,
                                    fontWeight: FontWeight.w600,
                                  )
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (cart.getTotalBulkDiscount() > 0) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.local_offer,
                                            color: Colors.green, size: 16),
                                        const SizedBox(width: 4),
                                        CustomText(
                                          text: "Bulk Discount",
                                          fontSize: 12,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ],
                                    ),
                                    CustomText(
                                      text:
                                          "- ${cart.getTotalBulkDiscount().toStringAsFixed(2)} Rs",
                                      fontSize: 12,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              /*
                              if (cart.hasCouponApplied()) ...[
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.confirmation_number,
                                            color: Colors.orange, size: 16),
                                        const SizedBox(width: 4),
                                        CustomText(
                                          text: "Coupon Discount",
                                          fontSize: 12,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ],
                                    ),
                                    CustomText(
                                      text:
                                      "- ${cart.getTotalCouponDiscount().toStringAsFixed(2)} Rs",
                                      fontSize: 12,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              */
                              Divider(
                                  color: Colors.grey.shade300, thickness: 1),
                              const SizedBox(height: 4),
                            ],

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CustomText(
                                  text: "x ${cart.cartItems.length} Items",
                                  fontSize: 12,
                                  color: FrontendConfigs.kAuthTextColor,
                                ),
                                CustomText(
                                  text:
                                      "${cart.getSubTotal().toStringAsFixed(2)} Rs",
                                )
                              ],
                            ),
                            const SizedBox(height: 11),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CustomText(
                                  text: TranslationHelper.getTranslatedText(
                                      'total'),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                                CustomText(
                                  text:
                                      "${cart.getSubTotal().toStringAsFixed(2)} Rs",
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: FrontendConfigs.kPrimaryColor,
                                )
                              ],
                            ),
                            const SizedBox(height: 45),

                            // ── Two action buttons: Add to Drafts + Place
                            // Order — offline mode shows only a full-width
                            // "Add to Drafts" that queues via _placeOrder
                            // instead of the online CreateDraftEvent path.
                            Provider.of<OfflineModeProvider>(context).isOffline
                                ? SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _isPlacingOrder
                                          ? null
                                          : () => _placeOrder(
                                              forceOfflineQueue: true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        "Add to Drafts",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                : Row(
                              children: [
                                // Add to Drafts
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        if (retailer.getRetailer() == null) {
                                          getFlushBar(context,
                                              title:
                                                  "Kindly select retailer in order to proceed.");
                                          return;
                                        }
                                        if (user.getSalesUserDetails()?.user == null) {
                                          getFlushBar(context,
                                              title:
                                                  "Session expired. Please sign in again.");
                                          return;
                                        }
                                        final selectedRetailer =
                                            retailer.getRetailer()!;
                                        final userDetails =
                                            user.getSalesUserDetails()!.user!;
                                        final shippingAddress =
                                            _resolveShippingAddress(
                                                selectedRetailer);

                                        BlocProvider.of<OrderBloc>(context).add(
                                          CreateDraftEvent(CreateOrderModel(
                                            retailerUser:
                                                selectedRetailer.id.toString(),
                                            saleUser: userDetails.id.toString(),
                                            orderType: selectedRetailer
                                                        .customerType
                                                        .toLowerCase() ==
                                                    'distributor'
                                                ? 'company'
                                                : 'market_booking',
                                            phoneNumber: (selectedRetailer
                                                            .phoneNumber ==
                                                        null ||
                                                    selectedRetailer
                                                        .phoneNumber!.isEmpty)
                                                ? "N/A"
                                                : selectedRetailer.phoneNumber!,
                                            city: userDetails.zone.toString(),
                                            paymentType: "cod",
                                            couponCode:
                                                couponController.text.trim(),
                                            shippingAddress: shippingAddress,
                                            status: "Draft",
                                            bulkDiscount:
                                                cart.getTotalBulkDiscount() > 0
                                                    ? cart
                                                        .getTotalBulkDiscount()
                                                        .toDouble()
                                                    : null,
                                            couponDiscount: cart
                                                    .hasCouponApplied()
                                                ? cart
                                                    .getTotalCouponDiscount()
                                                    .toDouble()
                                                : null,
                                            items: cart.cartItems.map((e) {
                                              final totalFinalPrice = cart
                                                  .calculateItemFinalPrice(e);
                                              final totalOriginalPrice =
                                                  cart.getItemOriginalPrice(e);
                                              num finalPiecePrice;
                                              num originalPiecePrice;
                                              if (e.type.toLowerCase() ==
                                                  "ctn") {
                                                int cartonSize = e
                                                        .productDetails
                                                        .cortanSize ??
                                                    1;
                                                int totalPieces =
                                                    e.quantity * cartonSize;
                                                finalPiecePrice =
                                                    totalFinalPrice /
                                                        totalPieces;
                                                originalPiecePrice =
                                                    totalOriginalPrice /
                                                        totalPieces;
                                              } else {
                                                finalPiecePrice =
                                                    totalFinalPrice /
                                                        e.quantity;
                                                originalPiecePrice =
                                                    totalOriginalPrice /
                                                        e.quantity;
                                              }
                                              return OrderItem(
                                                productId: e.productDetails.id,
                                                quantity: e.quantity,
                                                cartonSize:
                                                    e.productDetails.cortanSize,
                                                type: e.type,
                                                price: originalPiecePrice,
                                                discountedPrice:
                                                    finalPiecePrice,
                                              );
                                            }).toList(),
                                          )),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                            color:
                                                FrontendConfigs.kPrimaryColor),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        "Add to Drafts",
                                        style: TextStyle(
                                          color: FrontendConfigs.kPrimaryColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Place Order
                                Expanded(
                                  child: AppButton(
                                    onPressed: () async {
                                      if (_isPlacingOrder) return;
                                      setState(() => _isPlacingOrder = true);
                                      try {
                                      final visitProvider =
                                          Provider.of<VisitProvider>(context,
                                              listen: false);

                                      if (visitProvider.isVisitAutoLogged) {
                                        getFlushBar(context,
                                            title:
                                                "Cannot place order. You moved away from the location.");
                                        return;
                                      }

                                      if (retailer.getRetailer() == null) {
                                        getFlushBar(context,
                                            title:
                                                "Kindly select retailer in order to proceed.");
                                        return;
                                      }

                                      if (user.getSalesUserDetails()?.user == null) {
                                        getFlushBar(context,
                                            title:
                                                "Session expired. Please sign in again.");
                                        return;
                                      }

                                      // ── reverse geocode from retailer lat/lng ──
                                      String shippingAddress =
                                          _resolveShippingAddress(
                                              retailer.getRetailer()!);
                                      final rLat = retailer.getRetailer()!.lat;
                                      final rLng = retailer.getRetailer()!.lng;
                                      if (rLat != null && rLng != null) {
                                        try {
                                          final placemarks =
                                              await placemarkFromCoordinates(
                                                  rLat.toDouble(),
                                                  rLng.toDouble());
                                          if (placemarks.isNotEmpty) {
                                            final p = placemarks.first;
                                            final parts = [
                                              p.name,
                                              p.street,
                                              p.subLocality,
                                              p.locality,
                                              p.administrativeArea,
                                            ]
                                                .where((s) =>
                                                    s != null && s.isNotEmpty)
                                                .toList();
                                            final geocoded = parts.join(', ');
                                            if (geocoded.isNotEmpty) {
                                              shippingAddress = geocoded;
                                            }
                                            log("📍 Geocoded shipping address: $shippingAddress");
                                          }
                                        } catch (e) {
                                          log("⚠️ Geocoding failed, using fallback: $e");
                                        }
                                      }

                                      final userDetails =
                                          user.getSalesUserDetails()!.user!;
                                      final selectedRetailer =
                                          retailer.getRetailer()!;
                                      final locationProvider =
                                          Provider.of<LocationProvider>(context,
                                              listen: false);

                                      final startVisit =
                                          await visitProvider.getStartVisit();
                                      final visitLocation =
                                          visitProvider.visitLocation;

                                      if (startVisit != null &&
                                          visitLocation != null) {
                                        if (visitProvider.isNewShop) {
                                          AppLogger.debug(
                                              "🏪 New shop - logging visit without distance check");

                                          final visit = VisitModel(
                                              retailerId: selectedRetailer.id
                                                  .toString(),
                                              salesPersonId:
                                                  userDetails.id.toString(),
                                              shopName:
                                                  selectedRetailer.shopName ??
                                                      '',
                                              retailerEmail: '',
                                              retailerImage:
                                                  selectedRetailer.image ?? '',
                                              startTime:
                                                  startVisit.toIso8601String(),
                                              endTime: DateTime.now()
                                                  .toIso8601String(),
                                              date: DateTime.now()
                                                  .toString()
                                                  .split(' ')[0],
                                              image: "");

                                          context
                                              .read<VisitBloc>()
                                              .add(AddVisitEvent(visit));
                                        } else {
                                          final currentLocation =
                                              locationProvider.getLatLng();

                                          if (currentLocation == null) {
                                            getFlushBar(context,
                                                title:
                                                    "Current location not available");
                                            return;
                                          }

                                          final hasMovedAway = visitProvider
                                              .hasMovedBeyondThreshold(
                                                  currentLocation,
                                                  thresholdMeters: 20);

                                          final visit = VisitModel(
                                              retailerId: selectedRetailer.id
                                                  .toString(),
                                              salesPersonId:
                                                  userDetails.id.toString(),
                                              shopName:
                                                  selectedRetailer.shopName ??
                                                      '',
                                              retailerEmail: '',
                                              retailerImage:
                                                  selectedRetailer.image ?? '',
                                              startTime:
                                                  startVisit.toIso8601String(),
                                              endTime: DateTime.now()
                                                  .toIso8601String(),
                                              date: DateTime.now()
                                                  .toString()
                                                  .split(' ')[0],
                                              image: visitProvider.visitImage ??
                                                  "");

                                          if (hasMovedAway) {
                                            context
                                                .read<VisitBloc>()
                                                .add(AddVisitEvent(visit));
                                            await visitProvider
                                                .clearVisitData();
                                            getFlushBar(context,
                                                title:
                                                    "Visit logged. You moved away from the location. Order not placed.");
                                            Navigator.pop(context);
                                            return;
                                          }

                                          context
                                              .read<VisitBloc>()
                                              .add(AddVisitEvent(visit));
                                        }
                                      }

                                      final couponCode =
                                          cart.hasCouponApplied() &&
                                                  couponController.text
                                                      .trim()
                                                      .isNotEmpty
                                              ? couponController.text.trim()
                                              : "";

                                      final orderModel = CreateOrderModel(
                                        retailerUser:
                                            selectedRetailer.id.toString(),
                                        saleUser: userDetails.id.toString(),
                                        orderType: selectedRetailer.customerType
                                                    .toLowerCase() ==
                                                'distributor'
                                            ? 'company'
                                            : 'market_booking',
                                        phoneNumber:
                                            (selectedRetailer.phoneNumber ==
                                                        null ||
                                                    selectedRetailer
                                                        .phoneNumber!.isEmpty)
                                                ? "N/A"
                                                : selectedRetailer.phoneNumber!,
                                        city: userDetails.zone.toString(),
                                        paymentType: "cod",
                                        couponCode: couponCode,
                                        shippingAddress: shippingAddress,
                                        bulkDiscount:
                                            cart.getTotalBulkDiscount() > 0
                                                ? cart
                                                    .getTotalBulkDiscount()
                                                    .toDouble()
                                                : null,
                                        couponDiscount: cart.hasCouponApplied()
                                            ? cart
                                                .getTotalCouponDiscount()
                                                .toDouble()
                                            : null,
                                        items: cart.cartItems.map((e) {
                                          final totalFinalPrice =
                                              cart.calculateItemFinalPrice(e);
                                          final totalOriginalPrice =
                                              cart.getItemOriginalPrice(e);

                                          num finalPiecePrice;
                                          num originalPiecePrice;

                                          if (e.type.toLowerCase() == "ctn") {
                                            int cartonSize =
                                                e.productDetails.cortanSize ??
                                                    1;
                                            int totalPieces =
                                                e.quantity * cartonSize;
                                            finalPiecePrice =
                                                totalFinalPrice / totalPieces;
                                            originalPiecePrice =
                                                totalOriginalPrice /
                                                    totalPieces;
                                          } else {
                                            finalPiecePrice =
                                                totalFinalPrice / e.quantity;
                                            originalPiecePrice =
                                                totalOriginalPrice / e.quantity;
                                          }

                                          return OrderItem(
                                            productId: e.productDetails.id,
                                            quantity: e.quantity,
                                            cartonSize:
                                                e.productDetails.cortanSize,
                                            type: e.type,
                                            price: originalPiecePrice,
                                            discountedPrice: finalPiecePrice,
                                          );
                                        }).toList(),
                                      );

                                      final itemInfo = cart.cartItems
                                          .map((e) => PendingSyncItemInfo(
                                                productName: e.name,
                                                productImage: e.image,
                                              ))
                                          .toList();

                                      // ── Online/offline branch ──
                                      // Try a real reachability check (not just
                                      // OS-level connectivity) before deciding.
                                      final isOnline =
                                          await InternetConnectivityHelper
                                              .checkConnectivityFast();

                                      if (isOnline) {
                                        _lastAttemptedOrder = PendingSyncOrder(
                                          localId: const Uuid().v4(),
                                          model: orderModel,
                                          customerName:
                                              selectedRetailer.shopName ??
                                                  selectedRetailer.name ??
                                                  'Customer',
                                          total: cart.getSubTotal().toDouble(),
                                          createdAt: DateTime.now(),
                                          itemInfo: itemInfo,
                                        );
                                        BlocProvider.of<OrderBloc>(context)
                                            .add(CreateOrderEvent(orderModel));
                                      } else {
                                        // No internet — queue locally instead of
                                        // calling the API. The order still
                                        // "punches" from the salesperson's point
                                        // of view; it just isn't on the server yet.
                                        await PendingSyncService.add(
                                          PendingSyncOrder(
                                            localId: const Uuid().v4(),
                                            model: orderModel,
                                            customerName:
                                                selectedRetailer.shopName ??
                                                    selectedRetailer.name ??
                                                    'Customer',
                                            total:
                                                cart.getSubTotal().toDouble(),
                                            createdAt: DateTime.now(),
                                            itemInfo: itemInfo,
                                          ),
                                        );
                                        if (context.mounted) {
                                          cart.emptyCart();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const OrderPlacedView()),
                                          );
                                        }
                                      }

                                      await visitProvider.clearVisitData();
                                      } finally {
                                        if (mounted) {
                                          setState(() => _isPlacingOrder = false);
                                        }
                                      }
                                    },
                                    btnLabel:
                                        TranslationHelper.getTranslatedText(
                                            'place_order'),
                                    btnColor: Colors.black,
                                    height: 48,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
