// lib/presentation/view/pending_sync/pending_sync_order_details_view.dart
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../configurations/frontend_configs.dart';
import '../../../infrastructure/model/pending_sync_order.dart';
import '../../elements/custom_appbar.dart';
import '../../elements/custom_text.dart';

class PendingSyncOrderDetailsView extends StatelessWidget {
  final PendingSyncOrder order;

  const PendingSyncOrderDetailsView({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final items = order.model.items ?? [];
    final bulkDiscount = order.model.bulkDiscount ?? 0;
    final couponDiscount = order.model.couponDiscount ?? 0;
    final hasAnyDiscount = bulkDiscount > 0 || couponDiscount > 0;

    return Scaffold(
      appBar: customAppBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: "Pending Order Details",
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 14, color: Colors.orange.shade800),
                    const SizedBox(width: 6),
                    CustomText(
                      text: "Not yet synced to server",
                      fontSize: 12,
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Customer / order info card ──
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: FrontendConfigs.kAppBorder,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: "Customer",
                        color: FrontendConfigs.kAuthTextColor,
                        fontSize: 12,
                      ),
                      CustomText(
                        text: order.customerName,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      const SizedBox(height: 12),
                      CustomText(
                        text: "Queued At",
                        color: FrontendConfigs.kAuthTextColor,
                        fontSize: 12,
                      ),
                      CustomText(
                        text: DateFormat("d MMM yyyy, h:mm a")
                            .format(order.createdAt),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      if (order.model.shippingAddress?.isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        CustomText(
                          text: "Address",
                          color: FrontendConfigs.kAuthTextColor,
                          fontSize: 12,
                        ),
                        CustomText(
                          text: order.model.shippingAddress!,
                          fontSize: 14,
                        ),
                      ],
                      if (order.model.phoneNumber?.isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        CustomText(
                          text: "Phone Number",
                          color: FrontendConfigs.kAuthTextColor,
                          fontSize: 12,
                        ),
                        CustomText(
                          text: order.model.phoneNumber!,
                          fontSize: 14,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
              CustomText(
                text: "Items (${items.length})",
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: 10),

              // ── Item list ──
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final item = items[i];
                  final info = i < order.itemInfo.length
                      ? order.itemInfo[i]
                      : null;
                  final displayName = (info?.productName.isNotEmpty == true)
                      ? info!.productName
                      : (item.productId ?? 'Unknown product');
                  final displayImage = info?.productImage ?? '';

                  return Container(
                    decoration: BoxDecoration(
                      color: FrontendConfigs.kTextFieldColor,
                      borderRadius: FrontendConfigs.kAppBorder,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: displayImage.isNotEmpty
                                ? ExtendedImage.network(
                              displayImage,
                              height: 56,
                              width: 56,
                              fit: BoxFit.cover,
                              cache: true,
                            )
                                : Container(
                              height: 56,
                              width: 56,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.inventory_2_outlined,
                                  color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  text: displayName,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 4),
                                Builder(builder: (context) {
                                  final piecePrice =
                                  (item.discountedPrice ?? item.price ?? 0);
                                  final isCarton =
                                      (item.type ?? '').toLowerCase() == 'ctn';
                                  final cartonSize = item.cartonSize ?? 1;
                                  final cartonPrice = piecePrice * cartonSize;

                                  if (isCarton) {
                                    return Wrap(
                                      spacing: 10,
                                      runSpacing: 2,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            CustomText(
                                              text: "Box",
                                              fontSize: 10,
                                              color: FrontendConfigs
                                                  .kAuthTextColor,
                                            ),
                                            CustomText(
                                              text:
                                              "${piecePrice.toStringAsFixed(2)} Rs",
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color:
                                              FrontendConfigs.kPrimaryColor,
                                            ),
                                          ],
                                        ),
                                        Container(
                                          width: 1,
                                          height: 28,
                                          color: Colors.grey.shade300,
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            CustomText(
                                              text: "Ctn",
                                              fontSize: 10,
                                              color: FrontendConfigs
                                                  .kAuthTextColor,
                                            ),
                                            CustomText(
                                              text:
                                              "${cartonPrice.toStringAsFixed(2)} Rs",
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color:
                                              FrontendConfigs.kPrimaryColor,
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  }

                                  return CustomText(
                                    text: "${piecePrice.toStringAsFixed(2)} Rs",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: FrontendConfigs.kPrimaryColor,
                                  );
                                }),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              CustomText(
                                text: "Qty",
                                fontSize: 11,
                                color: FrontendConfigs.kAuthTextColor,
                              ),
                              CustomText(
                                text:
                                "${item.quantity ?? 0} ${(item.type ?? '').toUpperCase()}",
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              // ── Bill summary ──
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: FrontendConfigs.kAppBorder,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasAnyDiscount) ...[
                        if (bulkDiscount > 0)
                          _summaryRow("Bulk Discount",
                              "- ${bulkDiscount.toStringAsFixed(2)} Rs",
                              valueColor: Colors.green),
                        if (couponDiscount > 0)
                          _summaryRow("Coupon Discount",
                              "- ${couponDiscount.toStringAsFixed(2)} Rs",
                              valueColor: Colors.orange),
                        const Divider(),
                      ],
                      _summaryRow(
                        "Total",
                        "${order.total.toStringAsFixed(2)} Rs",
                        labelWeight: FontWeight.w700,
                        valueSize: 16,
                        valueColor: FrontendConfigs.kPrimaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(
      String label,
      String value, {
        FontWeight labelWeight = FontWeight.w500,
        double valueSize = 13,
        Color? valueColor,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(text: label, fontSize: 13, fontWeight: labelWeight),
          CustomText(
            text: value,
            fontSize: valueSize,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ],
      ),
    );
  }
}