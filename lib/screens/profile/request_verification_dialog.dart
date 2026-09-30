import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/enhancement_models.dart';
import '../../services/enhancement_services.dart';

/// Dialog for requesting a skill verification
class RequestVerificationDialog extends StatefulWidget {
  final String userId;
  final List<String> availableSkills;
  final String? initialSkill;
  final VerificationService? verificationService;
  final List<String>? verifiedSkills;

  const RequestVerificationDialog({
    super.key,
    required this.userId,
    required this.availableSkills,
    this.initialSkill,
    this.verificationService,
    this.verifiedSkills,
  });

  @override
  State<RequestVerificationDialog> createState() => _RequestVerificationDialogState();
}

class _RequestVerificationDialogState extends State<RequestVerificationDialog> {
  late final VerificationService _verificationService;
  late String _selectedSkill;
  VerificationType _selectedType = VerificationType.learningPlan;
  final TextEditingController _certificateUrlController = TextEditingController();
  final TextEditingController _learningPlanIdController = TextEditingController();
  bool _isSubmitting = false;
  bool _checkingEligibility = false;
  bool _isEligibleViaPlan = false;
  bool _checkingActiveRequest = false;
  bool _hasActiveRequest = false;
  bool _isAlreadyVerified = false;

  late List<String> _selectableSkills;

  @override
  void initState() {
    super.initState();
    _verificationService = widget.verificationService ?? VerificationService();
    
    // Filter available skills that are already verified
    final verifiedSet = (widget.verifiedSkills ?? []).toSet();
    final unverified = widget.availableSkills.where((s) => !verifiedSet.contains(s)).toList();
    _selectableSkills = unverified.isNotEmpty ? unverified : widget.availableSkills;

    _selectedSkill = widget.initialSkill ??
        (_selectableSkills.isNotEmpty ? _selectableSkills.first : '');
    
    if (_selectedSkill.isNotEmpty) {
      _checkSkillStatus();
    }
  }

  @override
  void dispose() {
    _certificateUrlController.dispose();
    _learningPlanIdController.dispose();
    super.dispose();
  }

  Future<void> _checkSkillStatus() async {
    if (_selectedSkill.isEmpty) return;
    setState(() {
      _checkingEligibility = true;
      _checkingActiveRequest = true;
    });

    final isVerifiedInList = (widget.verifiedSkills ?? []).contains(_selectedSkill);

    try {
      final results = await Future.wait([
        _verificationService.checkVerificationEligibility(widget.userId, _selectedSkill),
        _verificationService.hasActiveVerificationRequest(widget.userId, _selectedSkill),
      ]);

      if (mounted) {
        setState(() {
          _isEligibleViaPlan = results[0];
          _hasActiveRequest = results[1];
          _isAlreadyVerified = isVerifiedInList || (results[1] && isVerifiedInList);
          _checkingEligibility = false;
          _checkingActiveRequest = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isEligibleViaPlan = false;
          _hasActiveRequest = false;
          _isAlreadyVerified = isVerifiedInList;
          _checkingEligibility = false;
          _checkingActiveRequest = false;
        });
      }
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedSkill.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a skill to verify.'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    if (_isAlreadyVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This skill is already verified for your profile.'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    if (_hasActiveRequest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification already requested. You already have an active verification request for this skill.'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    if (_selectedType == VerificationType.certificate &&
        _certificateUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a valid certificate or proof URL.'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _verificationService.requestVerification(
        skill: _selectedSkill,
        type: _selectedType,
        certificateUrl: _certificateUrlController.text.trim().isNotEmpty
            ? _certificateUrlController.text.trim()
            : null,
        learningPlanId: _learningPlanIdController.text.trim().isNotEmpty
            ? _learningPlanIdController.text.trim()
            : null,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Skill verification request submitted for reviewer evaluation!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to request verification: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.verified, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Request XchangeHub Verified',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Skill to Verify:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            if (_selectableSkills.isEmpty)
              const Text(
                'No unverified skills available. All your teaching skills are already verified or pending request.',
                style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedSkill.isNotEmpty && _selectableSkills.contains(_selectedSkill)
                    ? _selectedSkill
                    : _selectableSkills.first,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _selectableSkills.map((skill) {
                  final isVerified = (widget.verifiedSkills ?? []).contains(skill);
                  return DropdownMenuItem<String>(
                    value: skill,
                    child: Text(isVerified ? '$skill (Verified)' : skill),
                  );
                }).toList(),
                onChanged: _isSubmitting
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() => _selectedSkill = val);
                          _checkSkillStatus();
                        }
                      },
              ),
            const SizedBox(height: 16),

            // Warning Banners for Active Request or Verified Skill
            if (_checkingActiveRequest) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Checking verification status...', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ] else if (_isAlreadyVerified) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: AppTheme.warningColor, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Skill already verified',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.warningColor),
                          ),
                          Text(
                            'This skill is already verified for your profile.',
                            style: TextStyle(fontSize: 11, color: AppTheme.textPrimaryColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else if (_hasActiveRequest) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.warningColor, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verification already requested',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.warningColor),
                          ),
                          Text(
                            'You already have an active verification request for this skill.',
                            style: TextStyle(fontSize: 11, color: AppTheme.textPrimaryColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            const Text(
              'Verification Type:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Learning Plan'),
                  selected: _selectedType == VerificationType.learningPlan,
                  onSelected: (_isSubmitting || _hasActiveRequest || _isAlreadyVerified)
                      ? null
                      : (selected) {
                          if (selected) setState(() => _selectedType = VerificationType.learningPlan);
                        },
                ),
                ChoiceChip(
                  label: const Text('Certificate Link'),
                  selected: _selectedType == VerificationType.certificate,
                  onSelected: (_isSubmitting || _hasActiveRequest || _isAlreadyVerified)
                      ? null
                      : (selected) {
                          if (selected) setState(() => _selectedType = VerificationType.certificate);
                        },
                ),
                ChoiceChip(
                  label: const Text('Portfolio'),
                  selected: _selectedType == VerificationType.portfolio,
                  onSelected: (_isSubmitting || _hasActiveRequest || _isAlreadyVerified)
                      ? null
                      : (selected) {
                          if (selected) setState(() => _selectedType = VerificationType.portfolio);
                        },
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_selectedType == VerificationType.learningPlan && !_hasActiveRequest && !_isAlreadyVerified) ...[
              if (_checkingEligibility)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Checking Learning Plan status...', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                )
              else if (_isEligibleViaPlan)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.successColor, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Completed Learning Plan detected for this skill. Ready for reviewer audit!',
                          style: TextStyle(fontSize: 12, color: AppTheme.successColor),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.warningColor, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No completed Learning Plan found yet for this skill. Reviewer will inspect exchange history or attached proof.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textPrimaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            if (_selectedType == VerificationType.certificate && !_hasActiveRequest && !_isAlreadyVerified) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _certificateUrlController,
                enabled: !_isSubmitting,
                decoration: InputDecoration(
                  labelText: 'Certificate / Proof URL',
                  hintText: 'https://credentials.example.com/cert/123',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_isSubmitting || _hasActiveRequest || _isAlreadyVerified || _checkingActiveRequest)
              ? null
              : _submitRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Submit Request'),
        ),
      ],
    );
  }
}
