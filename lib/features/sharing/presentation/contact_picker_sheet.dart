import 'package:flutter/material.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/features/sharing/data/contact_repository.dart';

/// Bottom sheet de sélection de contacts — envoie le lien par SMS.
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

  static const _avatarPalette = [
    AppColors.kPrimary,
    AppColors.kAccent,
    AppColors.kSuccess,
    AppColors.kAccentViolet,
    AppColors.kInfo,
  ];

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
      await widget.repository
          .shareViaContact(widget.shareUrl, _selected.toList());
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

  Color _avatarColor(int index) =>
      _avatarPalette[index % _avatarPalette.length];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.70,
      minChildSize: 0.40,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.kBgSurface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.kRadiusXl),
            ),
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(),
              const Divider(height: 1, color: AppColors.kBorder),
              Expanded(child: _buildContactList(scrollController)),
              _buildActions(),
            ],
          ),
        );
      },
    );
  }

  // ── Handle ────────────────────────────────────────────────────────────────

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.kBorder,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: [
          const Text(
            'Envoyer à un contact',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.kTextPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.kPrimary,
              ),
            )
          else if (_selected.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.kPrimary,
                borderRadius:
                    BorderRadius.circular(AppSpacing.kRadiusPill),
              ),
              child: Text(
                '${_selected.length}',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Liste contacts ────────────────────────────────────────────────────────

  Widget _buildContactList(ScrollController scrollController) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.kPrimary),
      );
    }
    if (_contacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.kBgElevated,
                ),
                child: const Icon(
                  Icons.contacts_outlined,
                  size: 28,
                  color: AppColors.kTextTertiary,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Aucun contact trouvé',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.kTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Aucun contact avec numéro disponible.',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  color: AppColors.kTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _contacts.length,
      itemBuilder: (context, i) {
        final contact = _contacts[i];
        final isSelected = _selected.contains(contact.phoneNumber);
        return _ContactRow(
          contact: contact,
          isSelected: isSelected,
          avatarColor: _avatarColor(i),
          onToggle: () => setState(() {
            if (isSelected) {
              _selected.remove(contact.phoneNumber);
            } else {
              _selected.add(contact.phoneNumber);
            }
          }),
        );
      },
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Widget _buildActions() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: AppSpacing.kButtonHeightSm,
                child: OutlinedButton(
                  onPressed:
                      _isSending ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.kTextSecondary,
                    side: const BorderSide(color: AppColors.kBorder),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: AppSpacing.kButtonHeightSm,
                child: FilledButton(
                  onPressed:
                      (_selected.isEmpty || _isSending) ? null : _send,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.kPrimary,
                    disabledBackgroundColor: AppColors.kBgElevated,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Envoyer (${_selected.length})'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _ContactRow ──────────────────────────────────────────────────────────────

class _ContactRow extends StatelessWidget {
  final ContactInfo contact;
  final bool isSelected;
  final Color avatarColor;
  final VoidCallback onToggle;

  const _ContactRow({
    required this.contact,
    required this.isSelected,
    required this.avatarColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.kPrimary.withValues(alpha: 0.05)
          : Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Avatar initiale
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: avatarColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    contact.name.isNotEmpty
                        ? contact.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: avatarColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Nom + numéro
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contact.phoneNumber,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        color: AppColors.kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Checkbox animée
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.kPrimary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.kPrimary
                        : AppColors.kBorder,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
