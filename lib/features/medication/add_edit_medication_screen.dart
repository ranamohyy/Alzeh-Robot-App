// lib/features/medication/add_edit_medication_screen.dart

import 'package:alzeh/core/resources/barallel.dart';
import 'package:alzeh/core/services/firestore_service.dart';
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
      enabled: true,
    );

    bool success;
    if (widget.medication == null) {
      final id = await FirestoreService.addMedication(medication);
      success = id != null;
    } else {
      success = await FirestoreService.updateMedication(medication);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      await showSuccessDialog(
        context,
        widget.medication == null
            ? '✓ Medication added successfully'
            : '✓ Medication updated successfully',
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save medication'),
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