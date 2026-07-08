import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/infrastructure/model/add_recovery.dart';
import 'package:sm_networking/infrastructure/services/order_booker_activity.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';

/// Shown for the `warehouseManager` role (reached from the "Orderbookers
/// Recoveries" tile). Lists market recoveries across ALL order bookers
/// under this TSM by default; the "Orderbookers" dropdown at the top lets
/// the user narrow down to one specific order booker.
///
/// Both the "all" and "single" cases hit the same paginated endpoint —
/// `payment/tsm/{tsmId}/market-recovery` — just with or without
/// `orderBookerId`. Replaces the old flow of picking an order booker first
/// and then choosing "Market Recoveries" from an actions screen.
class OrderBookerRecoveriesView extends StatefulWidget {
  const OrderBookerRecoveriesView({super.key});

  @override
  State<OrderBookerRecoveriesView> createState() =>
      _OrderBookerRecoveriesViewState();
}

class _OrderBookerRecoveriesViewState
    extends State<OrderBookerRecoveriesView> {
  static const int _pageSize = 10;

  final ScrollController _scrollController = ScrollController();

  /// null = "All Orderbookers"
  String? _selectedOrderBookerId;

  /// Order bookers under this TSM, straight off UserProvider (same source
  /// used elsewhere in the app — already scoped to the logged-in TSM).
  List<dynamic> _orderBookers = [];

  final List<RecoveryModel> _items = [];
  int _page = 1;
  int _totalPages = 1;
  int _total = 0;
  num _totalAmount = 0;

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFirstPage());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || _isInitialLoading) return;
    if (_page >= _totalPages) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage() async {
    final details = context.read<UserProvider>().getSalesUserDetails();
    _orderBookers = details?.orderBookers ?? [];

    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
    });
    await _fetch(page: 1, replace: true);
    if (mounted) setState(() => _isInitialLoading = false);
  }

  Future<void> _refresh() async {
    await _fetch(page: 1, replace: true);
  }

  Future<void> _loadNextPage() async {
    setState(() => _isLoadingMore = true);
    await _fetch(page: _page + 1, replace: false);
    if (mounted) setState(() => _isLoadingMore = false);
  }

  Future<void> _fetch({required int page, required bool replace}) async {
    final details = context.read<UserProvider>().getSalesUserDetails();
    final tsmId = details?.user?.id ?? '';
    final token = details?.token ?? '';

    if (tsmId.isEmpty || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Session expired or not logged in. Please sign in again.';
        if (replace) _items.clear();
      });
      return;
    }

    final result = await OrderBookerActivityRepositoryImp().getAllMarketRecoveries(
      tsmId: tsmId,
      orderBookerId: _selectedOrderBookerId,
      page: page,
      limit: _pageSize,
      token: token,
    );

    if (!mounted) return;

    result.fold(
          (l) {
        setState(() {
          _errorMessage = l.error.toString();
          if (replace) _items.clear();
        });
      },
          (r) {
        setState(() {
          _errorMessage = null;
          if (replace) _items.clear();
          _items.addAll(r.data);
          _page = r.page;
          _totalPages = r.totalPages;
          _total = r.total;
          _totalAmount = r.totalAmount;
        });
      },
    );
  }

  void _onOrderBookerChanged(String? id) {
    if (id == _selectedOrderBookerId) return;
    setState(() {
      _selectedOrderBookerId = id;
      _items.clear();
      _page = 1;
      _totalPages = 1;
      _isInitialLoading = true;
    });
    _fetch(page: 1, replace: true).then((_) {
      if (mounted) setState(() => _isInitialLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context,
          text: 'Orderbookers Recoveries', showText: true),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: _buildFilterDropdown(),
            ),
            if (!_isInitialLoading && (_total > 0 || _totalAmount > 0))
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: _buildSummaryRow(),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _isInitialLoading
                  ? const Center(child: ProcessingWidget())
                  : RefreshIndicator(
                onRefresh: _refresh,
                child: _buildList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: FrontendConfigs.kTextFieldColor,
        borderRadius: FrontendConfigs.kAppBorder,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: _selectedOrderBookerId,
          hint: const Text('Orderbookers'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All Orderbookers'),
            ),
            ..._orderBookers.map((ob) {
              final id = (ob.id ?? ob.salesId ?? '').toString();
              final name = (ob.name ?? 'Unnamed order booker').toString();
              return DropdownMenuItem<String?>(
                value: id,
                child: Text(name, overflow: TextOverflow.ellipsis),
              );
            }),
          ],
          onChanged: _onOrderBookerChanged,
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$_total recoveries',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        Text(
          '${_totalAmount.toStringAsFixed(0)} Rs',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: FrontendConfigs.kPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    if (_errorMessage != null && _items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_errorMessage!, textAlign: TextAlign.center),
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: Text('No market recoveries yet')),
        ],
      );
    }

    final showMoreLoader = _page < _totalPages;

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: _items.length + (showMoreLoader ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        if (i >= _items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final m = _items[i];
        return _RecoveryCard(
          recovery: m,
          // Only show whose recovery it is when we're already looking at
          // a mix of order bookers (i.e. "All" is selected).
          showOrderBooker: _selectedOrderBookerId == null,
        );
      },
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  final RecoveryModel recovery;
  final bool showOrderBooker;

  const _RecoveryCard({required this.recovery, required this.showOrderBooker});

  @override
  Widget build(BuildContext context) {
    final m = recovery;
    return Container(
      decoration: BoxDecoration(
        borderRadius: FrontendConfigs.kAppBorder,
        color: FrontendConfigs.kTextFieldColor,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  m.srNo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                '${m.amount.toStringAsFixed(0)} Rs',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: FrontendConfigs.kPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            m.distributionName,
            style: const TextStyle(fontSize: 13),
          ),
          if (showOrderBooker && m.orderBookerName.isNotEmpty)
            Text(
              'Orderbooker: ${m.orderBookerName}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          if (m.zoneName.isNotEmpty)
            Text(
              'Zone: ${m.zoneName}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          if (m.townName.isNotEmpty)
            Text(
              'Town: ${m.townName}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          if (m.date != null && m.date!.isNotEmpty)
            Text(
              'Date: ${m.date}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          const SizedBox(height: 4),
          Text(
            '${m.bankName} · ${m.paymentMode}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}