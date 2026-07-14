import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sm_networking/infrastructure/model/stats.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class MonthDashboardChart extends StatefulWidget {
  final List<MonthsSale> list;

  const MonthDashboardChart(this.list, {super.key});

  @override
  State<MonthDashboardChart> createState() => _MonthDashboardChartState();
}

class _MonthDashboardChartState extends State<MonthDashboardChart> {
  List<ChartData> chartData = [];

  @override
  void initState() {
    chartData = [
      ChartData(
          DateFormat('MMM').format(DateTime(
            DateTime.now().year,
            DateTime.now().subtract(Duration(days: (30) * 2)).month,
            0,
            0,
            0,
          )),
          widget.list[3].sales!.toDouble()),
      ChartData(
          DateFormat('MMM').format(DateTime(
            DateTime.now().year,
            DateTime.now().subtract(Duration(days: (30) * 1)).month,
            0,
            0,
            0,
          )),
          widget.list[2].sales!.toDouble()),
      ChartData(
          DateFormat('MMM').format(DateTime(
            DateTime.now().year,
            DateTime.now().month,
            0,
            0,
            0,
          )),
          widget.list[1].sales!.toDouble()),
      ChartData(
          DateFormat('MMM').format(DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            0,
            0,
          )),
          widget.list[0].sales!.toDouble()),
    ];

    setState(() {});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 160,
        child: SfCartesianChart(
            primaryYAxis: NumericAxis(
                // X axis is hidden now
                isVisible: true),
            primaryXAxis: CategoryAxis(
              //Hide the gridlines of x-axis
              majorGridLines: MajorGridLines(width: 0),
              //Hide the axis line of x-axis
              axisLine: AxisLine(width: 0),
            ),
            plotAreaBorderWidth: 0,
            series: <CartesianSeries>[
              SplineSeries<ChartData, String>(
                  dataSource: chartData,
                  // Type of spline
                  splineType: SplineType.monotonic,
                  color: Color(0xffFFAD42),
                  width: 5,
                  cardinalSplineTension: 0.9,
                  xValueMapper: (ChartData data, _) => data.x,
                  yValueMapper: (ChartData data, _) => data.y)
            ]));
  }
}

class ChartData {
  ChartData(this.x, this.y);

  final String x;
  final double y;
}
