// lib/features/medication/medication_list_screen.dart - UPDATED WITH REFILL

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
                        'ESP32 tracks pill counts automatically',
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
    // Check if enough pills
    if (medication.remainingPills < medication.pillsToDispense) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Not enough pills! Please refill the slot.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
            Text('Will dispense: ${medication.pillsToDispense} ${medication.unit}'),
            HeightSpace(8),
            Text('Remaining after: ${medication.remainingPills - medication.pillsToDispense}'),
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

    final success = await FirebaseService.sendDispenseCommand(
      medication.id!,
      medication.name,
      medication.slotNumber,
    );

    if (context.mounted) Navigator.pop(context);

    if (success && context.mounted) {
      await FirebaseService.logMedicationTaken(
        medication.id!,
        medication.name,
        'taken',
      );

      await showSuccessDialog(
        context,
        '✓ Command Sent!\n\nESP32 dispensing ${medication.pillsToDispense} ${medication.unit}',
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to send command'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refillSlot(BuildContext context) async {
    final controller = TextEditingController(
      text: medication.totalPills.toString(),
    );

    final newTotal = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refill Slot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Medication: ${medication.name}'),
            HeightSpace(8),
            Text('Slot: ${medication.slotNumber + 1}'),
            HeightSpace(16),
            Text(
              'Current: ${medication.remainingPills} ${medication.unit}',
              style: TextStyle(
                color: medication.isLowStock ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            HeightSpace(16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'New Total Pills',
                hintText: 'Enter total pills added',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
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
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.pop(context, value);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Refill', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (newTotal != null && context.mounted) {
      final updated = medication.copyWith(
        totalPills: newTotal,
        remainingPills: newTotal,
        lastRefillDate: DateTime.now().millisecondsSinceEpoch,
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Updating inventory...'),
            ],
          ),
        ),
      );

      final success = await FirebaseService.updateMedication(updated);

      if (context.mounted) Navigator.pop(context);

      if (success && context.mounted) {
        await showSuccessDialog(
          context,
          '✓ Slot Refilled!\n\nNew total: $newTotal ${medication.unit}',
        );
      }
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
            content: Text('${medication.name} deleted'),
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
            // Header Row
            Row(
              children: [
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

            // Pill Inventory (NEW)
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: medication.isLowStock
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: medication.isLowStock
                      ? Colors.red.shade200
                      : Colors.green.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4.h,
                    children: [
                      Text(
                        'Pills Remaining',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${medication.remainingPills} / ${medication.totalPills}',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: medication.isLowStock
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(
                        medication.isLowStock
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle,
                        color: medication.isLowStock
                            ? Colors.red
                            : Colors.green,
                        size: 32.r,
                      ),
                      Text(
                        '${medication.percentRemaining}%',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            _buildInfoRow(Icons.access_time, 'Time', medication.time),
            _buildInfoRow(Icons.repeat, 'Frequency', medication.frequencyDisplay),
            _buildInfoRow(
              Icons.medical_services,
              'Dosage',
              '${medication.pillsToDispense} ${medication.unit} per time',
            ),

            // Action Buttons
            HeightSpace(8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: medication.enabled && !medication.isEmpty
                        ? () => _dispenseMedication(context)
                        : null,
                    icon: const Icon(Icons.medical_services, size: 18),
                    label: const Text('Dispense'),
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
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _refillSlot(context),
                    icon: const Icon(Icons.add_circle, size: 18),
                    label: const Text('Refill'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}