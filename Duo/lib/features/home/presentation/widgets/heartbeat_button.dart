import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/duo_strings.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/widgets/bouncy_press.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../providers/heartbeat_provider.dart';

class HeartbeatButton extends ConsumerWidget {
  const HeartbeatButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final user = ref.watch(currentUserProvider);
    final myName = user?.userMetadata?['full_name'] as String? ?? 'You';

    return Tooltip(
      message: DuoStrings.get('heartbeat_tooltip', locale),
      child: BouncyPress(
        semanticsLabel: DuoStrings.get('heartbeat_tooltip', locale),
        onTap: () async {
          final sent = await ref.read(heartbeatProvider.notifier).sendHeartbeat(myName);
          if (sent && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Text('💓', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        DuoStrings.get('heartbeat_sent', locale),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFFE11D48),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF2E63).withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFF2E63).withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: Color(0xFFFF2E63),
            size: 20,
          ),
        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
         .scale(
           begin: const Offset(0.92, 0.92),
           end: const Offset(1.15, 1.15),
           duration: 900.ms,
           curve: Curves.easeInOut,
         ),
      ),
    );
  }
}
