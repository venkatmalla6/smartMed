import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/settings_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _specialtyController;
  String _selectedGender = '';
  String _selectedTitle = 'Dr.';

  final List<String> _titles = ['Dr.', 'Mr.', 'Ms.', 'Mrs.'];

  @override
  void initState() {
    super.initState();
    final provider = context.read<SettingsProvider>();
    _nameController = TextEditingController(text: provider.userName);
    _specialtyController = TextEditingController(text: provider.specialty);
    _selectedGender = provider.userGender;
    _selectedTitle = provider.userTitle;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    context.read<SettingsProvider>().updateProfile(
          name: _nameController.text.trim(),
          gender: _selectedGender,
          title: _selectedTitle,
          specialty: _specialtyController.text.trim(),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved successfully')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded, color: AppTheme.accentGreen),
            onPressed: _saveProfile,
            tooltip: 'Save Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      colors: [AppTheme.accentBlue, AppTheme.accentPurple]),
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 60),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Title',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _titles.map((title) {
                final isSelected = _selectedTitle == title;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTitle = title),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.accentBlue.withValues(alpha: 0.2) : AppTheme.bgInput,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.accentBlue : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? AppTheme.accentBlue : AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Name',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Enter your name...',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Medical Specialty / Role',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _specialtyController,
              decoration: const InputDecoration(
                hintText: 'e.g. Cardiologist, Med Student...',
                prefixIcon: Icon(Icons.medical_services_outlined),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Gender',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildGenderOption('Male', Icons.male_rounded),
                const SizedBox(width: 16),
                _buildGenderOption('Female', Icons.female_rounded),
                const SizedBox(width: 16),
                _buildGenderOption('Other', Icons.transgender_rounded),
              ],
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderOption(String gender, IconData icon) {
    final isSelected = _selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = gender),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentBlue.withValues(alpha: 0.2) : AppTheme.bgInput,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.accentBlue : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.accentBlue : AppTheme.textSecondary,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                gender,
                style: TextStyle(
                  color: isSelected ? AppTheme.accentBlue : AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
