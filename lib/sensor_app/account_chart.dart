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
  @override
  Widget build(BuildContext context) {
    return Column();
  }
}
