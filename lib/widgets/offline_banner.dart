import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/network/network_info.dart';
import '../core/theme/app_theme.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final networkInfo = context.watch<NetworkInfoImpl>();

    return FutureBuilder<bool>(
      future: networkInfo.isConnected,
      initialData: true,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? true;
        if (isConnected && !networkInfo.isSimulatingOffline) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppTheme.accentColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                networkInfo.isSimulatingOffline
                    ? 'Offline Simulation Active — Serving Cached Data'
                    : 'No Internet Connection — Serving Cached Data',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
