// lib/features/medication/medication_list_screen.dart - FIXED
// Now correctly reads from RTDB (same source as ESP32)

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
        stream: FirebaseService.getMedicationsStream(), // From RTDB
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80.r, color: Colors.red),
                  HeightSpace(16),
                  Text('Error: ${snapshot.error}'),
                  HeightSpace(16),
                  ElevatedButton(
                    onPressed: () {
                      (context as Element).markNeedsBuild();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
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
                  HeightSpace(24),
                  Text(
                    'ESP32 will automatically sync',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Info banner
              Container(
                margin: EdgeInsets.all(16.r),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    WidthSpace(12),
                    Expanded(
                      child: Text(
                        'ESP32 reads directly from this database',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Medication list
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.r),
                  itemCount: medications.length,
                  itemBuilder: (context, index) {
                    final medication = medications[index];
                    return MedicationListCard(medication: medication);
                  },
                ),
              ),
            ],
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
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dispense Medication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Medication: ${medication.name}'),
            HeightSpace(8),
            Text('Slot: ${medication.slotNumber + 1}'),
            HeightSpace(8),
            Text('Quantity: ${medication.quantity} ${medication.unit}'),
            HeightSpace(16),
            Text(
              'Send command to ESP32?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: const Text('Dispense', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            HeightSpace(16),
            const Text('Sending command to ESP32...'),
          ],
        ),
      ),
    );

    // Send command to RTDB (ESP32 listens here)
    final success = await FirebaseService.sendDispenseCommand(
      medication.id!,
      medication.name,
      medication.slotNumber,
    );

    // Close loading
    if (context.mounted) Navigator.pop(context);

    if (success && context.mounted) {
      // Log to Firestore
      await FirebaseService.logMedicationTaken(
        medication.id!,
        medication.name,
        'taken',
      );

      await showSuccessDialog(
        context,
        '✓ Command Sent to ESP32!\n\nSlot ${medication.slotNumber + 1}: ${medication.name}\nQuantity: ${medication.quantity} ${medication.unit}\n\nESP32 will dispense now...',
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to send command to ESP32'),
          backgroundColor: Colors.red,
        ),
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
          SnackBar(
            content: Text('${medication.name} deleted from RTDB'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Color _getSlotColor(int slotNumber) {
    switch (slotNumber) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(
          color: _getSlotColor(medication.slotNumber).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12.h,
          children: [
            Row(
              children: [
                // Slot indicator
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getSlotColor(medication.slotNumber),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Slot ${medication.slotNumber + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                WidthSpace(12),
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
                      disabledBackgroundColor: Colors.grey,
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