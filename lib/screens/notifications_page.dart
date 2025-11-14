import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  static const routeName = '/notifications';
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with SingleTickerProviderStateMixin {
  late TabController _tc;

  final List<Map<String,String>> _all = [
    {'type': 'Medical Emergency', 'desc': 'John Smith - Building A - Room 205', 'status': 'active'},
    {'type': 'Fire Emergency Resolved', 'desc': 'Cass Veraque - Laboratory Building', 'status': 'resolved'},
  ];

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tc.dispose(); super.dispose(); }

  List<Map<String,String>> _filter(String key) => _all.where((e) => key == 'all' ? true : (key == 'active' ? e['status']=='active' : e['status']=='resolved')).toList();

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFC82323);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: Column(children: [
          TabBar(controller: _tc, labelColor: red, unselectedLabelColor: Colors.black54, tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ]),
          Expanded(
            child: TabBarView(controller: _tc, children: [
              _listView(_filter('all')),
              _listView(_filter('active')),
              _listView(_filter('history')),
            ]),
          )
        ]),
      ),
    );
  }

  Widget _listView(List<Map<String,String>> items) {
    if (items.isEmpty) return const Center(child: Text('No notifications'));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_,__) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final it = items[i];
        final active = it['status']=='active';
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: active ? Colors.red.shade50 : Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: active ? Colors.red : Colors.green)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(it['type']!, style: TextStyle(fontWeight: FontWeight.bold, color: active ? Colors.red.shade700 : Colors.green.shade700)),
            const SizedBox(height: 6),
            Text(it['desc']!, style: const TextStyle(color: Colors.black54)),
          ]),
        );
      },
    );
  }
}
