import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';
import '../theme.dart';

/// Withdrawals at or above this amount require authentication.
const double kWealthProtectionWithdrawalThreshold = 5000.0;

/// Challenge the user to authenticate for a sensitive financial action.
///
/// Returns true if:
/// - Running on web (biometrics/PIN not applicable)
/// - Wealth protection is disabled
/// - The user successfully authenticates
///
/// Returns false if the user cancels or fails authentication.
Future<bool> challengeTransactionAuth(
  BuildContext context, {
  String reason = 'Authenticate to continue',
}) async {
  if (kIsWeb) return true;

  final enabled = await AppLockService.isWealthProtectionEnabled();
  if (!enabled) return true;

  final method = await AppLockService.getWealthAuthMethod();
  final biometricAvailable = await AppLockService.isBiometricAvailable();

  // Try biometric first if the method allows it
  if ((method == 'biometric' || method == 'any') && biometricAvailable) {
    final success = await AppLockService.authenticateWithBiometric();
    if (success) return true;
    // biometric-only mode and it failed → deny
    if (method == 'biometric') return false;
    // 'any' mode → fall through to PIN
  }

  // PIN challenge
  if (method == 'pin' || method == 'any') {
    final pinSet = await AppLockService.hasPin();
    // No PIN configured yet → allow gracefully (user hasn't set one up)
    if (!pinSet) return true;
    if (!context.mounted) return false;
    return _showPinChallengeDialog(context);
  }

  return false;
}

Future<bool> _showPinChallengeDialog(BuildContext context) async {
  final ctrl = TextEditingController();
  var attempts = 0;
  var authResult = false;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        Future<void> checkPin() async {
          final ok = await AppLockService.verifyPin(ctrl.text);
          if (ok) {
            authResult = true;
            if (ctx.mounted) Navigator.pop(ctx);
          } else {
            ctrl.clear();
            setState(() => attempts++);
            if (ctx.mounted && attempts >= 3) {
              Navigator.pop(ctx);
            }
          }
        }

        return AlertDialog(
          backgroundColor: TradEtTheme.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TradEtTheme.positive.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_rounded,
                    color: TradEtTheme.positive, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Enter PIN',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your security PIN to confirm this action',
                  style: TextStyle(
                      color: TradEtTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                autofocus: true,
                style: const TextStyle(
                    color: Colors.white, letterSpacing: 12, fontSize: 22),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '• • • •',
                  hintStyle: TextStyle(
                      color: TradEtTheme.textMuted, letterSpacing: 8),
                ),
                onChanged: (v) {
                  if (v.length == 4) checkPin();
                },
              ),
              if (attempts > 0 && attempts < 3) ...[
                const SizedBox(height: 10),
                Text(
                  '${3 - attempts} attempt(s) remaining',
                  style: const TextStyle(
                      color: TradEtTheme.negative, fontSize: 11),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: TradEtTheme.textSecondary)),
            ),
          ],
        );
      },
    ),
  );

  ctrl.dispose();
  return authResult;
}
