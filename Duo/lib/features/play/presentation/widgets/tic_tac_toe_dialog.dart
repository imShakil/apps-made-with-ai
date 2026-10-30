import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/duo_colors.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../pairing/presentation/providers/pairing_provider.dart';
import '../providers/games_provider.dart';

class TicTacToeDialog extends ConsumerStatefulWidget {
  const TicTacToeDialog({super.key});

  @override
  ConsumerState<TicTacToeDialog> createState() => _TicTacToeDialogState();
}

class _TicTacToeDialogState extends ConsumerState<TicTacToeDialog> {
  bool _isCouchMode = true; // Couch play allows immediate fun on the same screen

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gameState = ref.watch(ticTacToeProvider);
    final pairingState = ref.watch(pairingProvider);
    final user = ref.watch(currentUserProvider);

    final partnerName = pairingState.partner?['display_name'] as String? ?? 'Partner';
    final myId = user?.id;
    final isOwner = pairingState.space?['created_by'] == myId;

    final mySymbol = isOwner ? '❤️' : '⭐';
    final partnerSymbol = isOwner ? '⭐' : '❤️';

    String statusText;
    Color statusColor;

    if (gameState.winnerUserId == 'draw') {
      statusText = 'It’s a Draw! 🤝';
      statusColor = Colors.grey;
    } else if (gameState.winnerUserId == 'heart_win') {
      statusText = 'Hearts Won! ❤️🎉';
      statusColor = DuoColors.primary;
    } else if (gameState.winnerUserId == 'star_win') {
      statusText = 'Stars Won! ⭐🎉';
      statusColor = DuoColors.secondary;
    } else if (gameState.winnerUserId != null) {
      final isWinnerMe = gameState.winnerUserId == myId;
      statusText = isWinnerMe ? 'You Won! 🎉💖' : '$partnerName Won! ✨';
      statusColor = isWinnerMe ? DuoColors.primary : DuoColors.secondary;
    } else if (_isCouchMode) {
      final heartCount = gameState.board.where((e) => e == 'heart').length;
      final starCount = gameState.board.where((e) => e == 'star').length;
      final nextSymbol = heartCount <= starCount ? '❤️ Hearts' : '⭐ Stars';
      statusText = 'Couch Mode: $nextSymbol Turn';
      statusColor = DuoColors.primary;
    } else if (gameState.isMyTurn) {
      statusText = 'Your Turn ($mySymbol)!';
      statusColor = DuoColors.primary;
    } else {
      statusText = 'Waiting for $partnerName ($partnerSymbol)...';
      statusColor = Colors.grey;
    }

    return Dialog(
      backgroundColor: isDark ? DuoColors.cardDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Text('🎮', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 8),
                    Text(
                      'Love Tic-Tac-Toe',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Mode Selector Pill (Couch vs Remote)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : DuoColors.bgLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() => _isCouchMode = true);
                      ref.read(ticTacToeProvider.notifier).resetCouchGame();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isCouchMode ? DuoColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '🛋️ Couch Mode',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _isCouchMode ? Colors.white : (isDark ? Colors.grey : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _isCouchMode = false);
                      ref.read(ticTacToeProvider.notifier).startNewGame();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: !_isCouchMode ? DuoColors.secondary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '🌐 Realtime Sync',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: !_isCouchMode ? Colors.white : (isDark ? Colors.grey : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Turn & Winner Status Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 3x3 Board
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : DuoColors.bgLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? DuoColors.borderDark : DuoColors.borderLight),
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    final token = gameState.board[index];
                    final isWinningSquare = gameState.winningLine?.contains(index) == true;

                    Widget? content;
                    if (token == 'heart') {
                      content = const Text('❤️', style: TextStyle(fontSize: 34))
                          .animate()
                          .scale(duration: 250.ms, curve: Curves.easeOutBack);
                    } else if (token == 'star') {
                      content = const Text('⭐', style: TextStyle(fontSize: 34))
                          .animate()
                          .scale(duration: 250.ms, curve: Curves.easeOutBack);
                    }

                    return GestureDetector(
                      onTap: () {
                        if (token == null && gameState.winnerUserId == null) {
                          if (_isCouchMode) {
                            ref.read(ticTacToeProvider.notifier).playCouchMove(index);
                          } else if (gameState.isMyTurn) {
                            ref.read(ticTacToeProvider.notifier).makeMove(index);
                          }
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          color: isWinningSquare
                              ? DuoColors.primary.withValues(alpha: 0.25)
                              : (isDark ? DuoColors.cardDark : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isWinningSquare
                                ? DuoColors.primary
                                : (isDark ? Colors.transparent : DuoColors.borderLight),
                            width: isWinningSquare ? 2.5 : 1,
                          ),
                          boxShadow: [
                            if (!isDark)
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Center(child: content),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Controls
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('New Match 🔄'),
                    onPressed: () {
                      if (_isCouchMode) {
                        ref.read(ticTacToeProvider.notifier).resetCouchGame();
                      } else {
                        ref.read(ticTacToeProvider.notifier).startNewGame();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
