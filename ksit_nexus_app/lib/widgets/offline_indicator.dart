import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ksit_nexus_app/providers/offline_providers.dart';
import 'package:ksit_nexus_app/theme/app_theme.dart';

class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    final syncProgress = ref.watch(syncProgressProvider);
    final lastSyncTime = ref.watch(lastSyncTimeProvider);

    return connectionStatus.when(
      data: (isOnline) {
        if (isOnline) {
          return const SizedBox.shrink();
        } else {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.errorColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_off,
                  color: AppTheme.errorColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You\'re offline. Some features may be limited.',
                    style: TextStyle(
                      color: AppTheme.errorColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (syncStatus == 'syncing')
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.errorColor),
                    ),
                  ),
              ],
            ),
          );
        }
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final syncProgress = ref.watch(syncProgressProvider);
    final lastSyncTime = ref.watch(lastSyncTimeProvider);

    if (syncStatus == 'idle') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: syncStatus == 'error' 
            ? AppTheme.errorColor.withOpacity(0.1)
            : AppTheme.primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: syncStatus == 'error'
                ? AppTheme.errorColor.withOpacity(0.3)
                : AppTheme.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (syncStatus == 'syncing')
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          else if (syncStatus == 'completed')
            Icon(
              Icons.check_circle,
              color: AppTheme.successColor,
              size: 20,
            )
          else if (syncStatus == 'error')
            Icon(
              Icons.error,
              color: AppTheme.errorColor,
              size: 20,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getSyncStatusText(syncStatus),
                  style: TextStyle(
                    color: syncStatus == 'error' 
                        ? AppTheme.errorColor
                        : AppTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (syncStatus == 'syncing' && syncProgress > 0)
                  LinearProgressIndicator(
                    value: syncProgress,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSyncStatusText(String status) {
    switch (status) {
      case 'syncing':
        return 'Syncing data...';
      case 'completed':
        return 'Sync completed';
      case 'error':
        return 'Sync failed. Will retry automatically.';
      default:
        return '';
    }
  }
}

class OfflineBanner extends ConsumerWidget {
  final Widget child;
  
  const OfflineBanner({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const OfflineIndicator(),
        const SyncStatusIndicator(),
        Expanded(child: child),
      ],
    );
  }
}

class OfflineFloatingActionButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  
  const OfflineFloatingActionButton({
    Key? key,
    this.onPressed,
    required this.icon,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isOnline = connectionStatus.value ?? true;
    
    return FloatingActionButton(
      onPressed: isOnline ? onPressed : null,
      tooltip: isOnline ? tooltip : 'This feature requires an internet connection',
      backgroundColor: isOnline ? null : AppTheme.disabledColor,
      child: Icon(
        icon,
        color: isOnline ? null : AppTheme.textSecondaryColor,
      ),
    );
  }
}

class OfflineButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? offlineMessage;
  
  const OfflineButton({
    Key? key,
    this.onPressed,
    required this.child,
    this.offlineMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isOnline = connectionStatus.value ?? true;
    
    return Tooltip(
      message: isOnline ? null : (offlineMessage ?? 'This feature requires an internet connection'),
      child: Opacity(
        opacity: isOnline ? 1.0 : 0.6,
        child: ElevatedButton(
          onPressed: isOnline ? onPressed : null,
          child: child,
        ),
      ),
    );
  }
}

class OfflineTextField extends ConsumerWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final bool enabled;
  final String? offlineMessage;
  
  const OfflineTextField({
    Key? key,
    this.controller,
    this.labelText,
    this.hintText,
    this.enabled = true,
    this.offlineMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isOnline = connectionStatus.value ?? true;
    
    return Tooltip(
      message: isOnline ? null : (offlineMessage ?? 'This feature requires an internet connection'),
      child: TextField(
        controller: controller,
        enabled: enabled && isOnline,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          suffixIcon: isOnline ? null : Icon(
            Icons.cloud_off,
            color: AppTheme.errorColor,
            size: 20,
          ),
        ),
      ),
    );
  }
}
