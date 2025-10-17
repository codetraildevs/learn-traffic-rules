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

  List<AccessCode> _accessCodes = [];
  List<AccessCode> _filteredCodes = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  String _selectedSort = 'createdAt';
  bool _sortAscending = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAccessCodes();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
        title: const Text('Delete Access Code', style: AppTextStyles.heading3),
        content: Text(
          'Are you sure you want to delete access code ${code.code}? This action cannot be undone.',
          style: AppTextStyles.bodyMedium,
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
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: EdgeInsets.all(16.w),
            color: AppColors.white,
            child: Column(
              children: [
                // Search Bar
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

                // Filter and Sort Row
                Row(
                  children: [
                    // Filter Dropdown
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
                          DropdownMenuItem(
                            value: 'all',
                            child: Text(
                              'All Codes',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'active',
                            child: Text(
                              'Active',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'used',
                            child: Text(
                              'Used',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'expired',
                            child: Text(
                              'Expired',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'blocked',
                            child: Text(
                              'Blocked',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w),

                    // Sort Dropdown
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
                          DropdownMenuItem(
                            value: 'code',
                            child: Text(
                              'Code',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'user',
                            child: Text(
                              'User',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'createdAt',
                            child: Text(
                              'Created Date',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'expiresAt',
                            child: Text(
                              'Expires Date',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'paymentAmount',
                            child: Text(
                              'Amount',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w),

                    // Sort Direction Toggle
                    IconButton(
                      onPressed: _toggleSortDirection,
                      icon: Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: AppColors.primary,
                        size: 18.sp,
                      ),
                      tooltip: _sortAscending ? 'Ascending' : 'Descending',
                      constraints: BoxConstraints(
                        minWidth: 36.w,
                        minHeight: 36.h,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Access Codes List
          Expanded(
            child: _isLoading
                ? const Center(child: LoadingWidget())
                : _filteredCodes.isEmpty
                ? Center(
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
                : ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: _filteredCodes.length,
                    itemBuilder: (context, index) {
                      final code = _filteredCodes[index];
                      return _buildAccessCodeCard(code);
                    },
                  ),
          ),
        ],
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
