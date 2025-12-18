// lib/features/medication/medication_list_screen.dart

import 'package:alzeh/core/resources/barallel.dart';
import 'package:alzeh/core/services/firebase_service.dart';
import 'package:alzeh/features/model/medication_model.dart';
import 'package:alzeh/features/medication/add_edit_medication_screen.dart';
import 'package:flutter/material.dart';

class MedicationListScreen extends StatelessWidget {
  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: CustomAppBar(
        appBarTiltle: 'Manage Medications',
        showBackButton: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditMedicationScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<MedicationModel>>(
        stream: FirebaseService.getMedicationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final medications = snapshot.data ?? [];

          if (medications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medication_outlined,
                    size: 80.r,
                    color: Colors.grey,
                  ),
                  HeightSpace(16),
                  Text(
                    'No medications added yet',
                    style: AppStyles.kTextStyle16Grey,
                  ),
                  HeightSpace(8),
                  Text(
                    'Tap + to add your first medication',
                    style: AppStyles.kTextStyle14primary,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.r),
            itemCount: medications.length,
            itemBuilder: (context, index) {
              final medication = medications[index];
              return MedicationListCard(medication: medication);
            },
          );
        },
      ),
    );
  }
}

class MedicationListCard extends StatelessWidget {
  const MedicationListCard({super.key, required this.medication});
  final MedicationModel medication;

  Future<void> _dispenseMedication(BuildContext context) async {
    final success = await FirebaseService.sendDispenseCommand(
      medication.id!,
      medication.quantity,
    );

    if (success && context.mounted) {
      await showSuccessDialog(
        context,
        'Dispense command sent to ESP32!\n${medication.quantity} ${medication.unit} of ${medication.name}',
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send dispense command')),
      );
    }
  }

  Future<void> _deleteMedication(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Are you sure you want to delete ${medication.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await FirebaseService.deleteMedication(medication.id!);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12.h,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    medication.name,
                    style: AppStyles.kTextStyle18Primary,
                  ),
                ),
                Switch(
                  value: medication.enabled,
                  onChanged: (value) {
                    FirebaseService.toggleMedicationStatus(
                      medication.id!,
                      value,
                    );
                  },
                  activeColor: AppColors.primaryColor,
                ),
              ],
            ),
            _buildInfoRow(Icons.access_time, 'Time', medication.time),
            _buildInfoRow(Icons.refresh, 'Frequency', medication.frequency),
            _buildInfoRow(
              Icons.medication,
              'Dosage',
              '${medication.quantity} ${medication.unit}',
            ),
            HeightSpace(8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: medication.enabled
                        ? () => _dispenseMedication(context)
                        : null,
                    icon: const Icon(Icons.medical_services, size: 18),
                    label: const Text('Dispense Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                WidthSpace(8),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditMedicationScreen(
                          medication: medication,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  color: AppColors.primaryColor,
                ),
                IconButton(
                  onPressed: () => _deleteMedication(context),
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18.r, color: AppColors.primaryColor),
        WidthSpace(8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}