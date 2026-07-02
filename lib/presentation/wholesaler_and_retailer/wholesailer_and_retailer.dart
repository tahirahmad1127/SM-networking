import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/application/wholesaler_retailer_provider.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/infrastructure/model/wholesaler_retailer_model.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';
import 'package:sm_networking/presentation/elements/flush_bar.dart';

import 'add_wholesaler_and_retailer.dart';

enum WholesalerRetailerType { wholesaler, retailer }

// ─── Listing Screen ───────────────────────────────────────────────────────────

class WholesalerRetailerListView extends StatefulWidget {
  final WholesalerRetailerType type;

  const WholesalerRetailerListView({super.key, required this.type});

  @override
  State<WholesalerRetailerListView> createState() =>
      _WholesalerRetailerListViewState();
}

class _WholesalerRetailerListViewState
    extends State<WholesalerRetailerListView> {
  @override
  void initState() {
    super.initState();
    // Load from API on first visit
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final userDetails = Provider.of<UserProvider>(context, listen: false)
        .getSalesUserDetails();
    final token = userDetails?.token ?? '';
    final user = userDetails?.user;
    final role = userDetails?.role ?? '';

    // TSM  → filter by their zone (user.zone is a plain String ID)
    // Order Booker → filter by their zone AND first town
    // Other roles → no additional filter (show all)
    String? zoneId;
    String? townId;

    if (role.toLowerCase().contains('tsm') ||
        role.toLowerCase().contains('warehouse')) {
      zoneId = user?.zone; // single String ID
    } else if (role.toLowerCase().contains('order') ||
        role.toLowerCase().contains('booker') ||
        role.toLowerCase().contains('salesman')) {
      zoneId = user?.zone;
      townId = (user?.town != null && user!.town!.isNotEmpty)
          ? user.town!.first
          : null;
    }

    final provider =
    Provider.of<WholesalerRetailerProvider>(context, listen: false);

    if (widget.type == WholesalerRetailerType.wholesaler) {
      provider.loadWholesalers(token: token, zoneId: zoneId, townId: townId);
    } else {
      provider.loadRetailers(token: token, zoneId: zoneId, townId: townId);
    }
  }

  String get _title =>
      widget.type == WholesalerRetailerType.wholesaler
          ? 'Wholesalers'
          : 'Retailers';

  String get _singularLabel =>
      widget.type == WholesalerRetailerType.wholesaler
          ? 'Wholesaler'
          : 'Retailer';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context, text: _title, showText: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AddWholesalerRetailerView(type: widget.type),
            ),
          );
          // Add screen already popped — safe to show flushbar here because
          // the Navigator is no longer mid-transition.
          if (added == true && mounted) {
            getFlushBar(context, title: '$_singularLabel added successfully!');
            _load();
          }
        },
        backgroundColor: FrontendConfigs.kPrimaryColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Consumer<WholesalerRetailerProvider>(
          builder: (context, provider, _) {
            final isLoading =
            widget.type == WholesalerRetailerType.wholesaler
                ? provider.loadingWholesalers
                : provider.loadingRetailers;

            final error =
            widget.type == WholesalerRetailerType.wholesaler
                ? provider.wholesalerError
                : provider.retailerError;

            final entries =
            widget.type == WholesalerRetailerType.wholesaler
                ? provider.wholesalers
                : provider.retailers;

            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (error != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: Colors.red.shade300),
                    const SizedBox(height: 12),
                    CustomText(
                      text: 'Failed to load $_title',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (entries.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async => _load(),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _EntryCard(entry: entries[i]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.type == WholesalerRetailerType.wholesaler
                ? Icons.store_outlined
                : Icons.storefront_outlined,
            size: 72,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          CustomText(
            text: 'No $_title yet',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 6),
          CustomText(
            text: 'Tap + to add a new $_singularLabel',
            fontSize: 13,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }
}

// ─── Entry Card ───────────────────────────────────────────────────────────────

class _EntryCard extends StatelessWidget {
  final WholesalerRetailerModel entry;

  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: FrontendConfigs.kAppBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // ── Avatar ──────────────────────────────────────────────────
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: FrontendConfigs.kPrimaryColor.withOpacity(0.1),
              ),
              child: entry.pic != null && entry.pic!.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: ExtendedImage.network(
                  entry.pic!,
                  height: 50,
                  width: 50,
                  fit: BoxFit.cover,
                  cache: true,
                  loadStateChanged: (state) {
                    if (state.extendedImageLoadState ==
                        LoadState.loading ||
                        state.extendedImageLoadState ==
                            LoadState.failed) {
                      return Icon(Icons.store,
                          color: FrontendConfigs.kPrimaryColor,
                          size: 26);
                    }
                    return state.completedWidget;
                  },
                ),
              )
                  : Icon(Icons.store,
                  color: FrontendConfigs.kPrimaryColor, size: 26),
            ),
            const SizedBox(width: 12),

            // ── Details ──────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: FrontendConfigs.kTitleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  CustomText(
                    text: entry.contacts,
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 2),
                  if (entry.fullAddressDisplay.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.home_outlined,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Expanded(
                          child: CustomText(
                            text: entry.fullAddressDisplay,
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],
                  if (entry.zoneName.isNotEmpty || entry.townName.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Expanded(
                          child: CustomText(
                            text: [entry.zoneName, entry.townName]
                                .where((s) => s.isNotEmpty)
                                .join(' · '),
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}