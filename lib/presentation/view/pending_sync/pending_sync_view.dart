// lib/presentation/view/pending_sync/pending_sync_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../application/pending_recovery_provider.dart';
import '../../../application/pending_sync_provider.dart';
import '../../../configurations/frontend_configs.dart';
import '../../../infrastructure/model/pending_recovery_order.dart';
import '../../../infrastructure/model/pending_sync_order.dart';
import '../../elements/custom_appbar.dart';
import '../../elements/custom_text.dart';
import '../../elements/flush_bar.dart';
import '../../elements/navigation_dialog.dart';
import 'pending_sync_order_details_view.dart';

class PendingSyncView extends StatefulWidget {
  const PendingSyncView({super.key});

  @override
  State<PendingSyncView> createState() => _PendingSyncViewState();
}

class _PendingSyncViewState extends State<PendingSyncView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Provider.of<PendingSyncProvider>(context, listen: false).load();
    Provider.of<PendingRecoveryProvider>(context, listen: false).load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: FrontendConfigs.kPrimaryColor,
            unselectedLabelColor: FrontendConfigs.kAuthTextColor,
            indicatorColor: FrontendConfigs.kPrimaryColor,
            tabs: const [
              Tab(text: "Orders"),
              Tab(text: "Recoveries"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _PendingOrdersTab(),
                _PendingRecoveriesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Orders tab
// ─────────────────────────────────────────────────────────────────────────

class _PendingOrdersTab extends StatelessWidget {
  const _PendingOrdersTab();

  Future<void> _syncOne(BuildContext context, String localId) async {
    final provider = Provider.of<PendingSyncProvider>(context, listen: false);
    final ok = await provider.syncOne(localId);
    if (!context.mounted) return;
    getFlushBar(context,
        title: ok ? "Order synced successfully" : "Sync failed — still queued");
  }

  Future<void> _syncAll(BuildContext context) async {
    final provider = Provider.of<PendingSyncProvider>(context, listen: false);
    final result = await provider.syncAll();
    final succeeded = result.succeeded;
    final failed = result.failed;
    if (!context.mounted) return;
    if (failed == 0) {
      getFlushBar(context, title: "All $succeeded order(s) synced successfully");
    } else {
      getFlushBar(context,
          title: "$succeeded synced, $failed failed — still queued for retry");
    }
  }

  Future<void> _deleteOne(BuildContext context, PendingSyncOrder order) async {
    showNavigationDialog(
      context,
      message:
      "Delete this pending order for ${order.customerName}? This cannot be undone.",
      buttonText: "Delete",
      navigation: () async {
        Navigator.pop(context);
        await Provider.of<PendingSyncProvider>(context, listen: false)
            .deleteOne(order.localId);
        if (context.mounted) {
          getFlushBar(context, title: "Pending order deleted");
        }
      },
      secondButtonText: "Cancel",
      showSecondButton: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PendingSyncProvider>(
      builder: (context, provider, _) {
        final orders = provider.orders;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    text: "Pending Orders",
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  CustomText(
                    text: "${orders.length} order(s)",
                    fontSize: 13,
                    color: FrontendConfigs.kAuthTextColor,
                  ),
                ],
              ),
            ),
            if (orders.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: provider.isSyncingAll
                        ? null
                        : () => _syncAll(context),
                    icon: provider.isSyncingAll
                        ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.sync, color: Colors.white),
                    label: Text(
                      provider.isSyncingAll
                          ? "Syncing all..."
                          : "Sync All",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FrontendConfigs.kPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Expanded(
              child: orders.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_done_outlined,
                        size: 64, color: FrontendConfigs.kAuthTextColor),
                    const SizedBox(height: 12),
                    CustomText(
                      text: "Nothing to sync",
                      fontSize: 15,
                      color: FrontendConfigs.kAuthTextColor,
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                itemCount: orders.length,
                itemBuilder: (context, i) {
                  final order = orders[i];
                  final isSyncing = provider.isSyncing(order.localId);

                  return InkWell(
                    borderRadius: FrontendConfigs.kAppBorder,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PendingSyncOrderDetailsView(order: order),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: FrontendConfigs.kTextFieldColor,
                        borderRadius: FrontendConfigs.kAppBorder,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: CustomText(
                                    text: order.customerName,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red, size: 22),
                                  onPressed: isSyncing
                                      ? null
                                      : () => _deleteOne(context, order),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            CustomText(
                              text: DateFormat("d MMM yyyy, h:mm a")
                                  .format(order.createdAt),
                              fontSize: 12,
                              color: FrontendConfigs.kAuthTextColor,
                            ),
                            const SizedBox(height: 4),
                            CustomText(
                              text:
                              "${order.model.items?.length ?? 0} item(s) — "
                                  "${order.total.toStringAsFixed(2)} Rs",
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: FrontendConfigs.kPrimaryColor,
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: isSyncing
                                    ? null
                                    : () => _syncOne(context, order.localId),
                                icon: isSyncing
                                    ? SizedBox(
                                  height: 14,
                                  width: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: FrontendConfigs.kPrimaryColor),
                                )
                                    : Icon(Icons.sync,
                                    size: 16,
                                    color: FrontendConfigs.kPrimaryColor),
                                label: Text(
                                  isSyncing ? "Syncing..." : "Sync this order",
                                  style: TextStyle(
                                      color: FrontendConfigs.kPrimaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: FrontendConfigs.kPrimaryColor),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
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
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Recoveries tab
// ─────────────────────────────────────────────────────────────────────────

class _PendingRecoveriesTab extends StatelessWidget {
  const _PendingRecoveriesTab();

  Future<void> _syncOne(BuildContext context, String localId) async {
    final provider =
        Provider.of<PendingRecoveryProvider>(context, listen: false);
    final ok = await provider.syncOne(localId);
    if (!context.mounted) return;
    getFlushBar(context,
        title:
            ok ? "Recovery synced successfully" : "Sync failed — still queued");
  }

  Future<void> _syncAll(BuildContext context) async {
    final provider =
        Provider.of<PendingRecoveryProvider>(context, listen: false);
    final result = await provider.syncAll();
    final succeeded = result.succeeded;
    final failed = result.failed;
    if (!context.mounted) return;
    if (failed == 0) {
      getFlushBar(context,
          title: "All $succeeded recovery(s) synced successfully");
    } else {
      getFlushBar(context,
          title: "$succeeded synced, $failed failed — still queued for retry");
    }
  }

  Future<void> _deleteOne(
      BuildContext context, PendingRecoveryOrder order) async {
    showNavigationDialog(
      context,
      message:
      "Delete this pending recovery for ${order.model.distributionName}? This cannot be undone.",
      buttonText: "Delete",
      navigation: () async {
        Navigator.pop(context);
        await Provider.of<PendingRecoveryProvider>(context, listen: false)
            .deleteOne(order.localId);
        if (context.mounted) {
          getFlushBar(context, title: "Pending recovery deleted");
        }
      },
      secondButtonText: "Cancel",
      showSecondButton: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PendingRecoveryProvider>(
      builder: (context, provider, _) {
        final orders = provider.orders;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    text: "Pending Recoveries",
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  CustomText(
                    text: "${orders.length} recovery(s)",
                    fontSize: 13,
                    color: FrontendConfigs.kAuthTextColor,
                  ),
                ],
              ),
            ),
            if (orders.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: provider.isSyncingAll
                        ? null
                        : () => _syncAll(context),
                    icon: provider.isSyncingAll
                        ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.sync, color: Colors.white),
                    label: Text(
                      provider.isSyncingAll
                          ? "Syncing all..."
                          : "Sync All",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FrontendConfigs.kPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Expanded(
              child: orders.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_done_outlined,
                        size: 64, color: FrontendConfigs.kAuthTextColor),
                    const SizedBox(height: 12),
                    CustomText(
                      text: "Nothing to sync",
                      fontSize: 15,
                      color: FrontendConfigs.kAuthTextColor,
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                itemCount: orders.length,
                itemBuilder: (context, i) {
                  final order = orders[i];
                  final isSyncing = provider.isSyncing(order.localId);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: FrontendConfigs.kTextFieldColor,
                      borderRadius: FrontendConfigs.kAppBorder,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: CustomText(
                                  text: order.model.distributionName,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red, size: 22),
                                onPressed: isSyncing
                                    ? null
                                    : () => _deleteOne(context, order),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          CustomText(
                            text: DateFormat("d MMM yyyy, h:mm a")
                                .format(order.createdAt),
                            fontSize: 12,
                            color: FrontendConfigs.kAuthTextColor,
                          ),
                          const SizedBox(height: 4),
                          CustomText(
                            text:
                            "${order.model.amount.toStringAsFixed(2)} Rs — ${order.model.paymentMode}",
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: FrontendConfigs.kPrimaryColor,
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: isSyncing
                                  ? null
                                  : () => _syncOne(context, order.localId),
                              icon: isSyncing
                                  ? SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: FrontendConfigs.kPrimaryColor),
                              )
                                  : Icon(Icons.sync,
                                  size: 16,
                                  color: FrontendConfigs.kPrimaryColor),
                              label: Text(
                                isSyncing ? "Syncing..." : "Sync this recovery",
                                style: TextStyle(
                                    color: FrontendConfigs.kPrimaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: FrontendConfigs.kPrimaryColor),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
