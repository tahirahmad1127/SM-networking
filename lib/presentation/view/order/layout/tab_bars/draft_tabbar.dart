// lib/presentation/view/order/layout/tab_bars/drafts_tab_bar.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../application/cart_provider.dart';
import '../../../../../application/order_bloc/order_bloc.dart';
import '../../../../../infrastructure/model/create_order.dart';
import '../../order_placed_view.dart';
import '../../../../../application/user_provider.dart';
import '../../../../../configurations/frontend_configs.dart';
import '../../../../../infrastructure/model/order.dart';
import '../../../../../infrastructure/services/order.dart';
import '../../../../../injection_container.dart';
import '../../../../elements/custom_text.dart';
import '../../../../elements/flush_bar.dart';
import '../../../../elements/processing_widget.dart';

class DraftsTabBar extends StatefulWidget {
  const DraftsTabBar({super.key});

  @override
  State<DraftsTabBar> createState() => DraftsTabBarState();
}

class DraftsTabBarState extends State<DraftsTabBar> {
  List<OrderModel> _drafts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  /// Call this to force a fresh reload from outside
  void reload() => _loadDrafts();


  Future<void> _loadDrafts() async {
    final user = Provider.of<UserProvider>(context, listen: false);
    final tsmId = user.getSalesUserDetails()?.user?.id ?? '';
    if (tsmId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'User not found.';
      });
      return;
    }

    final result = await sl<OrderRepositoryImp>().getDrafts(tsmId);
    result.fold(
          (l) {
        if (mounted) setState(() {
          _loading = false;
          _error = l.error.toString();
        });
      },
          (r) {
        if (mounted) setState(() {
          _loading = false;
          _drafts = r.data ?? [];
        });
      },
    );
  }

  Future<void> _placeOrderFromDraft(BuildContext context, OrderModel draft) async {
    final items = draft.items ?? [];
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft has no items.')));
      return;
    }

    // Build CreateOrderModel from draft — reuse same fields
    final model = CreateOrderModel(
      retailerUser: draft.warehouseManager?.id ?? '',
      saleUser: draft.salesPerson?.id ?? '',
      phoneNumber: draft.phoneNumber ?? 'N/A',
      city: draft.warehouseManager?.id ?? '',
      paymentType: draft.paymentType ?? 'cod',
      couponCode: draft.coupon ?? '',
      shippingAddress: draft.shippingAddress ?? '',
      bulkDiscount: draft.bulkDiscount?.toDouble(),
      couponDiscount: draft.couponDiscount?.toDouble(),
      items: items.map((e) => OrderItem(
        productId: e.productId?.id,
        quantity: e.quantity,
        price: e.price,
        discountedPrice: e.discountedPrice,
        type: e.type,
      )).toList(),
    );

    // Use a temporary OrderBloc to place the order
    // Navigate to checkout-like flow — simplest: push OrderPlacedView on success
    final repo = sl<OrderRepositoryImp>();
    final result = await repo.createOrder(model);
    result.fold(
          (l) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed: ${l.error}')));
        }
      },
          (r) {
        // Remove from list
        setState(() => _drafts.removeWhere((d) => d.id == draft.id));
        if (context.mounted) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const OrderPlacedView()));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: ProcessingWidget());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 8),
            CustomText(text: _error!, color: Colors.red.shade400),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() { _loading = true; _error = null; });
                _loadDrafts();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_drafts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.drafts_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            CustomText(
              text: 'No draft orders yet.',
              color: Colors.grey.shade400,
              fontSize: 15,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() { _loading = true; _error = null; _drafts = []; });
        await _loadDrafts();
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _drafts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) => _DraftCard(
          draft: _drafts[i],
          onDeleted: () => setState(() => _drafts.removeAt(i)),
          onPlaceOrder: (context) => _placeOrderFromDraft(context, _drafts[i]),
        ),
      ),
    );
  }
}

// ── Draft Card ────────────────────────────────────────────────────────────────

class _DraftCard extends StatelessWidget {
  final OrderModel draft;
  final VoidCallback onDeleted;
  final void Function(BuildContext) onPlaceOrder;

  const _DraftCard({
    required this.draft,
    required this.onDeleted,
    required this.onPlaceOrder,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = draft.createdAt != null
        ? DateFormat('MMM d, yyyy  hh:mm a').format(draft.createdAt!)
        : '';
    final items = draft.items ?? [];
    final total = draft.total ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: draft.warehouseManager?.name ??
                            draft.shippingAddress ??
                            'Unknown Customer',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: const Color(0xFF2D3142),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (dateStr.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        CustomText(
                          text: dateStr,
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    'DRAFT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Divider(color: Colors.grey.shade100, height: 1),
            const SizedBox(height: 10),

            // ── Items ────────────────────────────────────────────────
            CustomText(
              text: '${items.length} item${items.length == 1 ? '' : 's'}',
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 4),
            ...items.take(2).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Icon(Icons.circle,
                      size: 5, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Expanded(
                    child: CustomText(
                      text:
                      '${item.productId?.englishTitle ?? 'Product'}  ×${item.quantity} ${(item.type ?? '').toUpperCase()}',
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
            if (items.length > 2)
              CustomText(
                text: '+${items.length - 2} more',
                fontSize: 11,
                color: Colors.grey.shade400,
              ),

            const SizedBox(height: 10),
            Divider(color: Colors.grey.shade100, height: 1),
            const SizedBox(height: 10),

            // ── Total + actions ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                        text: 'Total',
                        fontSize: 11,
                        color: Colors.grey.shade500),
                    CustomText(
                      text: '${total.toStringAsFixed(2)} Rs',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: FrontendConfigs.kPrimaryColor,
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Delete
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Draft'),
                            content: const Text(
                                'Are you sure you want to delete this draft?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text('Delete',
                                    style: TextStyle(
                                        color: Colors.red.shade600)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) onDeleted();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      icon: Icon(Icons.delete_outline,
                          size: 16, color: Colors.red.shade600),
                      label: Text('Delete',
                          style: TextStyle(
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    // Place Order
                    ElevatedButton.icon(
                      onPressed: () => onPlaceOrder(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FrontendConfigs.kPrimaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Place Order',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}