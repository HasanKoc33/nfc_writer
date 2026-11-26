import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../data/model/nfc_history_item.dart';

class HistoryItemCard extends StatelessWidget {
  final NfcHistoryItem item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onUse;
  final VoidCallback? onShare;

  const HistoryItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onDelete,
    this.onUse,
    this.onShare,
  });

  IconData _getIcon() {
    switch (item.type) {
      case NfcHistoryType.url:
        return Icons.link;
      case NfcHistoryType.text:
        return Icons.text_fields;
      case NfcHistoryType.wifi:
        return Icons.wifi;
      case NfcHistoryType.phone:
        return Icons.phone;
      case NfcHistoryType.email:
        return Icons.email;
      case NfcHistoryType.location:
        return Icons.location_on;
      case NfcHistoryType.sms:
        return Icons.sms;
      case NfcHistoryType.vcard:
        return Icons.contact_page;
      default:
        return Icons.nfc;
    }
  }

  Color _getIconColor(BuildContext context) {
    switch (item.type) {
      case NfcHistoryType.url:
        return Colors.blue;
      case NfcHistoryType.text:
        return Colors.green;
      case NfcHistoryType.wifi:
        return Colors.teal;
      case NfcHistoryType.phone:
        return Colors.orange;
      case NfcHistoryType.email:
        return Colors.red;
      case NfcHistoryType.location:
        return Colors.purple;
      case NfcHistoryType.sms:
        return Colors.indigo;
      case NfcHistoryType.vcard:
        return Colors.pink;
      default:
        return Theme.of(context).primaryColor;
    }
  }

  /// İçerik JSON olarak saklanır; kullanıcıya ham JSON yerine değerler gösterilir.
  String _readableContent() {
    try {
      final decoded = jsonDecode(item.content);
      if (decoded is Map) {
        if (item.type == NfcHistoryType.wifi) {
          return decoded['S']?.toString() ?? item.title;
        }
        return decoded.values
            .where((v) => v != null && v.toString().isNotEmpty)
            .map((v) => v.toString())
            .join(' · ');
      }
      return decoded.toString();
    } catch (e) {
      return item.content;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('history.confirm_delete'.tr()),
              content: Text('history.confirm_delete_message'.tr()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('history.cancel'.tr()),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'history.delete'.tr(),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        onDelete?.call();
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getIconColor(context).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _getIcon(),
                        color: _getIconColor(context),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _readableContent(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        switch (value) {
                          case 'use':
                            onUse?.call();
                            break;
                          case 'copy':
                            Clipboard.setData(
                              ClipboardData(text: _readableContent()),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('history.copied'.tr()),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            break;
                          case 'share':
                            onShare?.call();
                            break;
                          case 'delete':
                            onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem<String>(
                          value: 'use',
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline),
                              const SizedBox(width: 12),
                              Text('history.use'.tr()),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'copy',
                          child: Row(
                            children: [
                              const Icon(Icons.copy),
                              const SizedBox(width: 12),
                              Text('history.copy'.tr()),
                            ],
                          ),
                        ),
                        if (onShare != null)
                          PopupMenuItem<String>(
                            value: 'share',
                            child: Row(
                              children: [
                                const Icon(Icons.share),
                                const SizedBox(width: 12),
                                Text('history.share'.tr()),
                              ],
                            ),
                          ),
                        const PopupMenuDivider(),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete, color: Colors.red),
                              const SizedBox(width: 12),
                              Text(
                                'history.delete'.tr(),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 56, right: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'history.filter.${item.type}'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(item.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'history.just_now'.tr();
    } else if (difference.inHours < 1) {
      return 'history.minutes_ago'.tr(args: [difference.inMinutes.toString()]);
    } else if (difference.inDays < 1) {
      return 'history.hours_ago'.tr(args: [difference.inHours.toString()]);
    } else if (difference.inDays < 7) {
      return 'history.days_ago'.tr(args: [difference.inDays.toString()]);
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}
