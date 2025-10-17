import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:learn_traffic_rules/core/theme/app_theme.dart';
import 'package:learn_traffic_rules/models/user_management_model.dart';
import 'package:learn_traffic_rules/services/user_management_service.dart';
import 'package:learn_traffic_rules/widgets/loading_widget.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final UserManagementService _userManagementService = UserManagementService();
  final TextEditingController _searchController = TextEditingController();

  List<UserWithStats> _users = [];
  List<UserWithStats> _filteredUsers = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  String _selectedSort = 'name';
  bool _sortAscending = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadUsers();
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
        _loadUsers();
      }
    });
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🔄 Loading users...');
      final response = await _userManagementService.getAllUsers();
      debugPrint('🔄 Users response: ${response.data.users.length} users');

      if (response.success) {
        debugPrint('🔄 Users data: ${response.data.users.length} users');
        // Debug: Print user blocking status
        for (var user in response.data.users) {
          debugPrint(
            '👤 User: ${user.fullName}, isBlocked: ${user.isBlocked}, blockReason: ${user.blockReason ?? 'None'}',
          );
        }
        setState(() {
          _users = response.data.users;
          _filteredUsers = _users;
        });
        _applyFiltersAndSort();
      } else {
        debugPrint('❌ Failed to load users: ${response.message}');
      }
    } catch (e) {
      debugPrint('❌ Error loading users: $e');
      _showErrorSnackBar('Failed to load users: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    List<UserWithStats> filtered = List.from(_users);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        return user.fullName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            user.phoneNumber.contains(_searchQuery) ||
            user.role.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply role filter
    if (_selectedFilter != 'all') {
      if (_selectedFilter == 'with_code') {
        filtered = filtered
            .where((user) => user.accessCodeStats.active > 0)
            .toList();
      } else if (_selectedFilter == 'without_code') {
        filtered = filtered
            .where((user) => user.accessCodeStats.active == 0)
            .toList();
      } else {
        filtered = filtered
            .where((user) => user.role.toLowerCase() == _selectedFilter)
            .toList();
      }
    }

    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_selectedSort) {
        case 'name':
          comparison = a.fullName.compareTo(b.fullName);
          break;
        case 'role':
          comparison = a.role.compareTo(b.role);
          break;
        case 'createdAt':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'lastLogin':
          comparison =
              a.lastLogin?.compareTo(b.lastLogin ?? DateTime(1970)) ?? 0;
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    setState(() {
      _filteredUsers = filtered;
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
        title: const Text('User Management', style: AppTextStyles.heading2),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadUsers,
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

                // Filter and Sort Row - Responsive Layout
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Use different layouts based on screen width
                    if (constraints.maxWidth < 400) {
                      // Small screens: Stack vertically
                      return Column(
                        children: [
                          // Filter Row
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedFilter,
                                  onChanged: (value) =>
                                      _onFilterChanged(value!),
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
                                      child: Text(
                                        'All Users',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'user',
                                      child: Text(
                                        'Users',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'admin',
                                      child: Text(
                                        'Admins',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'manager',
                                      child: Text(
                                        'Managers',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'with_code',
                                      child: Text(
                                        'With Code',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'without_code',
                                      child: Text(
                                        'No Code',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          // Sort Row
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedSort,
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
                                      child: Text(
                                        'Name',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'role',
                                      child: Text(
                                        'Role',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'createdAt',
                                      child: Text(
                                        'Created',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'lastLogin',
                                      child: Text(
                                        'Last Login',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),
                              // Sort Direction Toggle
                              IconButton(
                                onPressed: _toggleSortDirection,
                                icon: Icon(
                                  _sortAscending
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: AppColors.primary,
                                  size: 16.sp,
                                ),
                                tooltip: _sortAscending
                                    ? 'Ascending'
                                    : 'Descending',
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
                      // Larger screens: Horizontal layout
                      return Row(
                        children: [
                          // Filter Dropdown
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedFilter,
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
                                  child: Text(
                                    'All Users',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'user',
                                  child: Text(
                                    'Users',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'admin',
                                  child: Text(
                                    'Admins',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'manager',
                                  child: Text(
                                    'Managers',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'with_code',
                                  child: Text(
                                    'With Code',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'without_code',
                                  child: Text(
                                    'No Code',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 6.w),

                          // Sort Dropdown
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedSort,
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
                                DropdownMenuItem(
                                  value: 'name',
                                  child: Text(
                                    'Name',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'role',
                                  child: Text(
                                    'Role',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'createdAt',
                                  child: Text(
                                    'Created',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'lastLogin',
                                  child: Text(
                                    'Last Login',
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
                              size: 16.sp,
                            ),
                            tooltip: _sortAscending
                                ? 'Ascending'
                                : 'Descending',
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
              ],
            ),
          ),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: LoadingWidget())
                : _filteredUsers.isEmpty
                ? Center(
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
                : ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return _buildUserCard(user);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserWithStats user) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
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
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
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
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.grey800,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            // Phone - Clickable for calling
                            GestureDetector(
                              onTap: () => _makePhoneCall(user.phoneNumber),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.phone,
                                      size: 16.sp,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      user.phoneNumber,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
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
                      _buildStatChip(
                        Icons.calendar_today,
                        'Created: ${DateFormat('MMM dd, yyyy').format(user.createdAt)}',
                        AppColors.info,
                      ),
                      _buildStatChip(
                        Icons.login,
                        'Last Login: ${user.lastLogin != null ? DateFormat('MMM dd, yyyy').format(user.lastLogin!) : 'Never'}',
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
                      // if (user.isBlocked == true)
                      //   _buildStatChip(Icons.block, 'Blocked', AppColors.error),
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

  void _makePhoneCall(String phoneNumber) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showErrorSnackBar('Could not make phone call to $phoneNumber');
      }
    } catch (e) {
      _showErrorSnackBar('Error making phone call: $e');
    }
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
