import 'package:flutter/material.dart';
import 'package:saraspatika/core/constants/colors.dart';
import 'package:saraspatika/feature/home/screen/view_all/widget/content_all_history.dart';

class ViewAllHistory extends StatefulWidget {
  const ViewAllHistory({super.key});

  @override
  State<ViewAllHistory> createState() => _ViewAllHistoryState();
}

class _ViewAllHistoryState extends State<ViewAllHistory> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.backgroundColor,
        centerTitle: true,
        title: const Text(
          'History Kehadiran',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ContentAllHistory(),
      ),
    );
  }
}
