import 'package:flutter/material.dart';
import 'package:ppiwd_work_breaks_frontend/activity_client.dart';
import 'package:ppiwd_work_breaks_frontend/token_client.dart';

class AccountChart extends StatefulWidget {
  const AccountChart({super.key, required this.activityClient});
  final ActivityClient activityClient;

  @override
  State<AccountChart> createState() => _AccountChart();
}

class _AccountChart extends State<AccountChart> {
  static const int PAGE_SIZE = 1;
  List<TimerDTO> timers = [];
  int currentPage = 0;
  int pageSize = 1;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTimers(0);
  }

  void loadTimers(page) async {
    setState(() {
      isLoading = true;
    });
    var response = await widget.activityClient.getAllTimers(page, PAGE_SIZE);
    setState(() {
      timers = response.content;
      currentPage = page;
      pageSize = pageSize;
      isLoading = false;
    });
  }

  bool _isPrevEnabled() {
    return !isLoading && pageSize - 1 >= 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            ElevatedButton(onPressed: () => {}, child: Text("test")),
            Text(pageSize.toString()),
            ElevatedButton(onPressed: () => {}, child: Text("test"))
          ],
        )
      ],
    );
  }
}
