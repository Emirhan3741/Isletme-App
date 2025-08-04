import 'package:flutter/material.dart';

class WorkerDashboard extends StatelessWidget {
  const WorkerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Çalışan Paneli'),
      ),
      body: const Center(
        child: Text('Çalışan Dashboard İçeriği'),
      ),
    );
  }
}
