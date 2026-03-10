import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/pin_service.dart';
import '../theme/app_theme.dart';

class PinSetupScreen extends StatefulWidget {
  /// Route to push after PIN is successfully created.
  final String onSuccessRoute;

  const PinSetupScreen({super.key, this.onSuccessRoute = '/home'});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  // ── State ─────────────────────────────────────────────────────────────────
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _errorMessage;

  // ── PIN entry logic ───────────────────────────────────────────────────────
  void _onDigitPressed(String digit) {
    setState(() {
      _errorMessage = null;
      if (!_isConfirming && _pin.length < 4) {
        _pin += digit;
        if (_pin.length == 4) _moveToConfirm();
      } else if (_isConfirming && _confirmPin.length < 4) {
        _confirmPin += digit;
        if (_confirmPin.length == 4) _validateAndSave();
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _errorMessage = null;
      if (_isConfirming && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      } else if (!_isConfirming && _pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  void _moveToConfirm() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() => _isConfirming = true);
    });
  }

  Future<void> _validateAndSave() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    if (_pin == _confirmPin) {
      await PinService.savePin(_pin);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, widget.onSuccessRoute);
    } else {
      setState(() {
        _errorMessage = 'PINs do not match. Please try again.';
        _confirmPin = '';
        _pin = '';
        _isConfirming = false;
      });
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final currentPin = _isConfirming ? _confirmPin : _pin;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _isConfirming
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => setState(() {
                  _isConfirming = false;
                  _confirmPin = '';
                  _pin = '';
                  _errorMessage = null;
                }),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // SingleChildScrollView is direct child of SafeArea — no Padding wrapper
          // This prevents overflow on small screens
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 36,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                _isConfirming ? 'Confirm your PIN' : 'Create a PIN',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                _isConfirming
                    ? 'Enter your PIN again to confirm'
                    : 'Choose a 4-digit PIN to protect your health data',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 48),

              // PIN dots
              _PinDots(filledCount: currentPin.length),
              const SizedBox(height: 16),

              // Error message — fixed height so layout doesn't jump
              SizedBox(
                height: 20,
                child: AnimatedOpacity(
                  opacity: _errorMessage != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _errorMessage ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.red[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Number pad
              _NumberPad(onDigit: _onDigitPressed, onBackspace: _onBackspace),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── PIN Dots ──────────────────────────────────────────────────────────────────
class _PinDots extends StatelessWidget {
  final int filledCount;
  const _PinDots({required this.filledCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final filled = i < filledCount;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppTheme.primary : Colors.transparent,
            border: Border.all(
              color: filled ? AppTheme.primary : Colors.grey[400]!,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}

// ── Number Pad ────────────────────────────────────────────────────────────────
class _NumberPad extends StatelessWidget {
  final void Function(String digit) onDigit;
  final VoidCallback onBackspace;

  const _NumberPad({required this.onDigit, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 12),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 12),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 88),
            const SizedBox(width: 12),
            _DigitButton(label: '0', onTap: () => onDigit('0')),
            const SizedBox(width: 12),
            _BackspaceButton(onTap: onBackspace),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((d) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _DigitButton(label: d, onTap: () => onDigit(d)),
        );
      }).toList(),
    );
  }
}

// ── Digit Button ──────────────────────────────────────────────────────────────
class _DigitButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DigitButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[100],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

// ── Backspace Button ──────────────────────────────────────────────────────────
class _BackspaceButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackspaceButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        height: 76,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        alignment: Alignment.center,
        child: const Icon(
          Icons.backspace_outlined,
          size: 26,
          color: Colors.black54,
        ),
      ),
    );
  }
}
