import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ride_provider.dart';
import 'history_detail_screen.dart';
import 'history_yearly_screen.dart';
import 'history_monthly_screen.dart';
import 'history_daily_screen.dart';
import 'history_average_screen.dart';
import 'history_total_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RideProvider>().loadRecords();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: '평균'),
            Tab(text: '연도별'),
            Tab(text: '월별'),
            Tab(text: '일별'),
            Tab(text: '상세'),
            Tab(text: '전체'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const HistoryAverageScreen(),
          const HistoryYearlyScreen(),
          const HistoryMonthlyScreen(),
          const HistoryDailyScreen(),
          HistoryDetailScreen(),
          const HistoryTotalScreen(),
        ],
      ),
    );
  }
}