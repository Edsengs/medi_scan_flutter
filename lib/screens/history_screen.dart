import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyRef = FirebaseDatabase.instance.ref('scanned_history').orderByChild('timestamp');

    return Scaffold(
      appBar: AppBar(title: const Text('Scan History')),
      body: StreamBuilder(
        stream: historyRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No scan history found.'));
          }

          final Map<dynamic, dynamic> historyMap = snapshot.data!.snapshot.value as Map;
          final List<MapEntry> historyList = historyMap.entries.toList();
          historyList.sort((a, b) => b.value['timestamp'].compareTo(a.value['timestamp']));

          return ListView.builder(
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final record = historyList[index].value;
              final bool wasFound = record['wasFound'] ?? false;
              final bool isGenuine = record['isGenuine'] ?? false;

              IconData leadIcon = Icons.help;
              Color iconColor = Colors.orange;
              if (wasFound) {
                leadIcon = isGenuine ? Icons.check_circle : Icons.cancel;
                iconColor = isGenuine ? Colors.green : Colors.red;
              }

              return ListTile(
                leading: Icon(leadIcon, color: iconColor),
                title: Text(record['drugName'] ?? 'Unknown'),
                subtitle: Text('Code: ${record['scannedCode']}'),
                trailing: Text(record['scanDate']?.substring(0, 10) ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}

