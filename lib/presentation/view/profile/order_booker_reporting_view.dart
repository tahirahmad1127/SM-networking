import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/infrastructure/model/tracking.dart';
import 'package:sm_networking/infrastructure/model/user.dart';
import 'package:sm_networking/infrastructure/services/order_booker_activity.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';
import 'package:sm_networking/presentation/view/orderbooker_recoveries_view.dart';
import 'package:sm_networking/presentation/view/profile/layout/widgets/profile_card.dart';
import 'package:sm_networking/presentation/view/profile/sales_view.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderBookersReportingView extends StatelessWidget {
  const OrderBookersReportingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        context,
        text: 'OrderBookers Reporting',
        showText: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              InkWell(
                borderRadius: FrontendConfigs.kAppBorder,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OrderBookerReportSelectionView(),
                    ),
                  );
                },
                child: ProfileCard(lebal: 'Attendance & Tracking'),
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: FrontendConfigs.kAppBorder,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SalesView(),
                    ),
                  );
                },
                child: ProfileCard(lebal: 'Sales'),
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: FrontendConfigs.kAppBorder,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OrderBookerRecoveriesView(),
                    ),
                  );
                },
                child: ProfileCard(lebal: 'Recovery'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderBookerReportSelectionView extends StatefulWidget {
  const OrderBookerReportSelectionView({super.key});

  @override
  State<OrderBookerReportSelectionView> createState() =>
      _OrderBookerReportSelectionViewState();
}

class _OrderBookerReportSelectionViewState
    extends State<OrderBookerReportSelectionView> {
  bool _isLoading = true;
  String? _errorMessage;
  List<OrderBooker> _orderBookers = [];

  @override
  void initState() {
    super.initState();
    _loadOrderBookers();
  }

  Future<void> _loadOrderBookers() async {
    final details = context.read<UserProvider>().getSalesUserDetails();
    final orderBookers = details?.orderBookers ?? [];
    if (orderBookers.isNotEmpty) {
      setState(() {
        _orderBookers = orderBookers;
        _isLoading = false;
      });
      return;
    }

    final tsmId = details?.user?.id ?? '';
    final token = details?.token ?? '';
    if (tsmId.isEmpty || token.isEmpty) {
      setState(() {
        _orderBookers = [];
        _errorMessage = 'Unable to load orderbookers. Please sign in again.';
        _isLoading = false;
      });
      return;
    }

    final result = await OrderBookerActivityRepositoryImp().getOrderBookersForTsm(
      tsmId: tsmId,
      token: token,
    );

    if (!mounted) return;

    result.fold((l) {
      setState(() {
        _orderBookers = [];
        _errorMessage = l.error.toString();
        _isLoading = false;
      });
    }, (r) {
      setState(() {
        _orderBookers = r;
        _errorMessage = null;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        context,
        text: 'Select OrderBooker',
        showText: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: ProcessingWidget())
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_orderBookers.isEmpty) {
      return const Center(child: Text('No orderbookers assigned'));
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      itemCount: _orderBookers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final orderBooker = _orderBookers[index];
        return InkWell(
          borderRadius: FrontendConfigs.kAppBorder,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderBookerReportTabsView(
                  orderBooker: orderBooker,
                ),
              ),
            );
          },
          child: ProfileCard(lebal: orderBooker.name ?? 'Unnamed OrderBooker'),
        );
      },
    );
  }
}

class OrderBookerReportTabsView extends StatefulWidget {
  final OrderBooker orderBooker;

  const OrderBookerReportTabsView({super.key, required this.orderBooker});

  @override
  State<OrderBookerReportTabsView> createState() =>
      _OrderBookerReportTabsViewState();
}

class _OrderBookerReportTabsViewState extends State<OrderBookerReportTabsView>
    with SingleTickerProviderStateMixin {
  // Query-param values expected by the `type=` param on
  // GET warehouse-manager/order-booker-report.
  static const List<String> _tabTypes = [
    'attendance',
    'tracking',
    'visit',
    'productivity',
  ];

  // Display labels for the tabs above (kept separate from _tabTypes since
  // "Visits" reads better than the singular API value "visit").
  static const List<String> _tabLabels = [
    'Attendance',
    'Tracking',
    'Visits',
    'Productivity',
  ];

  late final TabController _tabController;
  int _currentIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Cached raw `data` payload per report type, keyed by _tabTypes value.
  // Avoids refetching every time the user flips back to a tab they already
  // loaded, and lets the Productivity tab reuse the Visits payload (it needs
  // both to build its per-day breakdown — see [_ProductivityTable]).
  final Map<String, dynamic> _cache = {};

  // Bumped on every _fetchReport() call. If the user swipes to another tab
  // before an in-flight fetch resolves (e.g. Visits still loading when they
  // jump to Productivity), the earlier call's completion must NOT be allowed
  // to flip `_isLoading` back to false for a tab it didn't fetch — that was
  // producing a flash of "No <tab> data available" before the real data for
  // the current tab arrived. Only the most recent call's result is applied.
  int _fetchToken = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabTypes.length, vsync: this)
      ..addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchReport());
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      setState(() {
        _currentIndex = _tabController.index;
      });
      _fetchReport();
    }
  }

  Future<void> _fetchReport() async {
    final type = _tabTypes[_currentIndex];
    final needsVisitToo = type == 'productivity' && !_cache.containsKey('visit');

    // Bump the token even on the cache-hit path so a still-in-flight fetch
    // for a tab the user has since left can't later clobber this one.
    final requestToken = ++_fetchToken;

    if (_cache.containsKey(type) && !needsVisitToo) {
      // Already have everything this tab needs — show it immediately even
      // if an older fetch for a different tab is still spinning.
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    final details = context.read<UserProvider>().getSalesUserDetails();
    final tsmId = details?.user?.id ?? '';
    final token = details?.token ?? '';
    final orderBookerId = widget.orderBooker.id ?? widget.orderBooker.salesId ?? '';

    if (tsmId.isEmpty || token.isEmpty || orderBookerId.isEmpty) {
      if (!mounted || requestToken != _fetchToken) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load report. Please sign in again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = OrderBookerActivityRepositoryImp();
    final typesToFetch = <String>{
      if (!_cache.containsKey(type)) type,
      if (needsVisitToo) 'visit',
    };

    String? error;
    for (final t in typesToFetch) {
      final result = await repo.getOrderBookerReport(
        tsmId: tsmId,
        orderBookerId: orderBookerId,
        reportType: t,
        token: token,
      );
      result.fold((l) => error = l.error.toString(), (r) => _cache[t] = r);
    }

    // A newer _fetchReport() call (from switching tabs again while this one
    // was still in flight) has already taken over — don't let this stale
    // call flip _isLoading/_errorMessage for whatever tab is showing now.
    if (!mounted || requestToken != _fetchToken) return;
    setState(() {
      _isLoading = false;
      _errorMessage = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        context,
        text: widget.orderBooker.name ?? 'OrderBooker Report',
        showText: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: FrontendConfigs.kAppBorder,
                color: FrontendConfigs.kTextFieldColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.orderBooker.name ?? 'OrderBooker',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${widget.orderBooker.salesId ?? 'N/A'}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: FrontendConfigs.kPrimaryColor,
              unselectedLabelColor: Colors.grey.shade700,
              indicatorColor: FrontendConfigs.kPrimaryColor,
              tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: ProcessingWidget())
                  : _buildReportBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportBody() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    switch (_tabTypes[_currentIndex]) {
      case 'attendance':
        return _AttendanceTable(
          data: (_cache['attendance'] as List?) ?? const [],
          orderBooker: widget.orderBooker,
        );
      case 'tracking':
        return _TrackingMapView(
          data: _cache['tracking'] is Map
              ? Map<String, dynamic>.from(_cache['tracking'] as Map)
              : null,
        );
      case 'visit':
        return _VisitsTable(data: (_cache['visit'] as List?) ?? const []);
      case 'productivity':
        return _ProductivityTable(
          productivity: _cache['productivity'] is Map
              ? Map<String, dynamic>.from(_cache['productivity'] as Map)
              : null,
          visits: (_cache['visit'] as List?) ?? const [],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── shared table building blocks ─────────────────────────────────────────

class _Col {
  final String label;
  final double width;

  const _Col(this.label, this.width);
}

Widget _tableHeader(List<_Col> cols) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1.5)),
    ),
    child: Row(
      children: cols
          .map((c) => SizedBox(
                width: c.width,
                child: Text(
                  c.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ))
          .toList(),
    ),
  );
}

Widget _tableRow(List<Widget> cells) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: cells),
  );
}

Widget _cell(String text, double width, {bool bold = false}) {
  return SizedBox(
    width: width,
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    ),
  );
}

Widget _cellWithPin(String text, double width, {double? lat, double? lng}) {
  return SizedBox(
    width: width,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: const TextStyle(fontSize: 13)),
        if (lat != null && lng != null) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _openInMaps(lat, lng),
            child: Icon(Icons.location_on, size: 15, color: FrontendConfigs.kPrimaryColor),
          ),
        ],
      ],
    ),
  );
}

Future<void> _openInMaps(double lat, double lng) async {
  final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// "0m" / "17m" / "2h 23m" — mirrors the `timeDisplay` / `durationDisplay`
/// formatting the backend already uses on individual records, so aggregate
/// totals computed on-device (e.g. the "Total Hours" header) read the same way.
String _formatMinutes(num totalMinutes) {
  final total = totalMinutes.round();
  if (total <= 0) return '0m';
  final h = total ~/ 60;
  final m = total % 60;
  if (h <= 0) return '${m}m';
  if (m <= 0) return '${h}h';
  return '${h}h ${m}m';
}

DateTime? _parseDate(String? s) {
  if (s == null || s.isEmpty) return null;
  try {
    return DateTime.parse(s);
  } catch (_) {
    return null;
  }
}

String _formatFullDate(String? isoDate) {
  final d = _parseDate(isoDate);
  return d != null ? DateFormat('EEEE, MMMM d, yyyy').format(d) : (isoDate ?? '-');
}

// ── Attendance tab ────────────────────────────────────────────────────────

class _AttendanceTable extends StatelessWidget {
  final List<dynamic> data;
  final OrderBooker orderBooker;

  const _AttendanceTable({required this.data, required this.orderBooker});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No attendance records found.'));
    }

    final totalMinutes = data.fold<num>(0, (sum, e) {
      final m = e is Map ? e['totalMinutes'] : null;
      return sum + (m is num ? m : 0);
    });

    final zoneName = orderBooker.zone?.name ?? '-';
    final townName = orderBooker.town?.name ?? '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Text(
            'Total Hours: ${_formatMinutes(totalMinutes)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: FrontendConfigs.kPrimaryColor,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              width: 830,
              child: Column(
                children: [
                  _tableHeader(const [
                    _Col('Date', 160),
                    _Col('Distributor', 150),
                    _Col('Zone', 100),
                    _Col('Town', 90),
                    _Col('Check In', 110),
                    _Col('Check Out', 110),
                    _Col('Total Hours', 100),
                  ]),
                  Expanded(
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: data.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, i) {
                        final item = Map<String, dynamic>.from(data[i] as Map);
                        final dist = item['distributor'] is Map
                            ? Map<String, dynamic>.from(item['distributor'] as Map)
                            : <String, dynamic>{};
                        final checkIn = _parseDate(item['checkInTime']?.toString());
                        final checkOutRaw = item['checkOutTime']?.toString() ?? '';
                        final checkOut =
                            checkOutRaw.isEmpty ? null : _parseDate(checkOutRaw);
                        final lat = (item['lat'] as num?)?.toDouble();
                        final lng = (item['lng'] as num?)?.toDouble();

                        return _tableRow([
                          _cell(_formatFullDate(item['date']?.toString()), 160),
                          _cell(
                            (dist['name'] ?? dist['distributionName'] ?? '-')
                                .toString(),
                            150,
                          ),
                          _cell(zoneName, 100),
                          _cell(townName, 90),
                          _cellWithPin(
                            checkIn != null ? DateFormat('h:mm a').format(checkIn) : '-',
                            110,
                            lat: lat,
                            lng: lng,
                          ),
                          _cell(
                            checkOut != null ? DateFormat('h:mm a').format(checkOut) : '-',
                            110,
                          ),
                          _cell((item['timeDisplay'] ?? '-').toString(), 100, bold: true),
                        ]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Visits tab ───────────────────────────────────────────────────────────

class _VisitsTable extends StatelessWidget {
  final List<dynamic> data;

  const _VisitsTable({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No visits found.'));
    }

    final totalMinutes = data.fold<num>(0, (sum, e) {
      final m = e is Map ? e['durationMinutes'] : null;
      return sum + (m is num ? m : 0);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Text(
            'Total Time: ${_formatMinutes(totalMinutes)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: FrontendConfigs.kPrimaryColor,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              width: 740,
              child: Column(
                children: [
                  _tableHeader(const [
                    _Col('Shop', 180),
                    _Col('Date', 160),
                    _Col('Start Visit', 100),
                    _Col('End Visit', 100),
                    _Col('Total Time', 100),
                    _Col('Details', 70),
                  ]),
                  Expanded(
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: data.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, i) {
                        final item = Map<String, dynamic>.from(data[i] as Map);
                        final shopName = (item['shopName'] as String?)?.trim();
                        final retailerImage = (item['retailerImage'] as String?) ?? '';
                        final visitImage = (item['image'] as String?) ?? '';

                        return _tableRow([
                          SizedBox(
                            width: 180,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.grey.shade300,
                                  backgroundImage: retailerImage.isNotEmpty
                                      ? NetworkImage(retailerImage)
                                      : null,
                                  child: retailerImage.isEmpty
                                      ? Icon(Icons.storefront,
                                          size: 14, color: Colors.grey.shade600)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    (shopName?.isNotEmpty == true)
                                        ? shopName!
                                        : 'Unknown Shop',
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _cell(_formatFullDate(item['date']?.toString()), 160),
                          _cell((item['startTimeFormatted'] ?? '-').toString(), 100),
                          _cell((item['endTimeFormatted'] ?? '-').toString(), 100),
                          _cell((item['durationDisplay'] ?? '-').toString(), 100, bold: true),
                          SizedBox(
                            width: 70,
                            child: InkWell(
                              onTap: () => _showVisitImage(context, visitImage),
                              child: Icon(Icons.remove_red_eye_outlined,
                                  size: 20, color: FrontendConfigs.kPrimaryColor),
                            ),
                          ),
                        ]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

void _showVisitImage(BuildContext context, String url) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: url.isNotEmpty
                ? Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Text('Image not available'),
                    ),
                  )
                : Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Text('No image available'),
                  ),
          ),
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: Colors.black54,
              radius: 14,
              child: Icon(Icons.close, color: Colors.white, size: 16),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );
}

// ── Productivity tab ──────────────────────────────────────────────────────
//
// The `type=productivity` endpoint only returns aggregate totals + a flat
// `ordersList`, not a ready-made daily table. This rebuilds the per-day
// "Shop Visits / Total Orders / Progress" breakdown by grouping `ordersList`
// (by `createdAt` date) and the Visits tab's own report (by its `date`
// field) on the client, matching the web portal's table shape.

class _ProductivityTable extends StatelessWidget {
  final Map<String, dynamic>? productivity;
  final List<dynamic> visits;

  const _ProductivityTable({required this.productivity, required this.visits});

  @override
  Widget build(BuildContext context) {
    final p = productivity;
    if (p == null) {
      return const Center(child: Text('No productivity data available.'));
    }

    final ordersList = (p['ordersList'] as List?) ?? const [];

    final Map<String, int> visitsByDate = {};
    for (final v in visits) {
      if (v is! Map) continue;
      final d = v['date']?.toString();
      if (d == null || d.isEmpty) continue;
      visitsByDate[d] = (visitsByDate[d] ?? 0) + 1;
    }

    final Map<String, int> ordersByDate = {};
    for (final o in ordersList) {
      if (o is! Map) continue;
      final createdAt = o['createdAt']?.toString() ?? '';
      if (createdAt.length < 10) continue;
      final dateKey = createdAt.substring(0, 10); // yyyy-MM-dd, no tz shift
      ordersByDate[dateKey] = (ordersByDate[dateKey] ?? 0) + 1;
    }

    final allDates = <String>{...visitsByDate.keys, ...ordersByDate.keys}.toList()
      ..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _statChip('Orders', '${p['totalOrdersPlaced'] ?? 0}'),
              _statChip(
                  'Sales', 'Rs ${((p['totalSalesValue'] as num?) ?? 0).toStringAsFixed(0)}'),
              _statChip('Visits', '${p['totalVisitsCount'] ?? 0}'),
              _statChip('Conversion', '${p['overallConversionRatePercent'] ?? 0}%'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: allDates.isEmpty
              ? const Center(child: Text('No productivity records found.'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: SizedBox(
                    width: 480,
                    child: Column(
                      children: [
                        _tableHeader(const [
                          _Col('Date', 170),
                          _Col('Shop Visits', 110),
                          _Col('Total Orders', 110),
                          _Col('Progress', 90),
                        ]),
                        Expanded(
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: allDates.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: Colors.grey.shade200),
                            itemBuilder: (context, i) {
                              final dateKey = allDates[i];
                              final visitsCount = visitsByDate[dateKey] ?? 0;
                              final ordersCount = ordersByDate[dateKey] ?? 0;
                              final progressText = visitsCount == 0
                                  ? (ordersCount > 0 ? '-' : '0%')
                                  : '${((ordersCount / visitsCount) * 100).round()}%';

                              return _tableRow([
                                _cell(_formatFullDate(dateKey), 170),
                                _cell('$visitsCount', 110),
                                _cell('$ordersCount', 110),
                                _cell(progressText, 90, bold: true),
                              ]);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

Widget _statChip(String label, String value) {
  return Text.rich(
    TextSpan(
      children: [
        TextSpan(text: '$label: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        TextSpan(
          text: value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: FrontendConfigs.kPrimaryColor,
          ),
        ),
      ],
    ),
  );
}

// ── Tracking tab (map) ────────────────────────────────────────────────────
//
// `type=tracking` returns `{ date, sessions: [{ checkInTime, checkOutTime,
// coordinates: [{ lat, lng, timestamp }] }] }` — the same shape already
// modelled by [TrackingData]/[Session]/[Coordinate] (see
// infrastructure/model/tracking.dart, used by the live "tracking/ping"
// flow), so it's parsed with that model directly instead of a new one.

class _TrackingMapView extends StatefulWidget {
  final Map<String, dynamic>? data;

  const _TrackingMapView({required this.data});

  @override
  State<_TrackingMapView> createState() => _TrackingMapViewState();
}

class _TrackingMapViewState extends State<_TrackingMapView> {
  GoogleMapController? _controller;

  static const List<Color> _sessionColors = [
    Color(0xff4282fe),
    Color(0xff17B556),
    Color(0xffFF7A00),
    Color(0xffE0339B),
    Color(0xff8E44AD),
  ];

  @override
  Widget build(BuildContext context) {
    final raw = widget.data;
    if (raw == null) {
      return const Center(child: Text('No tracking data available.'));
    }

    final trackingData = TrackingData.fromJson(raw);
    final sessions = trackingData.sessions ?? [];

    final polylines = <Polyline>{};
    final markers = <Marker>{};
    final allPoints = <LatLng>[];

    for (var s = 0; s < sessions.length; s++) {
      final session = sessions[s];
      final coords = (session.coordinates ?? [])
          .where((c) => c.lat != null && c.lng != null)
          .map((c) => LatLng(c.lat!, c.lng!))
          .toList();
      if (coords.isEmpty) continue;

      final color = _sessionColors[s % _sessionColors.length];
      allPoints.addAll(coords);

      polylines.add(Polyline(
        polylineId: PolylineId('session_$s'),
        points: coords,
        color: color,
        width: 4,
      ));

      markers.add(Marker(
        markerId: MarkerId('session_${s}_start'),
        position: coords.first,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Check-in', snippet: session.checkInTime ?? ''),
      ));
      markers.add(Marker(
        markerId: MarkerId('session_${s}_end'),
        position: coords.last,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Check-out', snippet: session.checkOutTime ?? ''),
      ));
    }

    if (allPoints.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No tracking data available for ${trackingData.date ?? 'this date'}.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: allPoints.first, zoom: 14),
            polylines: polylines,
            markers: markers,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            onMapCreated: (controller) {
              _controller = controller;
              _fitBounds(allPoints);
            },
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: FrontendConfigs.kTextFieldColor,
          child: Text(
            '${sessions.length} tracking session${sessions.length == 1 ? '' : 's'} on ${trackingData.date ?? '-'}',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  void _fitBounds(List<LatLng> points) {
    if (points.length < 2) return;
    var minLat = points.first.latitude, maxLat = points.first.latitude;
    var minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
    });
  }
}
