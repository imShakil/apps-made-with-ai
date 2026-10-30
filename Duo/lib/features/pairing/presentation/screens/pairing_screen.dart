import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/duo_colors.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../providers/pairing_provider.dart';

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  bool _isJoining = false;
  final TextEditingController _codeController = TextEditingController();
  String? _activeInviteCode;
  bool _isGeneratingCode = false;

  @override
  void initState() {
    super.initState();
    // Only generate invite code if user hasn't already got one and is viewing invite tab
    if (!_isJoining && _activeInviteCode == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadOrGenerateInvite();
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadOrGenerateInvite() async {
    if (_activeInviteCode != null) return;
    setState(() => _isGeneratingCode = true);
    final code = await ref.read(pairingProvider.notifier).createInvitationCode();
    if (mounted) {
      setState(() {
        _activeInviteCode = code;
        _isGeneratingCode = false;
      });
    }
  }

  Future<void> _handleAccept() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an invitation code.')),
      );
      return;
    }

    final success = await ref.read(pairingProvider.notifier).acceptInvitation(code);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Connected! Welcome to your shared Duo space!')),
      );
      context.go('/home');
    } else {
      final err = ref.read(pairingProvider).error ?? 'Invalid invitation code.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _shareInvite() {
    if (_activeInviteCode == null) return;
    Share.share(
      'Hey love! 💗 Join our private world on Duo using our invite code: $_activeInviteCode\nDownload or open: http://localhost:5000',
      subject: 'Join our private Duo space!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pairingState = ref.watch(pairingProvider);

    // If pairing becomes active, auto-navigate to /home
    ref.listen<DuoSpaceState>(pairingProvider, (previous, next) {
      if (next.isPaired) {
        context.go('/home');
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(supabaseClientProvider).auth.signOut();
              if (context.mounted) {
                context.go('/auth');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Brand Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: DuoColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('💗', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Connect with Your Person',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Duo is a private sanctuary built for exactly two people.',
                style: TextStyle(fontSize: 14, color: isDark ? DuoColors.textMutedDark : DuoColors.textMutedLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Toggle: Invite Partner vs Enter Code
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : DuoColors.borderLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isJoining = false),
                        child: Container(
                          decoration: BoxDecoration(
                            color: !_isJoining ? (isDark ? DuoColors.cardDark : Colors.white) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Invite Partner',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: !_isJoining ? FontWeight.bold : FontWeight.w500,
                              color: !_isJoining ? DuoColors.primary : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isJoining = true),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isJoining ? (isDark ? DuoColors.cardDark : Colors.white) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Enter Code',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _isJoining ? FontWeight.bold : FontWeight.w500,
                              color: _isJoining ? DuoColors.primary : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              if (!_isJoining) ...[
                // Invite Code Display Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text(
                          'YOUR PAIRING CODE',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: DuoColors.surfaceWarm,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: _isGeneratingCode
                              ? const SizedBox(
                                  height: 28,
                                  width: 28,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: DuoColors.primary),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _activeInviteCode ?? 'GENERATING...',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                        color: DuoColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: const Icon(Icons.copy_rounded, color: DuoColors.primary, size: 20),
                                      onPressed: _activeInviteCode == null
                                          ? null
                                          : () {
                                              Clipboard.setData(ClipboardData(text: _activeInviteCode!));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Invite code copied to clipboard!')),
                                              );
                                            },
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Share this code with your partner. Once they accept, your shared world opens automatically!',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _activeInviteCode == null ? null : _shareInvite,
                  icon: const Icon(Icons.share_rounded, size: 20),
                  label: const Text('Share Invite Link'),
                ),
              ] else ...[
                // Enter Partner Code Form
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enter Partner’s Invite Code',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Paste the code sent by your partner to connect.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _codeController,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            hintText: 'e.g. DUO4B29A',
                            prefixIcon: Icon(Icons.key_rounded, color: DuoColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: pairingState.isLoading ? null : _handleAccept,
                  child: pairingState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Connect & Enter Duo ✨'),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
