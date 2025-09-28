import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../services/api_service.dart';

class StudyRemindersScreen extends ConsumerStatefulWidget {
  const StudyRemindersScreen({super.key});

  @override
  ConsumerState<StudyRemindersScreen> createState() =>
      _StudyRemindersScreenState();
}

class _StudyRemindersScreenState extends ConsumerState<StudyRemindersScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _enableReminders = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 19, minute: 0);
  List<String> _selectedDays = ['Monday', 'Wednesday', 'Friday'];
  int _studyGoal = 30; // minutes per day
  String? _reminderId;

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _loadStudyReminder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Reminders'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.schedule, size: 48.sp, color: AppColors.primary),
                  SizedBox(height: 16.h),
                  Text(
                    'Study Reminders',
                    style: AppTextStyles.heading2.copyWith(fontSize: 24.sp),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Set up reminders to maintain your study routine',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Enable Reminders
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: AppColors.primary,
                    size: 24.sp,
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enable Study Reminders',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Receive daily reminders to study',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _enableReminders,
                    onChanged: (value) {
                      setState(() {
                        _enableReminders = value;
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),

            if (_enableReminders) ...[
              SizedBox(height: 24.h),

              // Reminder Time
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reminder Time',
                      style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
                    ),
                    SizedBox(height: 16.h),

                    InkWell(
                      onTap: _selectTime,
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.grey300),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: AppColors.primary,
                              size: 20.sp,
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              _reminderTime.format(context),
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_drop_down,
                              color: AppColors.grey600,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Days of Week
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reminder Days',
                      style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
                    ),
                    SizedBox(height: 16.h),

                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: _daysOfWeek.map((day) {
                        final isSelected = _selectedDays.contains(day);
                        return FilterChip(
                          label: Text(day),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedDays.add(day);
                              } else {
                                _selectedDays.remove(day);
                              }
                            });
                          },
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.grey700,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Study Goal
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Study Goal',
                      style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
                    ),
                    SizedBox(height: 16.h),

                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: AppColors.primary,
                          size: 20.sp,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          '$_studyGoal minutes per day',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            if (_studyGoal > 5) {
                              setState(() {
                                _studyGoal -= 5;
                              });
                            }
                          },
                          icon: const Icon(Icons.remove),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.grey100,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        IconButton(
                          onPressed: () {
                            if (_studyGoal < 120) {
                              setState(() {
                                _studyGoal += 5;
                              });
                            }
                          },
                          icon: const Icon(Icons.add),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 32.h),

            // Save Button
            CustomButton(
              text: _reminderId == null ? 'Create Reminder' : 'Update Reminder',
              onPressed: _isLoading ? null : _saveReminders,
              backgroundColor: AppColors.primary,
              width: double.infinity,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  Future<void> _loadStudyReminder() async {
    try {
      final response = await _apiService.getStudyReminder();
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        setState(() {
          _reminderId = data['id'];
          _enableReminders = data['isEnabled'] ?? true;
          _studyGoal = data['studyGoalMinutes'] ?? 30;
          // Parse daysOfWeek - it might be a JSON string or already a list
          dynamic daysData = data['daysOfWeek'];
          if (daysData is String) {
            // Parse JSON string
            try {
              final List<dynamic> parsedDays = List<dynamic>.from(
                jsonDecode(daysData) ?? ['Monday', 'Wednesday', 'Friday']
              );
              _selectedDays = parsedDays.cast<String>();
            } catch (e) {
              print('Error parsing daysOfWeek JSON: $e');
              _selectedDays = ['Monday', 'Wednesday', 'Friday'];
            }
          } else if (daysData is List) {
            // Already a list
            _selectedDays = List<String>.from(daysData);
          } else {
            // Default fallback
            _selectedDays = ['Monday', 'Wednesday', 'Friday'];
          }

          // Parse reminder time
          final timeStr = data['reminderTime'] as String?;
          if (timeStr != null) {
            final parts = timeStr.split(':');
            if (parts.length == 2) {
              _reminderTime = TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );
            }
          }
        });
      }
    } catch (e) {
      print('Error loading study reminder: $e');
    }
  }

  Future<void> _saveReminders() async {
    if (!_enableReminders) {
      if (_reminderId != null) {
        await _deleteReminder();
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final reminderTime =
          '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}';

      if (_reminderId == null) {
        // Create new reminder
        final response = await _apiService.createStudyReminder(
          reminderTime: reminderTime,
          daysOfWeek: _selectedDays,
          studyGoalMinutes: _studyGoal,
        );

        if (response['success'] == true) {
          _reminderId = response['data']['id'];
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Study reminder created successfully'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          throw Exception(response['message'] ?? 'Failed to create reminder');
        }
      } else {
        // Update existing reminder
        final response = await _apiService.updateStudyReminder(_reminderId!, {
          'reminderTime': reminderTime,
          'daysOfWeek': _selectedDays,
          'studyGoalMinutes': _studyGoal,
          'isEnabled': _enableReminders,
        });

        if (response['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Study reminder updated successfully'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          throw Exception(response['message'] ?? 'Failed to update reminder');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save reminder: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteReminder() async {
    if (_reminderId == null) return;

    try {
      final response = await _apiService.deleteStudyReminder(_reminderId!);
      if (response['success'] == true) {
        setState(() {
          _reminderId = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Study reminder deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      print('Error deleting reminder: $e');
    }
  }
}
