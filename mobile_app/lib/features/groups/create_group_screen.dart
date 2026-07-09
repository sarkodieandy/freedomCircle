import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/repositories/group_repository.dart';
import '../monetization/feature_locked_modal.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final GroupRepository _groupRepository = const GroupRepository();

  String _visibility = 'public';
  String _groupType = 'accountability';
  bool _premium = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;

    setState(() => _submitting = true);
    try {
      if (_premium && mounted) {
        final allowed = await _groupRepository
            .canCurrentUserCreatePremiumGroup();
        if (!mounted) return;
        if (!allowed) {
          await FeatureLockedModal.show(
            context,
            featureKey: 'premium_group_creation',
            featureName: 'Create premium groups',
            reason:
                'Premium groups are available for users with active premium access.',
            benefits: const [
              'Create premium guided circles',
              'Advanced moderation and structure',
              'Premium-only member experiences',
            ],
            screen: 'create_group',
          );
          if (mounted) {
            setState(() {
              _premium = false;
              _submitting = false;
            });
          }
          return;
        }
      }

      final group = await _groupRepository.createGroupAndJoinAsOwner(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        visibility: _visibility,
        groupType: _groupType,
        isPremium: _premium,
      );

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacementNamed(AppRoutes.groupDetail, arguments: group);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create group: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create group')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Build a support circle',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a safe and structured group for recovery, prayer, or mentorship.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Group name',
                        prefixIcon: Icon(Icons.groups_rounded),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.length < 3) {
                          return 'Please enter at least 3 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.length < 12) {
                          return 'Please add a short description (12+ chars).';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visibility',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _visibility,
                      items: const [
                        DropdownMenuItem(
                          value: 'public',
                          child: Text('Public'),
                        ),
                        DropdownMenuItem(
                          value: 'private',
                          child: Text('Private'),
                        ),
                        DropdownMenuItem(
                          value: 'church_only',
                          child: Text('Church only'),
                        ),
                        DropdownMenuItem(
                          value: 'premium',
                          child: Text('Premium'),
                        ),
                        DropdownMenuItem(
                          value: 'invite_only',
                          child: Text('Invite only'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _visibility = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _groupType,
                      decoration: const InputDecoration(
                        labelText: 'Group focus',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'accountability',
                          child: Text('Accountability'),
                        ),
                        DropdownMenuItem(
                          value: 'recovery',
                          child: Text('Recovery'),
                        ),
                        DropdownMenuItem(
                          value: 'prayer',
                          child: Text('Prayer'),
                        ),
                        DropdownMenuItem(
                          value: 'bible_study',
                          child: Text('Bible study'),
                        ),
                        DropdownMenuItem(value: 'youth', child: Text('Youth')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _groupType = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _premium,
                      onChanged: (value) => setState(() => _premium = value),
                      title: const Text('Premium group'),
                      subtitle: const Text('Members may need premium access.'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const SafetyNotice(
                icon: Icons.shield_rounded,
                text:
                    'Keep group rules clear, do not share personal details publicly, and report harmful behavior quickly.',
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: _submitting ? 'Creating...' : 'Create group',
                icon: Icons.check_circle_rounded,
                onPressed: () {
                  if (_submitting) return;
                  _submit();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
