import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../application/user_provider.dart';
import '../../../../configurations/frontend_configs.dart';
import '../../../../infrastructure/model/order.dart';
import '../../../../infrastructure/services/order.dart';
import '../../../../injection_container.dart';
import '../../../elements/custom_text.dart';
import '../../../elements/processing_widget.dart';
import '../no_data_found_view.dart';
import '../order_details/order_details_view.dart';
import '../widgets/order_card.dart';

class OrderBody extends StatefulWidget {
  const OrderBody({super.key});

  @override
  State<OrderBody> createState() => _OrderBodyState();
}

class _OrderBodyState extends State<OrderBody> {
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  String? _error;
  List<OrderModel> _orders = [];

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final userId = Provider.of<UserProvider>(context, listen: false)
        .getSalesUserDetails()!
        .user!
        .id
        .toString();
    final repo = sl<OrderRepositoryImp>();

    // The backend has no single "all statuses" endpoint, so pull every
    // status bucket that used to be its own tab and merge them here.
    final results = await Future.wait([
      repo.getPendingOrders(userId),
      repo.getProcessedOrders(userId),
      repo.getCompletedOrders(userId),
      repo.getCancelledOrders(userId),
    ]);

    final merged = <OrderModel>[];
    String? errorMsg;
    for (final result in results) {
      result.fold(
        (l) => errorMsg ??= l.error.toString(),
        (r) => merged.addAll(r.data ?? []),
      );
    }

    final filtered = merged.where((o) {
      final created = o.createdAt?.toLocal();
      if (created == null) return false;
      return created.year == _selectedDate.year &&
          created.month == _selectedDate.month &&
          created.day == _selectedDate.day;
    }).toList()
      ..sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

    if (!mounted) return;
    setState(() {
      _loading = false;
      _orders = filtered;
      // Only surface an error if every bucket failed; a partial failure
      // still shows whatever orders did come back.
      _error = merged.isEmpty ? errorMsg : null;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FrontendConfigs.appDivider,
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: _isToday
                      ? "Today's Orders"
                      : DateFormat('d MMM yyyy').format(_selectedDate),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                Row(
                  children: [
                    if (!_isToday)
                      IconButton(
                        tooltip: 'Back to today',
                        icon: Icon(Icons.today_outlined,
                            color: FrontendConfigs.kAuthTextColor),
                        onPressed: () {
                          setState(() => _selectedDate = DateTime.now());
                          _loadOrders();
                        },
                      ),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _pickDate,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month_outlined,
                                size: 18, color: FrontendConfigs.kPrimaryColor),
                            const SizedBox(width: 6),
                            CustomText(
                              text: 'Filter by date',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: FrontendConfigs.kPrimaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: ProcessingWidget());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_orders.isEmpty) {
      return const NoDataFoundView();
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        itemCount: _orders.length,
        itemBuilder: (context, i) {
          final order = _orders[i];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailsView(model: order),
                ),
              ).then((val) {
                if (val == true) _loadOrders();
              });
            },
            child: OrderCard(status: order.status ?? 'Pending', model: order),
          );
        },
      ),
    );
  }
}
