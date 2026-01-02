// lib/features/medication/add_edit_medication_screen.dart - FIXED
// Now saves to RTDB (same source as ESP32 reads from)

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
  final _frequencyController = TextEditingController();
  final _quantityController = TextEditingController();

  bool _isLoading = false;
  String _selectedUnit = 'pills';
  int _selectedSlot = 0;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      _nameController.text = widget.medication!.name;
      _timeController.text = widget.medication!.time;
      _frequencyController.text = widget.medication!.frequency;
      _quantityController.text = widget.medication!.quantity.toString();
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

    setState(() => _isLoading = true);

    final medication = MedicationModel(
      id: widget.medication?.id,
      name: _nameController.text.trim(),
      time: _timeController.text,
      frequency: _frequencyController.text.trim(),
      quantity: int.parse(_quantityController.text),
      unit: _selectedUnit,
      slotNumber: _selectedSlot,
      enabled: true,
    );

    bool success;
    String message;

    if (widget.medication == null) {
      // Add new medication to RTDB
      final id = await FirebaseService.addMedication(medication);
      success = id != null;
      message = success
          ? '✓ Medication added to RTDB\nESP32 will sync automatically'
          : '❌ Failed to add medication';
    } else {
      // Update existing medication in RTDB
      success = await FirebaseService.updateMedication(medication);
      message = success
          ? '✓ Medication updated in RTDB\nESP32 will sync automatically'
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
                          'Saved to Realtime Database\nESP32 syncs automatically',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                _buildTextField(
                  controller: _nameController,
                  label: 'Medicine Name',
                  hint: 'Enter medicine name',
                  icon: Icons.medication,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter medicine name';
                    }
                    return null;
                  },
                ),

                _buildTimeField(),

                _buildTextField(
                  controller: _frequencyController,
                  label: 'Frequency',
                  hint: 'e.g., Every 8 hours, Daily',
                  icon: Icons.refresh,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter frequency';
                    }
                    return null;
                  },
                ),

                _buildSlotDropdown(),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _quantityController,
                        label: 'Quantity',
                        hint: 'Number',
                        icon: Icons.format_list_numbered,
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
                    ),
                    WidthSpace(16),
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
                      ? 'Add to RTDB'
                      : 'Update RTDB',
                  onPressed: _saveMedication,
                ),
              ],
            ),
          ),
        ),
      ),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Colors.red),
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
        Text('Device Slot (ESP32)', style: AppStyles.kTextStyle14primary),
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
            DropdownMenuItem(
              value: 0,
              child: Row(
                children: [
                  Container(
                    width: 12.w,
                    height: 12.h,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  WidthSpace(8),
                  const Text('Slot 1 (Motor 1)'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 1,
              child: Row(
                children: [
                  Container(
                    width: 12.w,
                    height: 12.h,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  WidthSpace(8),
                  const Text('Slot 2 (Motor 2)'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 2,
              child: Row(
                children: [
                  Container(
                    width: 12.w,
                    height: 12.h,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  WidthSpace(8),
                  const Text('Slot 3 (Motor 3)'),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            setState(() => _selectedSlot = value!);
          },
        ),
      ],
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
    _timeController.dispose();
    _frequencyController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}