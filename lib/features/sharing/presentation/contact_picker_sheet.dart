import 'package:flutter/material.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/sharing/data/contact_repository.dart';

/// Bottom sheet permettant de sélectionner un ou plusieurs contacts
/// et d'envoyer le lien de partage par SMS.
class ContactPickerSheet extends StatefulWidget {
  final String shareUrl;
  final ContactRepository repository;

  const ContactPickerSheet({
    super.key,
    required this.shareUrl,
    required this.repository,
  });

  @override
  State<ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<ContactPickerSheet> {
  List<ContactInfo> _contacts = [];
  final Set<String> _selected = {};
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await widget.repository.getContacts();
    if (!mounted) return;
    setState(() {
      _contacts = contacts;
      _isLoading = false;
    });
  }

  Future<void> _send() async {
    if (_selected.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await widget.repository.shareViaContact(
          widget.shareUrl, _selected.toList());
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible d'envoyer. Vérifiez l'app SMS."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.kBgSurface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.kRadiusLg),
            ),
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(),
              const Divider(height: 1, color: AppColors.kOutline),
              Expanded(child: _buildContactList(scrollController)),
              _buildActions(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.kSpaceSm),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.kOutline,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.kScreenMargin,
        AppSpacing.kSpaceXs,
        AppSpacing.kScreenMargin,
        AppSpacing.kSpaceMd,
      ),
      child: Row(
        children: [
          Text('Sélectionner des contacts',
              style: AppTextStyles.kTitleLarge),
          const Spacer(),
          if (_isLoading) const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildContactList(ScrollController scrollController) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_contacts.isEmpty) {
      return Center(
        child: Text(
          'Aucun contact avec numéro trouvé.',
          style: AppTextStyles.kBodyMedium
              .copyWith(color: AppColors.kTextSecondary),
        ),
      );
    }
    return ListView.builder(
      controller: scrollController,
      itemCount: _contacts.length,
      itemBuilder: (_, i) {
        final contact = _contacts[i];
        final isSelected = _selected.contains(contact.phoneNumber);
        return CheckboxListTile(
          value: isSelected,
          onChanged: (checked) {
            setState(() {
              if (checked == true) {
                _selected.add(contact.phoneNumber);
              } else {
                _selected.remove(contact.phoneNumber);
              }
            });
          },
          title: Text(contact.name, style: AppTextStyles.kBodyMedium),
          subtitle: Text(
            contact.phoneNumber,
            style: AppTextStyles.kCaption
                .copyWith(color: AppColors.kTextSecondary),
          ),
          activeColor: AppColors.kPrimary,
          checkColor: AppColors.kBgBase,
          controlAffinity: ListTileControlAffinity.leading,
        );
      },
    );
  }

  Widget _buildActions() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.kScreenMargin),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSending ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.kTextSecondary,
                  side: BorderSide(color: AppColors.kTextSecondary),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.kRadiusMd),
                  ),
                ),
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: AppSpacing.kSpaceMd),
            Expanded(
              child: FilledButton(
                onPressed: (_selected.isEmpty || _isSending) ? null : _send,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.kPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.kRadiusMd),
                  ),
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Envoyer (${_selected.length})'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
