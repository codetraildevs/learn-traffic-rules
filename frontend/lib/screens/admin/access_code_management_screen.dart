import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:learn_traffic_rules/core/theme/app_theme.dart';
import 'package:learn_traffic_rules/models/access_code_model.dart';
import 'package:learn_traffic_rules/services/user_management_service.dart';
import 'package:learn_traffic_rules/widgets/loading_widget.dart';

class AccessCodeManagementScreen extends ConsumerStatefulWidget {
  const AccessCodeManagementScreen({super.key});

  @override
  ConsumerState<AccessCodeManagementScreen> createState() =>
      _AccessCodeManagementScreenState();
}

class _AccessCodeManagementScreenState
    extends ConsumerState<AccessCodeManagementScreen> {
  final UserManagementService _userManagementService = UserManagementService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<AccessCode> _accessCodes = [];
  List<AccessCode> _filteredCodes = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  String _selectedSort = 'createdAt';
  bool _sortAscending = false;
  Timer? _refreshTimer;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _filterByToday = false;

  @override
  void initState() {
    super.initState();
    _loadAccessCodes();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    // Refresh every 24 hours (86400000 milliseconds)
    _refreshTimer = Timer.periodic(const Duration(hours: 24), (timer) {
      if (mounted) {
        _loadAccessCodes();
      }
    });
  }

  Future<void> _loadAccessCodes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _userManagementService.getAllAccessCodes();
      if (response.success) {
        setState(() {
          _accessCodes = response.data.accessCodes;
          _filteredCodes = _accessCodes;
        });
        _applyFiltersAndSort();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load access codes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    List<AccessCode> filtered = List.from(_accessCodes);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((code) {
        return code.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            code.userId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            code.paymentTier.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply status filter
    if (_selectedFilter != 'all') {
      switch (_selectedFilter) {
        case 'active':
          filtered = filtered
              .where(
                (code) => !code.isUsed && !code.isExpired && !code.isBlocked,
              )
              .toList();
          break;
        case 'used':
          filtered = filtered.where((code) => code.isUsed).toList();
          break;
        case 'expired':
          filtered = filtered.where((code) => code.isExpired).toList();
          break;
        case 'blocked':
          filtered = filtered.where((code) => code.isBlocked).toList();
          break;
      }
    }

    // Apply date filters
    if (_filterByToday) {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      filtered = filtered.where((code) {
        final codeDate = DateTime(
          code.createdAt.year,
          code.createdAt.month,
          code.createdAt.day,
        );
        return codeDate.isAfter(
              todayStart.subtract(const Duration(microseconds: 1)),
            ) &&
            codeDate.isBefore(todayEnd);
      }).toList();
    } else if (_startDate != null || _endDate != null) {
      filtered = filtered.where((code) {
        final codeDate = DateTime(
          code.createdAt.year,
          code.createdAt.month,
          code.createdAt.day,
        );

        if (_startDate != null && _endDate != null) {
          final rangeStart = DateTime(
            _startDate!.year,
            _startDate!.month,
            _startDate!.day,
          );
          final rangeEnd = DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day,
          ).add(const Duration(days: 1));

          return codeDate.isAfter(
                rangeStart.subtract(const Duration(microseconds: 1)),
              ) &&
              codeDate.isBefore(rangeEnd);
        } else if (_startDate != null) {
          final rangeStart = DateTime(
            _startDate!.year,
            _startDate!.month,
            _startDate!.day,
          );
          return codeDate.isAfter(
            rangeStart.subtract(const Duration(microseconds: 1)),
          );
        } else if (_endDate != null) {
          final rangeEnd = DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day,
          ).add(const Duration(days: 1));
          return codeDate.isBefore(rangeEnd);
        }
        return true;
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_selectedSort) {
        case 'code':
          comparison = a.code.compareTo(b.code);
          break;
        case 'user':
          comparison = a.userId.compareTo(b.userId);
          break;
        case 'createdAt':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'expiresAt':
          comparison = a.expiresAt.compareTo(b.expiresAt);
          break;
        case 'paymentAmount':
          comparison = a.paymentAmount.compareTo(b.paymentAmount);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    setState(() {
      _filteredCodes = filtered;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFiltersAndSort();
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _applyFiltersAndSort();
  }

  void _onSortChanged(String sort) {
    setState(() {
      _selectedSort = sort;
    });
    _applyFiltersAndSort();
  }

  void _toggleSortDirection() {
    setState(() {
      _sortAscending = !_sortAscending;
    });
    _applyFiltersAndSort();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _filterByToday = false;
      });
      _applyFiltersAndSort();
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _filterByToday = false;
      });
      _applyFiltersAndSort();
    }
  }

  void _toggleTodayFilter() {
    setState(() {
      _filterByToday = !_filterByToday;
      if (_filterByToday) {
        _startDate = null;
        _endDate = null;
      }
    });
    _applyFiltersAndSort();
  }

  void _clearDateFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _filterByToday = false;
    });
    _applyFiltersAndSort();
  }

  Widget _buildDateFilters() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16.sp, color: AppColors.primary),
              SizedBox(width: 8.w),
              Text(
                'Date Filter',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              // Today Filter Button
              FilterChip(
                label: const Text('Today'),
                selected: _filterByToday,
                onSelected: (selected) => _toggleTodayFilter(),
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
              ),
              // Start Date
              InkWell(
                onTap: _selectStartDate,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: _startDate != null
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: _startDate != null
                          ? AppColors.primary
                          : AppColors.grey300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16.sp,
                        color: _startDate != null
                            ? AppColors.primary
                            : AppColors.grey600,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        _startDate != null
                            ? DateFormat('MMM dd, yyyy').format(_startDate!)
                            : 'Start Date',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _startDate != null
                              ? AppColors.primary
                              : AppColors.grey600,
                          fontWeight: _startDate != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // End Date
              InkWell(
                onTap: _selectEndDate,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: _endDate != null
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: _endDate != null
                          ? AppColors.primary
                          : AppColors.grey300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16.sp,
                        color: _endDate != null
                            ? AppColors.primary
                            : AppColors.grey600,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        _endDate != null
                            ? DateFormat('MMM dd, yyyy').format(_endDate!)
                            : 'End Date',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _endDate != null
                              ? AppColors.primary
                              : AppColors.grey600,
                          fontWeight: _endDate != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Clear Button
              if (_startDate != null || _endDate != null || _filterByToday)
                InkWell(
                  onTap: _clearDateFilters,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.clear, size: 16.sp, color: AppColors.error),
                        SizedBox(width: 6.w),
                        Text(
                          'Clear',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBlockStatus(AccessCode code) async {
    try {
      final response = await _userManagementService.toggleAccessCodeBlockStatus(
        code.id,
        !code.isBlocked, // Toggle the current status
      );
      if (response['success'] == true) {
        _showSuccessSnackBar('Access code ${code.code} successfully');
        _loadAccessCodes(); // Refresh the list
      } else {
        _showErrorSnackBar(
          'Failed to toggle block status: ${response['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error toggling block status: $e');
    }
  }

  Future<void> _deleteAccessCode(AccessCode code) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Expanded(
          child: Row(
            children: [
              Icon(Icons.delete_forever, color: AppColors.error, size: 24.sp),
              SizedBox(width: 8.w),
              const Text('Delete Access Code', style: AppTextStyles.caption),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delete access code ${code.code}? This action cannot be undone.',
              style: AppTextStyles.bodyMedium,
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: AppColors.error, size: 18.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Users relying on this code may lose access immediately.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: AppTextStyles.bodyMedium),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete', style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _userManagementService.deleteAccessCode(code.id);
        if (response['success'] == true) {
          _showSuccessSnackBar('Access code deleted successfully');
          _loadAccessCodes(); // Refresh the list
        } else {
          _showErrorSnackBar(
            'Failed to delete access code: ${response['message'] ?? 'Unknown error'}',
          );
        }
      } catch (e) {
        _showErrorSnackBar('Error deleting access code: $e');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text(
          'Access Code Management',
          style: AppTextStyles.heading2,
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadAccessCodes,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAccessCodes,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildFilterSection()),
            if (_isLoading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: const Center(child: LoadingWidget()),
              )
            else if (_filteredCodes.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.vpn_key_outlined,
                      size: 64.sp,
                      color: AppColors.grey400,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'No access codes found matching "$_searchQuery"'
                          : 'No access codes found',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.grey600,
                      ),
                    ),
                  ],
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.all(16.w),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final code = _filteredCodes[index];
                    return _buildAccessCodeCard(code);
                  }, childCount: _filteredCodes.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessCodeCard(AccessCode code) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Code
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        code.code,
                        style: AppTextStyles.heading3.copyWith(
                          fontSize: 16.sp,
                          fontFamily: 'monospace',
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _getUserDisplayName(code),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.grey600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (code.user?.phoneNumber?.isNotEmpty == true) ...[
                        SizedBox(height: 2.h),
                        Text(
                          code.user!.phoneNumber!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                      SizedBox(height: 2.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(code),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          code.statusText,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Row(
                  children: [
                    // Toggle Block Button
                    IconButton(
                      onPressed: () => _toggleBlockStatus(code),
                      icon: Icon(
                        code.isBlocked ? Icons.lock_open : Icons.block,
                        color: code.isBlocked
                            ? AppColors.success
                            : AppColors.warning,
                        size: 20.sp,
                      ),
                      tooltip: code.isBlocked ? 'Unblock' : 'Block',
                    ),

                    // Delete Button
                    IconButton(
                      onPressed: () => _deleteAccessCode(code),
                      icon: Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                        size: 20.sp,
                      ),
                      tooltip: 'Delete Access Code',
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Details Row - Responsive with Wrap
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _buildDetailChip(
                  Icons.payment,
                  '${code.paymentAmount} RWF',
                  AppColors.primary,
                ),
                _buildDetailChip(
                  Icons.schedule,
                  code.durationText,
                  AppColors.secondary,
                ),
                _buildDetailChip(
                  Icons.calendar_today,
                  'Expires at: ${DateFormat('MMM dd, yyyy').format(code.expiresAt)}',
                  AppColors.grey600,
                ),
                _buildDetailChip(
                  Icons.schedule,
                  '${_getRemainingDays(code)} days left',
                  _getRemainingDays(code) > 7
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: AppColors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search access codes...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColors.grey300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedFilter,
                  onChanged: (value) => _onFilterChanged(value!),
                  decoration: InputDecoration(
                    labelText: 'Filter by Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 4.h,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Codes')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'used', child: Text('Used')),
                    DropdownMenuItem(value: 'expired', child: Text('Expired')),
                    DropdownMenuItem(value: 'blocked', child: Text('Blocked')),
                  ],
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedSort,
                  onChanged: (value) => _onSortChanged(value!),
                  decoration: InputDecoration(
                    labelText: 'Sort by',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 4.h,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'code', child: Text('Code')),
                    DropdownMenuItem(value: 'user', child: Text('User')),
                    DropdownMenuItem(
                      value: 'createdAt',
                      child: Text('Created Date'),
                    ),
                    DropdownMenuItem(
                      value: 'expiresAt',
                      child: Text('Expires Date'),
                    ),
                    DropdownMenuItem(
                      value: 'paymentAmount',
                      child: Text('Amount'),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6.w),
              IconButton(
                onPressed: _toggleSortDirection,
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: AppColors.primary,
                  size: 18.sp,
                ),
                tooltip: _sortAscending ? 'Ascending' : 'Descending',
                constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.h),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildDateFilters(),
        ],
      ),
    );
  }

  Color _getStatusColor(AccessCode code) {
    if (code.isBlocked) return AppColors.error;
    if (code.isExpired) return AppColors.grey500;
    if (code.isUsed) return AppColors.warning;
    return AppColors.success;
  }

  int _getRemainingDays(AccessCode code) {
    if (code.isUsed || code.isExpired) return 0;

    final now = DateTime.now();
    final difference = code.expiresAt.difference(now);
    return difference.inDays > 0 ? difference.inDays : 0;
  }

  String _getUserDisplayName(AccessCode code) {
    final fullName = code.user?.fullName;
    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }
    return 'User ID: ${code.userId.substring(0, 8)}...';
  }
}
