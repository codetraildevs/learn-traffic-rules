import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:learn_traffic_rules/core/theme/app_theme.dart';
import 'package:learn_traffic_rules/models/user_management_model.dart';
import 'package:learn_traffic_rules/services/user_management_service.dart';
import 'package:learn_traffic_rules/services/network_service.dart';
import 'package:learn_traffic_rules/widgets/loading_widget.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final UserManagementService _userManagementService = UserManagementService();
  final NetworkService _networkService = NetworkService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _listScrollController = ScrollController();

  List<UserWithStats> _users = [];
  List<UserWithStats> _filteredUsers = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  String _selectedSort = 'createdAt';
  bool _sortAscending = false; // false = descending (newest first)
  Timer? _refreshTimer;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _filterByToday = false;
  // Track called users - Map of user ID to call timestamp
  final Map<String, DateTime> _calledUsers = {};
  static const String _calledUsersPrefsKey = 'called_users_tracking';
  
  // Pagination state
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalUsers = 0;
  static const int _usersPerPage = 20;

  @override
  void initState() {
    super.initState();
    _loadCalledUsersFromPrefs();
    _loadUsers();
    _startRefreshTimer();
    // Sync call tracking with backend when online
    _syncCallTrackingWithBackend();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listScrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    // Refresh every 24 hours (86400000 milliseconds)
    _refreshTimer = Timer.periodic(const Duration(hours: 24), (timer) {
      if (mounted) {
        _loadUsers();
      }
    });
  }

  Future<void> _loadUsers({int? page}) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final pageToLoad = page ?? _currentPage;
      debugPrint('🔄 Loading users (page $pageToLoad)...');
      
      // Convert sort direction to backend format
      final sortOrder = _sortAscending ? 'ASC' : 'DESC';
      
      // Convert filter to role or filter type
      String roleFilter = '';
      String filterType = '';
      if (_selectedFilter == 'user') {
        roleFilter = 'USER';
      } else if (_selectedFilter == 'manager') {
        roleFilter = 'MANAGER';
      } else if (_selectedFilter == 'admin') {
        roleFilter = 'ADMIN';
      } else if (_selectedFilter == 'with_code' || 
                 _selectedFilter == 'without_code' ||
                 _selectedFilter == 'called' ||
                 _selectedFilter == 'not_called') {
        filterType = _selectedFilter;
      }
      
      // Prepare date filters (format as YYYY-MM-DD)
      String? startDateStr;
      String? endDateStr;
      if (_startDate != null) {
        startDateStr = '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}';
      }
      if (_endDate != null) {
        endDateStr = '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}';
      }
      
      final response = await _userManagementService.getAllUsers(
        page: pageToLoad,
        limit: _usersPerPage,
        search: _searchQuery,
        role: roleFilter,
        sortBy: _selectedSort,
        sortOrder: sortOrder,
        filter: filterType,
        startDate: startDateStr,
        endDate: endDateStr,
        filterByToday: _filterByToday,
      );
      
      debugPrint('🔄 Users response: ${response.data.users.length} users');
      debugPrint('🔄 Pagination: ${response.data.pagination.total} total, page ${response.data.pagination.page}/${response.data.pagination.totalPages}');

      if (response.success) {
        debugPrint('🔄 Users data: ${response.data.users.length} users');
        // Debug: Print user blocking status
        for (var user in response.data.users) {
          debugPrint(
            '👤 User: ${user.fullName}, isBlocked: ${user.isBlocked}, blockReason: ${user.blockReason ?? 'None'}',
          );
        }
        if (mounted) {
          setState(() {
            _users = response.data.users;
            _currentPage = response.data.pagination.page;
            _totalPages = response.data.pagination.totalPages;
            _totalUsers = response.data.pagination.total;
            // All filters are now handled by backend, just filter out test admin
            _applyClientSideFilters();
          });
        }
        
        // Sync call tracking after loading users (to get latest from server)
        _syncCallTrackingWithBackend();
      } else {
        debugPrint('❌ Failed to load users: ${response.message}');
      }
    } catch (e) {
      debugPrint('❌ Error loading users: $e');
      _showErrorSnackBar('Failed to load users: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyClientSideFilters() {
    List<UserWithStats> filtered = List.from(_users);

    // Filter out only the test admin user (0780000000), but show all other users including ADMINs
    filtered = filtered
        .where((user) => user.phoneNumber.toString() != '0780000000')
        .toList();

    // All filters (search, role, date, access code, call tracking) are now handled by backend
    // We only filter out the test admin user client-side

    // Note: Sorting is now handled by backend, no need to sort client-side

    if (mounted) {
      setState(() {
        _filteredUsers = filtered;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTop());
    }
  }

  void _scrollToTop() {
    if (!_listScrollController.hasClients) return;
    _listScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1; // Reset to first page on search
    });
    _loadUsers(page: 1);
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _currentPage = 1; // Reset to first page on filter change
    });
    _loadUsers(page: 1);
  }

  void _onSortChanged(String sort) {
    setState(() {
      _selectedSort = sort;
      _currentPage = 1; // Reset to first page on sort change
    });
    _loadUsers(page: 1);
  }

  void _toggleSortDirection() {
    setState(() {
      _sortAscending = !_sortAscending;
      _currentPage = 1; // Reset to first page on sort direction change
    });
    _loadUsers(page: 1);
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
        _currentPage = 1; // Reset to first page on date filter
      });
      _loadUsers(page: 1);
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
        _currentPage = 1; // Reset to first page on date filter
      });
      _loadUsers(page: 1);
    }
  }

  void _toggleTodayFilter() {
    setState(() {
      _filterByToday = !_filterByToday;
      if (_filterByToday) {
        _startDate = null;
        _endDate = null;
      }
      _currentPage = 1; // Reset to first page on date filter
    });
    _loadUsers(page: 1);
  }

  void _clearDateFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _filterByToday = false;
      _currentPage = 1; // Reset to first page on clear
    });
    _loadUsers(page: 1);
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

  Future<void> _generateAccessCode(UserWithStats user) async {
    try {
      debugPrint(
        '🔍 Generating access code for user: ${user.fullName} (ID: ${user.id})',
      );

      // Show payment tier selection dialog
      final selectedTier = await _showPaymentTierDialog();
      if (selectedTier == null) return;

      debugPrint(
        '🔍 Selected tier: ${selectedTier['name']} - ${selectedTier['amount']} RWF',
      );

      final response = await _userManagementService.createAccessCodeForUser(
        user.id,
        selectedTier['amount'].toDouble(),
      );

      if (response.success) {
        _showSuccessSnackBar(
          'Access code generated successfully for ${user.fullName}',
        );
        _loadUsers(); // Refresh the list
      } else {
        _showErrorSnackBar(
          'Failed to generate access code: ${response.message}',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error generating access code: $e');
    }
  }

  Future<Map<String, dynamic>?> _showPaymentTierDialog() async {
    final tiers = [
      {
        'tier': '1_MONTH',
        'amount': 1500,
        'days': 30,
        'label': '1 Month - 1500 RWF',
      },
      {
        'tier': '3_MONTHS',
        'amount': 3000,
        'days': 90,
        'label': '3 Months - 3000 RWF',
      },
      {
        'tier': '6_MONTHS',
        'amount': 5000,
        'days': 180,
        'label': '6 Months - 5000 RWF',
      },
    ];

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Payment Tier', style: AppTextStyles.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: tiers
              .map(
                (tier) => ListTile(
                  title: Text(
                    tier['label'] as String,
                    style: AppTextStyles.bodyMedium,
                  ),
                  onTap: () => Navigator.pop(context, tier),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(UserWithStats user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: AppColors.error, size: 24.sp),
            SizedBox(width: 8.w),
            const Text('Delete User'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete ${user.fullName}?',
              style: AppTextStyles.bodyMedium,
            ),
            SizedBox(height: 8.h),
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
                  Icon(Icons.warning, color: AppColors.error, size: 16.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. The user and all their data will be permanently removed.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (user.accessCodeStats.active > 0) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: AppColors.warning, size: 16.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'This user has active access codes. Please delete them first.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: user.accessCodeStats.active > 0
                ? null
                : () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _userManagementService.deleteUser(user.id);
        if (response['success'] == true) {
          _showSuccessSnackBar('User ${user.fullName} deleted successfully');
          _loadUsers(); // Refresh the list
        } else {
          _showErrorSnackBar(
            'Failed to delete user: ${response['message'] ?? 'Unknown error'}',
          );
        }
      } catch (e) {
        _showErrorSnackBar('Error deleting user: $e');
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('User Management', style: AppTextStyles.heading2),
            if (_totalUsers > 0)
              Text(
                '$_totalUsers users',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.white.withValues(alpha: 0.8),
                  fontSize: 12.sp,
                ),
              ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _loadUsers(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUsers,
        child: CustomScrollView(
          controller: _listScrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildFilterSection()),
            if (_isLoading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: const Center(child: LoadingWidget()),
              )
            else if (_filteredUsers.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64.sp,
                      color: AppColors.grey400,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'No users found matching "$_searchQuery"'
                          : 'No users found',
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
                    final user = _filteredUsers[index];
                    return _buildUserCard(user);
                  }, childCount: _filteredUsers.length),
                ),
              ),
            // Pagination controls
            SliverToBoxAdapter(child: _buildPaginationControls()),
            // Total users count
            SliverToBoxAdapter(child: _buildTotalUsersCount()),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserWithStats user) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.white, AppColors.grey50],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Responsive layout based on available width
              bool isCompact = constraints.maxWidth < 350;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Blocked Status Banner (if blocked)
                  if (user.isBlocked == true)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.r),
                          topRight: Radius.circular(16.r),
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.block,
                            color: AppColors.error,
                            size: 18.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'BLOCKED${user.blockReason != null && user.blockReason!.isNotEmpty ? ': ${user.blockReason}' : ''}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Header Row with Avatar and User Info
                  Row(
                    children: [
                      // Avatar with gradient
                      Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              user.isBlocked == true
                                  ? AppColors.error
                                  : AppColors.secondary,
                              (user.isBlocked == true
                                      ? AppColors.error
                                      : AppColors.primary)
                                  .withValues(alpha: 0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (user.isBlocked == true
                                          ? AppColors.error
                                          : AppColors.primary)
                                      .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : 'U',
                            style: AppTextStyles.heading2.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),

                      // User Info - Name and Phone in Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name - More prominent
                            Text(
                              user.fullName,
                              style: AppTextStyles.heading2.copyWith(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: user.isBlocked == true
                                    ? AppColors.error
                                    : AppColors.grey800,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            // Phone - Clickable for calling
                            GestureDetector(
                              onTap: () =>
                                  _makePhoneCall(user.phoneNumber, user),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: _isUserCalled(user.id)
                                      ? AppColors.success.withValues(alpha: 0.1)
                                      : AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: _isUserCalled(user.id)
                                        ? AppColors.success.withValues(
                                            alpha: 0.3,
                                          )
                                        : AppColors.primary.withValues(
                                            alpha: 0.3,
                                          ),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isUserCalled(user.id)
                                          ? Icons.phone_callback
                                          : Icons.phone,
                                      size: 16.sp,
                                      color: _isUserCalled(user.id)
                                          ? AppColors.success
                                          : AppColors.primary,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      user.phoneNumber,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: _isUserCalled(user.id)
                                            ? AppColors.success
                                            : AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    if (_isUserCalled(user.id)) ...[
                                      SizedBox(width: 4.w),
                                      Icon(
                                        Icons.check_circle,
                                        size: 14.sp,
                                        color: AppColors.success,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            // Role Badge
                            // Container(
                            //   padding: EdgeInsets.symmetric(
                            //     horizontal: 12.w,
                            //     vertical: 4.h,
                            //   ),
                            //   decoration: BoxDecoration(
                            //     color: _getRoleColor(
                            //       user.role,
                            //     ).withValues(alpha: 0.1),
                            //     borderRadius: BorderRadius.circular(20.r),
                            //     border: Border.all(
                            //       color: _getRoleColor(
                            //         user.role,
                            //       ).withValues(alpha: 0.3),
                            //       width: 1,
                            //     ),
                            //   ),
                            //   child: Text(
                            //     user.role.toUpperCase(),
                            //     style: AppTextStyles.caption.copyWith(
                            //       color: _getRoleColor(user.role),
                            //       fontSize: 10.sp,
                            //       fontWeight: FontWeight.bold,
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  //  SizedBox(height: 8.h),

                  // Action Buttons Row - Responsive
                  if (isCompact) ...[
                    // Compact layout: Stack buttons vertically
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                              icon: Icons.vpn_key,
                              color: AppColors.warning,
                              onPressed: () => _generateAccessCode(user),
                              tooltip: 'Generate Access Code',
                            ),
                            _buildActionButton(
                              icon: user.isBlocked == true
                                  ? Icons.check_circle
                                  : Icons.block,
                              color: user.isBlocked == true
                                  ? AppColors.success
                                  : AppColors.grey700,
                              onPressed: () => _showBlockUserDialog(user),
                              tooltip: user.isBlocked == true
                                  ? 'Unblock User'
                                  : 'Block User',
                            ),
                            _buildActionButton(
                              icon: Icons.delete_outline,
                              color: AppColors.error,
                              onPressed: () => _deleteUser(user),
                              tooltip: 'Delete User',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ] else ...[
                    // Normal layout: All buttons in one row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.vpn_key,
                          color: AppColors.warning,
                          onPressed: () => _generateAccessCode(user),
                          tooltip: 'Generate Access Code',
                        ),
                        _buildActionButton(
                          icon: user.isBlocked == true
                              ? Icons.check_circle
                              : Icons.block,
                          color: user.isBlocked == true
                              ? AppColors.success
                              : AppColors.error,
                          onPressed: () => _showBlockUserDialog(user),
                          tooltip: user.isBlocked == true
                              ? 'Unblock User'
                              : 'Block User',
                        ),
                        _buildActionButton(
                          icon: Icons.delete_outline,
                          color: AppColors.grey600,
                          onPressed: () => _deleteUser(user),
                          tooltip: 'Delete User',
                        ),
                      ],
                    ),
                  ],

                  SizedBox(height: 16.h),

                  // Stats Row
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      // _buildStatChip(
                      //   Icons.calendar_today,
                      //   'Created: ${DateFormat('MMM dd, yyyy').format(user.createdAt)}',
                      //   AppColors.info,
                      // ),
                      // _buildStatChip(
                      //   Icons.login,
                      //   'Last Login: ${user.lastLogin != null ? DateFormat('MMM dd, yyyy').format(user.lastLogin!) : 'Never'}',
                      //   AppColors.success,
                      // ),
                      _buildStatChip(
                        Icons.calendar_today,
                        'Created: ${DateFormat('MMM dd, yyyy').format(user.createdAt)}',
                        AppColors.info,
                      ),
                      if (user.lastLogin != null)
                        _buildStatChip(
                          Icons.login,
                          'Last Login: ${DateFormat('MMM dd, yyyy').format(user.lastLogin!)}',
                          AppColors.success,
                        ),
                      if (user.remainingDays > 0)
                        _buildStatChip(
                          Icons.schedule,
                          '${user.remainingDays} days left',
                          AppColors.warning,
                        ),
                      if (user.expiresAt != null)
                        _buildStatChip(
                          Icons.calendar_today,
                          'Expires at: ${DateFormat('MMM dd, yyyy').format(user.expiresAt!)}',
                          AppColors.grey600,
                        ),
                      if (user.isBlocked == true)
                        _buildStatChip(
                          Icons.block,
                          'Blocked${user.blockReason != null && user.blockReason!.isNotEmpty ? ': ${user.blockReason}' : ''}',
                          AppColors.error,
                        ),
                      if (_isUserCalled(user.id))
                        _buildStatChip(
                          Icons.phone_callback,
                          'Called${_getCallTimestamp(user.id) != null ? ' ${_formatCallTime(_getCallTimestamp(user.id)!)}' : ''}',
                          AppColors.success,
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 20.sp),
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          shape: const CircleBorder(),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 6.w),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCallTime(DateTime callTime) {
    final now = DateTime.now();
    final difference = now.difference(callTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(callTime);
    }
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
              hintText: 'Search users...',
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
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 400) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedFilter,
                            onChanged: (value) => _onFilterChanged(value!),
                            decoration: InputDecoration(
                              labelText: 'Filter',
                              labelStyle: TextStyle(fontSize: 10.sp),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All Users'),
                              ),
                              DropdownMenuItem(
                                value: 'user',
                                child: Text('Users'),
                              ),
                              DropdownMenuItem(
                                value: 'manager',
                                child: Text('Managers'),
                              ),
                              DropdownMenuItem(
                                value: 'with_code',
                                child: Text('With Code'),
                              ),
                              DropdownMenuItem(
                                value: 'without_code',
                                child: Text('No Code'),
                              ),
                              DropdownMenuItem(
                                value: 'called',
                                child: Text('Called'),
                              ),
                              DropdownMenuItem(
                                value: 'not_called',
                                child: Text('Not Called'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedSort,
                            onChanged: (value) => _onSortChanged(value!),
                            decoration: InputDecoration(
                              labelText: 'Sort',
                              labelStyle: TextStyle(fontSize: 10.sp),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'name',
                                child: Text('Name'),
                              ),
                              DropdownMenuItem(
                                value: 'role',
                                child: Text('Role'),
                              ),
                              DropdownMenuItem(
                                value: 'createdAt',
                                child: Text('Created'),
                              ),
                              DropdownMenuItem(
                                value: 'lastLogin',
                                child: Text('Last Login'),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        IconButton(
                          onPressed: _toggleSortDirection,
                          icon: Icon(
                            _sortAscending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: AppColors.primary,
                            size: 16.sp,
                          ),
                          tooltip: _sortAscending ? 'Ascending' : 'Descending',
                          padding: EdgeInsets.all(4.w),
                          constraints: BoxConstraints(
                            minWidth: 32.w,
                            minHeight: 32.h,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        onChanged: (value) => _onFilterChanged(value!),
                        decoration: InputDecoration(
                          labelText: 'Filter',
                          labelStyle: TextStyle(fontSize: 10.sp),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('All Users'),
                          ),
                          DropdownMenuItem(value: 'user', child: Text('Users')),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Admins'),
                          ),
                          DropdownMenuItem(
                            value: 'manager',
                            child: Text('Managers'),
                          ),
                          DropdownMenuItem(
                            value: 'with_code',
                            child: Text('With Code'),
                          ),
                          DropdownMenuItem(
                            value: 'without_code',
                            child: Text('No Code'),
                          ),
                          DropdownMenuItem(
                            value: 'called',
                            child: Text('Called'),
                          ),
                          DropdownMenuItem(
                            value: 'not_called',
                            child: Text('Not Called'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedSort,
                        onChanged: (value) => _onSortChanged(value!),
                        decoration: InputDecoration(
                          labelText: 'Sort',
                          labelStyle: TextStyle(fontSize: 10.sp),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'name', child: Text('Name')),
                          DropdownMenuItem(value: 'role', child: Text('Role')),
                          DropdownMenuItem(
                            value: 'createdAt',
                            child: Text('Created'),
                          ),
                          DropdownMenuItem(
                            value: 'lastLogin',
                            child: Text('Last Login'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w),
                    IconButton(
                      onPressed: _toggleSortDirection,
                      icon: Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: AppColors.primary,
                        size: 16.sp,
                      ),
                      tooltip: _sortAscending ? 'Ascending' : 'Descending',
                      padding: EdgeInsets.all(4.w),
                      constraints: BoxConstraints(
                        minWidth: 32.w,
                        minHeight: 32.h,
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          SizedBox(height: 12.h),
          _buildDateFilters(),
        ],
      ),
    );
  }

  void _makePhoneCall(String phoneNumber, UserWithStats user) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        // Mark user as called and persist locally
        setState(() {
          _calledUsers[user.id] = DateTime.now();
        });
        await _saveCalledUsersToPrefs();
        
        // Sync with backend if online (works offline, syncs when online)
        _syncCallTrackingWithBackend();
        
        _showSuccessSnackBar('Calling ${user.fullName}...');
        debugPrint('📞 Marked user ${user.fullName} (${user.id}) as called');
      } else {
        _showErrorSnackBar('Could not make phone call to $phoneNumber');
      }
    } catch (e) {
      _showErrorSnackBar('Error making phone call: $e');
    }
  }

  /// Load called users from SharedPreferences
  Future<void> _loadCalledUsersFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final calledUsersJson = prefs.getString(_calledUsersPrefsKey);
      if (calledUsersJson != null) {
        final Map<String, dynamic> calledUsersMap =
            json.decode(calledUsersJson) as Map<String, dynamic>;
        setState(() {
          _calledUsers.clear();
          calledUsersMap.forEach((userId, timestampStr) {
            try {
              _calledUsers[userId] = DateTime.parse(timestampStr as String);
            } catch (e) {
              debugPrint(
                '⚠️ Error parsing call timestamp for user $userId: $e',
              );
            }
          });
        });
        debugPrint(
          '✅ Loaded ${_calledUsers.length} called users from SharedPreferences',
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading called users from SharedPreferences: $e');
    }
  }

  /// Sync call tracking with backend (works offline, syncs when online)
  Future<void> _syncCallTrackingWithBackend() async {
    try {
      final hasInternet = await _networkService.hasInternetConnection();
      if (!hasInternet) {
        debugPrint('📞 No internet - call tracking saved locally, will sync when online');
        return;
      }

      // Convert local called users to Map<String, String> for API
      final Map<String, String> localCalledUsers = {};
      _calledUsers.forEach((userId, timestamp) {
        localCalledUsers[userId] = timestamp.toIso8601String();
      });

      // Sync with backend
      final syncedCalledUsers = await _userManagementService.syncCallTracking(localCalledUsers);
      
      // Update local state with merged data from server
      setState(() {
        _calledUsers.clear();
        syncedCalledUsers.forEach((userId, timestampStr) {
          try {
            _calledUsers[userId] = DateTime.parse(timestampStr);
          } catch (e) {
            debugPrint('⚠️ Error parsing synced timestamp for user $userId: $e');
          }
        });
      });

      // Save synced data to SharedPreferences
      await _saveCalledUsersToPrefs();

      debugPrint('✅ Synced ${_calledUsers.length} called users with backend');
    } catch (e) {
      debugPrint('❌ Error syncing call tracking with backend: $e');
      // Continue with local data if sync fails
    }
  }

  /// Save called users to SharedPreferences
  Future<void> _saveCalledUsersToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, String> calledUsersMap = {};
      _calledUsers.forEach((userId, timestamp) {
        calledUsersMap[userId] = timestamp.toIso8601String();
      });
      await prefs.setString(_calledUsersPrefsKey, json.encode(calledUsersMap));
      debugPrint(
        '✅ Saved ${_calledUsers.length} called users to SharedPreferences',
      );
    } catch (e) {
      debugPrint('❌ Error saving called users to SharedPreferences: $e');
    }
  }

  bool _isUserCalled(String userId) {
    return _calledUsers.containsKey(userId);
  }

  DateTime? _getCallTimestamp(String userId) {
    return _calledUsers[userId];
  }

  Widget _buildTotalUsersCount() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      color: AppColors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, color: AppColors.primary, size: 20.sp),
          SizedBox(width: 8.w),
          Text(
            'Total Users: $_totalUsers',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    if (_totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      color: AppColors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          IconButton(
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                    _loadUsers(page: _currentPage);
                    _scrollToTop();
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous page',
          ),
          SizedBox(width: 8.w),
          
          // Page numbers
          ...List.generate(
            _totalPages > 5 ? 5 : _totalPages,
            (index) {
              int pageNumber;
              if (_totalPages <= 5) {
                pageNumber = index + 1;
              } else {
                // Show current page and 2 pages on each side
                if (_currentPage <= 3) {
                  pageNumber = index + 1;
                } else if (_currentPage >= _totalPages - 2) {
                  pageNumber = _totalPages - 4 + index;
                } else {
                  pageNumber = _currentPage - 2 + index;
                }
              }

              final isCurrentPage = pageNumber == _currentPage;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _currentPage = pageNumber;
                    });
                    _loadUsers(page: pageNumber);
                    _scrollToTop();
                  },
                  borderRadius: BorderRadius.circular(8.r),
                  child: Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: isCurrentPage
                          ? AppColors.primary
                          : AppColors.grey100,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: isCurrentPage
                            ? AppColors.primary
                            : AppColors.grey300,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$pageNumber',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isCurrentPage
                              ? AppColors.white
                              : AppColors.grey800,
                          fontWeight: isCurrentPage
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Show ellipsis if there are more pages
          if (_totalPages > 5 && _currentPage < _totalPages - 2)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                '...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.grey600,
                ),
              ),
            ),
          
          // Show last page if not in visible range
          if (_totalPages > 5 && _currentPage < _totalPages - 2)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _currentPage = _totalPages;
                  });
                  _loadUsers(page: _totalPages);
                  _scrollToTop();
                },
                borderRadius: BorderRadius.circular(8.r),
                child: Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.grey300),
                  ),
                  child: Center(
                    child: Text(
                      '$_totalPages',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          SizedBox(width: 8.w),
          
          // Next button
          IconButton(
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                    _loadUsers(page: _currentPage);
                    _scrollToTop();
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next page',
          ),
        ],
      ),
    );
  }

  void _showBlockUserDialog(UserWithStats user) {
    final TextEditingController reasonController = TextEditingController();
    final bool isCurrentlyBlocked = user.isBlocked ?? false;

    // Debug: Print user blocking status
    debugPrint('🔒 Block dialog for user: ${user.fullName}');
    debugPrint('🔒 isBlocked: ${user.isBlocked}');
    debugPrint('🔒 isCurrentlyBlocked: $isCurrentlyBlocked');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isCurrentlyBlocked ? Icons.check_circle : Icons.block,
              color: isCurrentlyBlocked ? AppColors.success : AppColors.error,
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            Text(isCurrentlyBlocked ? 'Unblock User' : 'Block User'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCurrentlyBlocked
                  ? 'Are you sure you want to unblock ${user.fullName}?'
                  : 'Are you sure you want to block ${user.fullName}?',
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color:
                    (isCurrentlyBlocked ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color:
                      (isCurrentlyBlocked ? AppColors.success : AppColors.error)
                          .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCurrentlyBlocked ? Icons.info : Icons.warning,
                    color: isCurrentlyBlocked
                        ? AppColors.success
                        : AppColors.error,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      isCurrentlyBlocked
                          ? 'Unblocked users will regain access to the system.'
                          : 'Blocked users will not be able to access the system.',
                      style: AppTextStyles.caption.copyWith(
                        color: isCurrentlyBlocked
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isCurrentlyBlocked) ...[
              SizedBox(height: 16.h),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason for blocking (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _blockUser(
                user,
                !isCurrentlyBlocked,
                reasonController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyBlocked
                  ? AppColors.success
                  : AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: Text(isCurrentlyBlocked ? 'Unblock User' : 'Block User'),
          ),
        ],
      ),
    );
  }

  Future<void> _blockUser(
    UserWithStats user,
    bool isBlocked,
    String blockReason,
  ) async {
    final bool isCurrentlyBlocked = user.isBlocked ?? false;
    try {
      final response = await _userManagementService.blockUser(
        user.id,
        isBlocked,
        blockReason: blockReason.isNotEmpty ? blockReason : null,
      );

      if (response['success'] == true) {
        _showSuccessSnackBar(
          'User ${isCurrentlyBlocked ? 'unblocked' : 'blocked'} successfully',
        );
        _loadUsers(); // Refresh the list
      } else {
        _showErrorSnackBar(
          'Failed to ${isCurrentlyBlocked ? 'unblock' : 'block'} user: ${response['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      _showErrorSnackBar(
        'Error ${isCurrentlyBlocked ? 'unblocking' : 'blocking'} user: $e',
      );
    }
  }
}

class _PaymentTierDialog extends StatefulWidget {
  final UserWithStats user;
  final Function(double) onGenerate;

  const _PaymentTierDialog({required this.user, required this.onGenerate});

  @override
  State<_PaymentTierDialog> createState() => _PaymentTierDialogState();
}

class _PaymentTierDialogState extends State<_PaymentTierDialog> {
  double _selectedAmount = 1500.0;
  final List<Map<String, dynamic>> _paymentTiers = [
    {
      'amount': 1500.0,
      'days': 30,
      'description': '1 Month Access',
      'color': AppColors.primary,
    },
    {
      'amount': 3000.0,
      'days': 90,
      'description': '3 Months Access',
      'color': AppColors.success,
    },
    {
      'amount': 5000.0,
      'days': 180,
      'description': '6 Months Access',
      'color': AppColors.warning,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.vpn_key, color: AppColors.primary, size: 24.sp),
          SizedBox(width: 8.w),
          const Text('Generate Access Code'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select payment tier for ${widget.user.fullName}:',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          ..._paymentTiers.map((tier) => _buildTierOption(tier)),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: AppColors.primary, size: 16.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Access code will be valid for ${_paymentTiers.firstWhere((tier) => tier['amount'] == _selectedAmount)['days']} days',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => widget.onGenerate(_selectedAmount),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
          ),
          child: const Text('Generate Code'),
        ),
      ],
    );
  }

  Widget _buildTierOption(Map<String, dynamic> tier) {
    final isSelected = tier['amount'] == _selectedAmount;
    final color = tier['color'] as Color;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: () => setState(() => _selectedAmount = tier['amount']),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : AppColors.grey50,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? color : AppColors.grey300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20.w,
                height: 20.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? color : AppColors.grey300,
                ),
                child: isSelected
                    ? Icon(Icons.check, color: AppColors.white, size: 12.sp)
                    : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tier['description'],
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? color : AppColors.grey800,
                      ),
                    ),
                    Text(
                      '${tier['amount']} RWF',
                      style: AppTextStyles.caption.copyWith(
                        color: isSelected ? color : AppColors.grey600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${tier['duration']} days',
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
