import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/infrastructure/model/add_recovery.dart';
import 'package:sm_networking/infrastructure/model/error.dart';
import 'package:sm_networking/infrastructure/services/retailer.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';

class MyRecoveriesView extends StatefulWidget {
  const MyRecoveriesView({super.key});

  @override
  State<MyRecoveriesView> createState() => _MyRecoveriesViewState();
}

class _MyRecoveriesViewState extends State<MyRecoveriesView> {
  late Future<Either<GlobalErrorModel, RecoveryListingModel>> _future;
  bool _futureInited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_futureInited) return;
    _futureInited = true;
    final token =
        context.read<UserProvider>().getSalesUserDetails()?.token ?? '';
    _future = token.isEmpty
        ? Future.value(
            Left(
              GlobalErrorModel(
                error:
                    'Session expired or not logged in. Please sign in again.',
              ),
            ),
          )
        : RetailerRepositoryImp().getMyPayments(token);
  }

  Future<void> _reload() async {
    final token =
        context.read<UserProvider>().getSalesUserDetails()?.token ?? '';
    setState(() {
      _future = token.isEmpty
          ? Future.value(
              Left(
                GlobalErrorModel(
                  error:
                      'Session expired or not logged in. Please sign in again.',
                ),
              ),
            )
          : RetailerRepositoryImp().getMyPayments(token);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context, text: 'My Recoveries', showText: true),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<Either<GlobalErrorModel, RecoveryListingModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: ProcessingWidget());
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(snapshot.error.toString(),
                        textAlign: TextAlign.center),
                  ),
                ],
              );
            }
            final result = snapshot.data;
            if (result == null) {
              return const SizedBox.shrink();
            }
            return result.fold(
              (l) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l.error.toString(),
                        textAlign: TextAlign.center),
                  ),
                ],
              ),
              (r) {
                if (r.data.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No recoveries yet')),
                    ],
                  );
                }
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  itemCount: r.data.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final m = r.data[i];
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
                          if (m.zoneName.isNotEmpty)
                            Text(
                              'Zone: ${m.zoneName}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade700),
                            ),
                          if (m.townName.isNotEmpty)
                            Text(
                              'Town: ${m.townName}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade700),
                            ),
                          if (m.date != null && m.date!.isNotEmpty)
                            Text(
                              'Date: ${m.date}',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            '${m.bankName} · ${m.paymentMode}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
