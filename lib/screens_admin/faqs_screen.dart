import 'package:flutter/material.dart';
import 'package:resq_alert/widgets/admin_scaffold.dart';

class FaqsScreen extends StatelessWidget {
  const FaqsScreen({super.key});

  final faqs = const [
    {
      "q": "How do broadcasts work?",
      "a": "Admins can send an alert to all registered responders instantly."
    },
    {"q": "Can users be removed?", "a": "Yes, via User Management page."},
    {
      "q": "How is response time calculated?",
      "a": "Based on time between alert sent and responder acknowledgement."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: "FAQs",
      selected: AdminMenuItem.faqs,
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: faqs.length,
        itemBuilder: (context, i) => _FaqTile(
          question: faqs[i]["q"]!,
          answer: faqs[i]["a"]!,
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question, answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text(widget.question,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(widget.answer),
          )
        ],
      ),
    );
  }
}
