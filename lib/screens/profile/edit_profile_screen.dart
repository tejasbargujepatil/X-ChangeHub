import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  
  List<String> _selectedSkillsToTeach = [];
  List<String> _selectedSkillsToLearn = [];
  String? _profileImagePath;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user != null) {
      _fullNameController.text = user.fullName;
      _bioController.text = user.bio ?? '';
      _selectedSkillsToTeach = List.from(user.skillsToTeach);
      _selectedSkillsToLearn = List.from(user.skillsToLearn);
      _profileImagePath = user.profileImageUrl;
    }
  }

  ImageProvider? _getProfileImageProvider(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    if (kIsWeb) {
      return NetworkImage(path);
    }
    return FileImage(File(path));
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 85,
                );
                if (image != null) {
                  setState(() {
                    _profileImagePath = image.path;
                    _hasChanges = true;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 85,
                );
                if (image != null) {
                  setState(() {
                    _profileImagePath = image.path;
                    _hasChanges = true;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser!;

      // Create updated user model
      final updatedUser = currentUser.copyWith(
        fullName: _fullNameController.text.trim(),
        bio: _bioController.text.trim(),
        skillsToTeach: _selectedSkillsToTeach,
        skillsToLearn: _selectedSkillsToLearn,
        // TODO: Upload profile image to Firebase Storage if _profileImagePath changed
      );

      // Update profile
      await authProvider.updateProfile(updatedUser);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSkillSelector({required bool isTeaching}) async {
    final List<String> currentSkills = isTeaching 
        ? _selectedSkillsToTeach 
        : _selectedSkillsToLearn;
    
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => _SkillSelectorDialog(
        title: isTeaching ? 'Skills I Can Teach' : 'Skills I Want to Learn',
        availableSkills: AppConfig.popularSkills,
        selectedSkills: currentSkills,
        maxSelection: isTeaching 
            ? AppConfig.maxSkillsToTeach 
            : AppConfig.maxSkillsToLearn,
      ),
    );

    if (result != null) {
      setState(() {
        if (isTeaching) {
          _selectedSkillsToTeach = result;
        } else {
          _selectedSkillsToLearn = result;
        }
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Discard Changes?'),
              content: const Text('You have unsaved changes. Are you sure you want to leave?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                  ),
                  child: const Text('Discard'),
                ),
              ],
            ),
          );
          return result ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          actions: [
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              TextButton(
                onPressed: _hasChanges ? _saveProfile : null,
                child: const Text(
                  'SAVE',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            onChanged: () {
              if (!_hasChanges) {
                setState(() {
                  _hasChanges = true;
                });
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Image
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        backgroundImage: _getProfileImageProvider(_profileImagePath),
                        child: _profileImagePath == null
                            ? Text(
                                user.fullName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 48,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    if (value.trim().length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Username (Read-only)
                TextFormField(
                  initialValue: user.username,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.alternate_email),
                    enabled: false,
                  ),
                ),
                const SizedBox(height: 16),

                // Email (Read-only)
                TextFormField(
                  initialValue: user.email,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    enabled: false,
                  ),
                ),
                const SizedBox(height: 16),

                // Bio
                TextFormField(
                  controller: _bioController,
                  maxLines: 4,
                  maxLength: AppConfig.maxBioLength,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Tell us about yourself...',
                    prefixIcon: Icon(Icons.notes),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value != null && value.length > AppConfig.maxBioLength) {
                      return 'Bio is too long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Skills to Teach Section
                _buildSkillSection(
                  title: 'Skills I Can Teach',
                  skills: _selectedSkillsToTeach,
                  color: AppTheme.primaryColor,
                  onTap: () => _showSkillSelector(isTeaching: true),
                  emptyMessage: 'Add skills you can teach',
                ),
                const SizedBox(height: 24),

                // Skills to Learn Section
                _buildSkillSection(
                  title: 'Skills I Want to Learn',
                  skills: _selectedSkillsToLearn,
                  color: AppTheme.secondaryColor,
                  onTap: () => _showSkillSelector(isTeaching: false),
                  emptyMessage: 'Add skills you want to learn',
                ),
                const SizedBox(height: 32),

                // Save Button (Bottom)
                ElevatedButton(
                  onPressed: _isLoading || !_hasChanges ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkillSection({
    required String title,
    required List<String> skills,
    required Color color,
    required VoidCallback onTap,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (skills.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, color: color),
                const SizedBox(width: 12),
                Text(
                  emptyMessage,
                  style: TextStyle(color: color),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((skill) => 
              Chip(
                label: Text(skill),
                backgroundColor: color.withOpacity(0.1),
                labelStyle: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                deleteIcon: Icon(Icons.close, size: 18, color: color),
                onDeleted: () {
                  setState(() {
                    skills.remove(skill);
                    _hasChanges = true;
                  });
                },
              ),
            ).toList(),
          ),
      ],
    );
  }
}

// Skill Selector Dialog
class _SkillSelectorDialog extends StatefulWidget {
  final String title;
  final List<String> availableSkills;
  final List<String> selectedSkills;
  final int maxSelection;

  const _SkillSelectorDialog({
    required this.title,
    required this.availableSkills,
    required this.selectedSkills,
    required this.maxSelection,
  });

  @override
  State<_SkillSelectorDialog> createState() => _SkillSelectorDialogState();
}

class _SkillSelectorDialogState extends State<_SkillSelectorDialog> {
  late List<String> _selected;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedSkills);
  }

  List<String> get _filteredSkills {
    if (_searchQuery.isEmpty) {
      return widget.availableSkills;
    }
    return widget.availableSkills
        .where((skill) => skill.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_selected.length} / ${widget.maxSelection} selected',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search skills...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // Skills List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredSkills.length,
                itemBuilder: (context, index) {
                  final skill = _filteredSkills[index];
                  final isSelected = _selected.contains(skill);
                  
                  return CheckboxListTile(
                    title: Text(skill),
                    value: isSelected,
                    enabled: isSelected || _selected.length < widget.maxSelection,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selected.add(skill);
                        } else {
                          _selected.remove(skill);
                        }
                      });
                    },
                  );
                },
              ),
            ),

            // Save Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _selected),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
