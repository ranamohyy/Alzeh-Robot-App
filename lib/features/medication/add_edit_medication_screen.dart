// lib/features/medication/add_edit_medication_screen.dart - UPDATED

import 'package:alzeh/core/resources/barallel.dart';
import 'package:alzeh/core/services/firebase_service.dart';
import 'package:alzeh/features/model/medication_model.dart';
import 'package:flutter/material.dart';

class AddEditMedicationScreen extends StatefulWidget {
  const AddEditMedicationScreen({super.key, this.medication});
  final MedicationModel? medication;

  @override
  State<AddEditMedicationScreen> createState() =>
      _AddEditMedicationScreenState();
}

class _AddEditMedicationScreenState extends State<AddEditMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _timeController = TextEditingController();
  final _totalPillsController = TextEditingController();
  final _pillsToDispenseController = TextEditingController();

  bool _isLoading = false;
  String _selectedUnit = 'pills';
  String _selectedFrequency = 'daily';
  int _selectedSlot = 0;
  TimeOfDay? _selectedTime;

  // Frequency options
  final List<Map<String, String>> _frequencyOptions = [
    {'value': 'daily', 'label': 'Daily', 'icon': '📅'},
    {'value': 'weekly', 'label': 'Weekly', 'icon': '📆'},
    {'value': 'monthly', 'label': 'Monthly', 'icon': '🗓️'},
    {'value': 'custom', 'label': 'Custom', 'icon': '⚙️'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      _nameController.text = widget.medication!.name;
      _timeController.text = widget.medication!.time;
      _selectedFrequency = widget.medication!.frequency;
      _totalPillsController.text = widget.medication!.totalPills.toString();
      _pillsToDispenseController.text = widget.medication!.pillsToDispense.toString();
      _selectedUnit = widget.medication!.unit;
      _selectedSlot = widget.medication!.slotNumber;
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate pill counts
    int totalPills = int.parse(_totalPillsController.text);
    int toDispense = int.parse(_pillsToDispenseController.text);

    if (toDispense > totalPills) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pills to dispense cannot exceed total pills!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final medication = MedicationModel(
      id: widget.medication?.id,
      name: _nameController.text.trim(),
      time: _timeController.text,
      frequency: _selectedFrequency,
      totalPills: totalPills,
      pillsToDispense: toDispense,
      remainingPills: widget.medication?.remainingPills ?? totalPills, // Keep existing or use total
      unit: _selectedUnit,
      slotNumber: _selectedSlot,
      enabled: true,
      lastRefillDate: widget.medication?.lastRefillDate ?? DateTime.now().millisecondsSinceEpoch,
    );

    bool success;
    String message;

    if (widget.medication == null) {
      final id = await FirebaseService.addMedication(medication);
      success = id != null;
      message = success
          ? '✓ Medication added!\nESP32 will sync automatically'
          : '❌ Failed to add medication';
    } else {
      success = await FirebaseService.updateMedication(medication);
      message = success
          ? '✓ Medication updated!\nESP32 will sync automatically'
          : '❌ Failed to update medication';
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      await showSuccessDialog(context, message);
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => closeKeyboard(context),
      child: Scaffold(
        backgroundColor: AppColors.bgColor,
        appBar: CustomAppBar(
          appBarTiltle: widget.medication == null
              ? 'Add Medication'
              : 'Edit Medication',
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.r),
            child: Column(
              spacing: 20.h,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info banner
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20.r),
                      WidthSpace(12),
                      Expanded(
                        child: Text(
                          'Track pill inventory\nESP32 updates automatically',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Medication Name
                _buildTextField(
                  controller: _nameController,
                  label: 'Medication Name',
                  hint: 'Enter medication name',
                  icon: Icons.medication,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter medication name';
                    }
                    return null;
                  },
                ),

                // Time
                _buildTimeField(),

                // Frequency Selector (NEW)
                _buildFrequencySelector(),

                // Slot Selection
                _buildSlotDropdown(),

                // Pill Counts Section (NEW)
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 16.h,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.inventory, color: Colors.orange.shade700),
                          WidthSpace(8),
                          Text(
                            'Pill Inventory',
                            style: AppStyles.kTextStyle18Primary.copyWith(
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),

                      // Total Pills in Slot
                      _buildTextField(
                        controller: _totalPillsController,
                        label: 'Total Pills in Slot',
                        hint: 'e.g., 30',
                        icon: Icons.inventory_2,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          if (int.parse(value) <= 0) {
                            return 'Must be > 0';
                          }
                          return null;
                        },
                      ),

                      // Pills to Dispense Per Time
                      _buildTextField(
                        controller: _pillsToDispenseController,
                        label: 'Pills to Dispense (per time)',
                        hint: 'e.g., 2',
                        icon: Icons.medical_services,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          if (int.parse(value) <= 0) {
                            return 'Must be > 0';
                          }
                          return null;
                        },
                      ),

                      // Current Remaining (if editing)
                      if (widget.medication != null) ...[
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Currently Remaining:',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${widget.medication!.remainingPills} ${widget.medication!.unit}',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: widget.medication!.isLowStock
                                    ? Colors.red
                                    : AppColors.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Unit Selector
                Row(
                  children: [
                    Expanded(
                      child: _buildUnitDropdown(),
                    ),
                  ],
                ),

                HeightSpace(20),

                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : AppButton(
                  hintText: widget.medication == null
                      ? 'Add Medication'
                      : 'Update Medication',
                  onPressed: _saveMedication,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Frequency Selector (NEW)
  Widget _buildFrequencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Frequency', style: AppStyles.kTextStyle14primary),
        HeightSpace(8),
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            spacing: 8.h,
            children: _frequencyOptions.map((option) {
              bool isSelected = _selectedFrequency == option['value'];
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedFrequency = option['value']!;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryColor
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        option['icon']!,
                        style: TextStyle(fontSize: 24.sp),
                      ),
                      WidthSpace(12),
                      Expanded(
                        child: Text(
                          option['label']!,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primaryColor
                                : Colors.black,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: AppColors.primaryColor,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.kTextStyle14primary),
        HeightSpace(8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.primaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Time', style: AppStyles.kTextStyle14primary),
        HeightSpace(8),
        TextFormField(
          controller: _timeController,
          readOnly: true,
          onTap: _selectTime,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select time';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'Select time',
            prefixIcon:
            const Icon(Icons.access_time, color: AppColors.primaryColor),
            suffixIcon: const Icon(Icons.arrow_drop_down),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlotDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Device Slot', style: AppStyles.kTextStyle14primary),
        HeightSpace(8),
        DropdownButtonFormField<int>(
          value: _selectedSlot,
          decoration: InputDecoration(
            hintText: 'Select slot',
            prefixIcon: const Icon(Icons.inventory_2, color: AppColors.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.primaryColor),
            ),
          ),
          items: [
            _buildSlotItem(0, 'Slot 1 (Motor 1)', Colors.blue),
            _buildSlotItem(1, 'Slot 2 (Motor 2)', Colors.green),
            _buildSlotItem(2, 'Slot 3 (Motor 3)', Colors.orange),
          ],
          onChanged: (value) {
            setState(() => _selectedSlot = value!);
          },
        ),
      ],
    );
  }

  DropdownMenuItem<int> _buildSlotItem(int value, String label, Color color) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.h,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          WidthSpace(8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildUnitDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Unit', style: AppStyles.kTextStyle14primary),
        HeightSpace(8),
        DropdownButtonFormField<String>(
          value: _selectedUnit,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.primaryColor),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
          ),
          items: ['pills', 'ml', 'drops', 'capsules']
              .map((unit) => DropdownMenuItem(
            value: unit,
            child: Text(unit),
          ))
              .toList(),
          onChanged: (value) {
            setState(() => _selectedUnit = value!);
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.text;dispose();
    _totalPillsController.dispose();
    _pillsToDispenseController.dispose();
    super.dispose();
  }
}