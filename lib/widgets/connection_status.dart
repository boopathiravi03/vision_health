import 'package:flutter/material.dart';

class ConnectionStatus extends StatelessWidget {
  final bool online;

  const ConnectionStatus({
    super.key,
    required this.online,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: online
            ? Colors.green.shade50
            : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            online
                ? Icons.cloud_done_rounded
                : Icons.cloud_off_rounded,
            size: 16,
            color: online
                ? Colors.green.shade700
                : Colors.orange.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            online ? 'Online' : 'Offline Mode',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: online
                  ? Colors.green.shade700
                  : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
