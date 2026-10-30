import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/localization/duo_strings.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/duo_colors.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../pairing/presentation/providers/pairing_provider.dart';

class ProximityHugDialog extends ConsumerStatefulWidget {
  final String partnerName;

  const ProximityHugDialog({
    super.key,
    required this.partnerName,
  });

  @override
  ConsumerState<ProximityHugDialog> createState() => _ProximityHugDialogState();
}

class _ProximityHugDialogState extends ConsumerState<ProximityHugDialog> with TickerProviderStateMixin {
  bool _isHolding = false;
  bool _isPartnerHolding = false;
  bool _hasAchievedConnection = false;
  Timer? _hapticTimer;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _setupRealtime();
  }

  void _setupRealtime() {
    final pairing = ref.read(pairingProvider);
    final duoId = pairing.space?['id'] as String?;
    final client = ref.read(supabaseClientProvider);
    if (duoId == null) return;

    _channel = client.channel('duo_pulse:$duoId');

    _channel?.onBroadcast(
      event: 'proximity_touch_start',
      callback: (payload) {
        final senderId = payload['sender_id'] as String?;
        final user = client.auth.currentUser;
        if (senderId == null || senderId == user?.id) return;

        if (mounted) {
          setState(() {
            _isPartnerHolding = true;
          });
          _checkSimultaneous();
        }
      },
    );

    _channel?.onBroadcast(
      event: 'proximity_touch_end',
      callback: (payload) {
        final senderId = payload['sender_id'] as String?;
        final user = client.auth.currentUser;
        if (senderId == null || senderId == user?.id) return;

        if (mounted) {
          setState(() {
            _isPartnerHolding = false;
          });
        }
      },
    );

    _channel?.subscribe();
  }

  void _checkSimultaneous() {
    if (_isHolding && _isPartnerHolding) {
      if (!_hasAchievedConnection) {
        setState(() => _hasAchievedConnection = true);
        HapticFeedback.heavyImpact();
      }
    }
  }

  void _startHolding() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isHolding = true;
    });

    _broadcastTouch(true);
    _checkSimultaneous();

    _hapticTimer?.cancel();
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 600), (t) {
      if (!mounted || !_isHolding) {
        t.cancel();
        return;
      }
      if (_isPartnerHolding) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    });
  }

  void _stopHolding() {
    _hapticTimer?.cancel();
    if (mounted) {
      setState(() {
        _isHolding = false;
      });
      _broadcastTouch(false);
    }
  }

  void _broadcastTouch(bool isStarting) {
    final client = ref.read(supabaseClientProvider);
    final user = client.auth.currentUser;
    if (user == null) return;

    _channel?.sendBroadcastMessage(
      event: isStarting ? 'proximity_touch_start' : 'proximity_touch_end',
      payload: {'sender_id': user.id},
    );
  }

  @override
  void dispose() {
    _hapticTimer?.cancel();
    _broadcastTouch(false);
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);

    final bothConnected = _isHolding && _isPartnerHolding;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1926) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: bothConnected
                    ? const Color(0xFFFF2E63).withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: 36,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: DuoColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Text('🫂', style: TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DuoStrings.get('virtual_hug_title', locale),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            withPartner(widget.partnerName, locale),
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              Text(
                bothConnected
                    ? DuoStrings.get('connected_celebration', locale)
                    : DuoStrings.get('virtual_hug_sub', locale),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: bothConnected ? FontWeight.bold : FontWeight.normal,
                  color: bothConnected
                      ? const Color(0xFFE11D48)
                      : (isDark ? Colors.grey[300] : Colors.grey[700]),
                ),
              ),
              const SizedBox(height: 24),

              // Interactive Touch Target
              GestureDetector(
                onTapDown: (_) => _startHolding(),
                onTapUp: (_) => _stopHolding(),
                onTapCancel: () => _stopHolding(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: bothConnected
                          ? [const Color(0xFFFF2E63), const Color(0xFFFF8FA3)]
                          : (_isHolding
                              ? [const Color(0xFFE11D48), const Color(0xFFFF4D6D)]
                              : [
                                  isDark ? const Color(0xFF2C2438) : const Color(0xFFFFF0F3),
                                  isDark ? const Color(0xFF1E1829) : const Color(0xFFFFE5EB),
                                ]),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isHolding || bothConnected)
                            ? const Color(0xFFFF2E63).withValues(alpha: 0.4)
                            : Colors.transparent,
                        blurRadius: 28,
                        spreadRadius: _isHolding ? 8 : 2,
                      ),
                    ],
                    border: Border.all(
                      color: bothConnected
                          ? const Color(0xFFFFD166)
                          : (_isHolding ? const Color(0xFFFF2E63) : DuoColors.primary.withValues(alpha: 0.3)),
                      width: bothConnected ? 3.5 : 2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          bothConnected ? '💖' : (_isHolding ? '💓' : '🤍'),
                          style: TextStyle(fontSize: _isHolding ? 48 : 42),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isHolding ? 'HOLDING...' : 'HOLD HERE',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.bold,
                            color: (_isHolding || bothConnected)
                                ? Colors.white
                                : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Live Status Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatusBadge(
                    label: DuoStrings.get('holding_status_you', locale),
                    isActive: _isHolding,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildStatusBadge(
                    label: _isPartnerHolding
                        ? DuoStrings.get('holding_status_partner', locale, params: {'name': widget.partnerName})
                        : '${widget.partnerName} (${locale == 'bn' ? 'অপেক্ষা করছে' : 'waiting'})',
                    isActive: _isPartnerHolding,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Quick Send fallback
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: DuoColors.primary),
                icon: const Text('🤗', style: TextStyle(fontSize: 16)),
                label: Text(
                  locale == 'bn' ? 'দ্রুত ভার্চুয়াল আলিঙ্গন পাঠান' : 'Send Instant Warm Hug',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Text('🤗', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              DuoStrings.get('hug_sent_toast', locale),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: DuoColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String withPartner(String name, String locale) {
    return locale == 'bn' ? '$name-এর সাথে সংযোগ' : 'Realtime touch with $name';
  }

  Widget _buildStatusBadge({
    required String label,
    required bool isActive,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF10B981).withValues(alpha: 0.15)
            : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0xFF10B981) : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? const Color(0xFF047857) : (isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
      ),
    );
  }
}
