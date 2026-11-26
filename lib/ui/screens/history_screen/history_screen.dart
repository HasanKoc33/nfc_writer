import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/utils/analytics_helper.dart';
import '../../../data/model/nfc_history_item.dart';
import '../../../data/repositories/nfc_history_repository.dart';
import '../../widgets/history_item_card.dart';
import '../../widgets/modern_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.embedded = false, this.onUseItem});

  /// Ana ekrandaki sekme içinde gösterildiğinde kendi AppBar'ını çizmez.
  final bool embedded;

  /// "Kullan" seçildiğinde çağrılır; verilmezse ekran öğeyle birlikte kapanır.
  final ValueChanged<NfcHistoryItem>? onUseItem;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NfcHistoryRepository _repository = NfcHistoryRepository();
  final TextEditingController _searchController = TextEditingController();

  List<NfcHistoryItem> _readHistory = [];
  List<NfcHistoryItem> _writeHistory = [];
  List<NfcHistoryItem> _filteredReadHistory = [];
  List<NfcHistoryItem> _filteredWriteHistory = [];

  String _selectedFilter = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
    AnalyticsService().logScreenView(screenName: 'HistoryScreen');
    AnalyticsHelper.trackCustomEvent(eventName: 'history_screen_opened');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    _readHistory = await _repository.getReadHistory();
    _writeHistory = await _repository.getWriteHistory();
    _filteredReadHistory = _readHistory;
    _filteredWriteHistory = _writeHistory;

    setState(() => _isLoading = false);
  }

  void _filterHistory(String filter) {
    setState(() {
      _selectedFilter = filter;

      if (filter == 'all') {
        _filteredReadHistory = _readHistory;
        _filteredWriteHistory = _writeHistory;
      } else {
        _filteredReadHistory = _readHistory
            .where((item) => item.type == filter)
            .toList();
        _filteredWriteHistory = _writeHistory
            .where((item) => item.type == filter)
            .toList();
      }
    });
  }

  void _searchHistory(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredReadHistory = _readHistory;
        _filteredWriteHistory = _writeHistory;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredReadHistory = _readHistory.where((item) {
          return item.title.toLowerCase().contains(lowerQuery) ||
              item.content.toLowerCase().contains(lowerQuery);
        }).toList();
        _filteredWriteHistory = _writeHistory.where((item) {
          return item.title.toLowerCase().contains(lowerQuery) ||
              item.content.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  Future<void> _deleteItem(NfcHistoryItem item) async {
    await _repository.deleteHistoryItem(item.id);
    await AnalyticsHelper.trackCustomEvent(
      eventName: 'history_item_deleted',
      parameters: {'type': item.type, 'category': item.category},
    );
    await _loadHistory();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('history.item_deleted'.tr())));
    }
  }

  Future<void> _useItem(NfcHistoryItem item) async {
    await AnalyticsHelper.trackCustomEvent(
      eventName: 'history_item_used',
      parameters: {'type': item.type, 'category': item.category},
    );

    if (!mounted) return;
    if (widget.onUseItem != null) {
      widget.onUseItem!(item);
    } else {
      Navigator.pop(context, item);
    }
  }

  Future<void> _clearHistory(String category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('history.confirm_clear'.tr()),
        content: Text('history.confirm_clear_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('history.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'history.clear_all'.tr(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repository.clearHistory(category);
      await AnalyticsHelper.trackCustomEvent(
        eventName: 'history_cleared',
        parameters: {'category': category},
      );
      await _loadHistory();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('history.cleared'.tr())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _buildBody();
    return Scaffold(
      appBar: AppBar(
        title: Text('history.title'.tr()),
        bottom: _buildTabBar(),
        actions: [_buildMenu()],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'clear_read') {
          _clearHistory(NfcHistoryCategory.read);
        } else if (value == 'clear_write') {
          _clearHistory(NfcHistoryCategory.write);
        } else if (value == 'clear_all') {
          _clearHistory('all');
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'clear_read',
          child: Text('history.clear_read'.tr()),
        ),
        PopupMenuItem(
          value: 'clear_write',
          child: Text('history.clear_write'.tr()),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'clear_all',
          child: Text(
            'history.clear_all'.tr(),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  TabBar _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: [
        Tab(text: 'history.read_tab'.tr()),
        Tab(text: 'history.write_tab'.tr()),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        if (widget.embedded)
          Row(
            children: [
              Expanded(child: _buildTabBar()),
              _buildMenu(),
            ],
          ),
        _buildSearchBar(),
        _buildFilterChips(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildHistoryList(
                      _filteredReadHistory,
                      NfcHistoryCategory.read,
                    ),
                    _buildHistoryList(
                      _filteredWriteHistory,
                      NfcHistoryCategory.write,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'history.search'.tr(),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchHistory('');
                  },
                )
              : null,
        ),
        onChanged: _searchHistory,
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {
        'value': 'all',
        'label': 'history.filter.all'.tr(),
        'icon': Icons.all_inclusive,
      },
      {
        'value': NfcHistoryType.url,
        'label': 'history.filter.url'.tr(),
        'icon': Icons.link,
      },
      {
        'value': NfcHistoryType.text,
        'label': 'history.filter.text'.tr(),
        'icon': Icons.text_fields,
      },
      {
        'value': NfcHistoryType.wifi,
        'label': 'history.filter.wifi'.tr(),
        'icon': Icons.wifi,
      },
      {
        'value': NfcHistoryType.phone,
        'label': 'history.filter.phone'.tr(),
        'icon': Icons.phone,
      },
      {
        'value': NfcHistoryType.email,
        'label': 'history.filter.email'.tr(),
        'icon': Icons.email,
      },
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['value'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              avatar: Icon(filter['icon'] as IconData, size: 16),
              label: Text(filter['label'] as String),
              onSelected: (selected) {
                _filterHistory(filter['value'] as String);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryList(List<NfcHistoryItem> items, String category) {
    if (items.isEmpty) {
      return StatusView(
        icon: Icons.history_rounded,
        title: 'history.empty'.tr(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return HistoryItemCard(
            item: item,
            onTap: () => _showItemDetails(item),
            onDelete: () => _deleteItem(item),
            onUse: () => _useItem(item),
          );
        },
      ),
    );
  }

  void _showItemDetails(NfcHistoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getIconForType(item.type)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'history.type'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text('history.filter.${item.type}'.tr()),
              const SizedBox(height: 16),
              Text(
                'history.content'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(item.content),
              const SizedBox(height: 16),
              Text(
                'history.date'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(DateFormat('dd/MM/yyyy HH:mm').format(item.timestamp)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('history.close'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _useItem(item);
            },
            child: Text('history.use'.tr()),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
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
}
