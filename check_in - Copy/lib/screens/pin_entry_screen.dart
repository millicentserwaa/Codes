import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/pin_service.dart';
import '../theme/app_theme.dart';

class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

enum _PinScreenMode { entering, forgotDob, settingNewPin, confirmingNewPin }

class _PinEntryScreenState extends State<PinEntryScreen> {
  _PinScreenMode _mode = _PinScreenMode.entering;

  String _pin = '';
  String _newPin = '';
  String? _errorMessage;
  bool _isLoading = false;

  int? _dobDay;
  int? _dobMonth;
  int? _dobYear;

  void _onDigitPressed(String digit) {
    if (_isLoading) return;
    setState(() {
      _errorMessage = null;
      if (_pin.length < 4) {
        _pin += digit;
        if (_pin.length == 4) _handleComplete();
      }
    });
  }

  void _onBackspace() {
    if (_isLoading) return;
    setState(() {
      _errorMessage = null;
      if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _handleComplete() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    switch (_mode) {
      case _PinScreenMode.entering:
        await _verifyPin();
        break;
      case _PinScreenMode.settingNewPin:
        setState(() {
          _newPin = _pin;
          _pin = '';
          _mode = _PinScreenMode.confirmingNewPin;
        });
        break;
      case _PinScreenMode.confirmingNewPin:
        await _saveNewPin();
        break;
      default:
        break;
    }
  }

  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);
    final correct = await PinService.verifyPin(_pin);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (correct) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() {
        _pin = '';
        _errorMessage = 'Incorrect PIN. Please try again.';
      });
    }
  }

  void _onForgotPin() {
    setState(() {
      _mode = _PinScreenMode.forgotDob;
      _pin = '';
      _errorMessage = null;
      _dobDay = null;
      _dobMonth = null;
      _dobYear = null;
    });
  }

  Future<void> _verifyDob() async {
    if (_dobDay == null || _dobMonth == null || _dobYear == null) {
      setState(
        () => _errorMessage = 'Please enter your complete date of birth.',
      );
      return;
    }
    setState(() => _isLoading = true);
    final enteredDob = DateTime(_dobYear!, _dobMonth!, _dobDay!);
    final correct = await PinService.verifyDob(enteredDob);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (correct) {
      setState(() {
        _mode = _PinScreenMode.settingNewPin;
        _pin = '';
        _newPin = '';
        _errorMessage = null;
      });
    } else {
      setState(
        () => _errorMessage = 'Date of birth does not match our records.',
      );
    }
  }

  Future<void> _saveNewPin() async {
    if (_pin != _newPin) {
      setState(() {
        _errorMessage = 'PINs do not match. Please try again.';
        _pin = '';
        _newPin = '';
        _mode = _PinScreenMode.settingNewPin;
      });
      return;
    }
    await PinService.savePin(_pin);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _mode == _PinScreenMode.forgotDob
            ? _buildForgotDobView()
            : _buildPinView(),
      ),
    );
  }

  Widget _buildPinView() {
    String title, subtitle;
    switch (_mode) {
      case _PinScreenMode.entering:
        title = 'Welcome back';
        subtitle = 'Enter your PIN to continue';
        break;
      case _PinScreenMode.settingNewPin:
        title = 'Set a new PIN';
        subtitle = 'Choose a new 4-digit PIN';
        break;
      case _PinScreenMode.confirmingNewPin:
        title = 'Confirm new PIN';
        subtitle = 'Enter your new PIN again';
        break;
      default:
        title = '';
        subtitle = '';
    }

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
            const SizedBox(height: 56),

            // App icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.favorite_rounded,
                size: 36,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),

            // PIN dots
            _PinDots(filledCount: _pin.length),
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
            const SizedBox(height: 8),

            // Forgot PIN — always renders, visibility controlled by opacity
            // Using AnimatedOpacity so layout space is always reserved —
            // no layout shift, no overflow
            AnimatedOpacity(
              opacity: _mode == _PinScreenMode.entering ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: TextButton(
                onPressed: _mode == _PinScreenMode.entering
                    ? _onForgotPin
                    : null,
                child: Text(
                  'Forgot PIN?',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Number pad
            _NumberPad(
              onDigit: _onDigitPressed,
              onBackspace: _onBackspace,
            ),
            const SizedBox(height: 40),
          ],
      ),
    );
  }

  Widget _buildForgotDobView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => setState(() {
              _mode = _PinScreenMode.entering;
              _errorMessage = null;
              _pin = '';
            }),
            child: const Icon(Icons.arrow_back, color: Colors.black87),
          ),
          const SizedBox(height: 32),
          Text(
            'Forgot your PIN?',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your date of birth to verify your identity and set a new PIN.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 40),
          _dobField(
            label: 'Day',
            hint: 'DD',
            maxLength: 2,
            onChanged: (val) => setState(() => _dobDay = int.tryParse(val)),
          ),
          const SizedBox(height: 16),
          _dobField(
            label: 'Month',
            hint: 'MM',
            maxLength: 2,
            onChanged: (val) => setState(() => _dobMonth = int.tryParse(val)),
          ),
          const SizedBox(height: 16),
          _dobField(
            label: 'Year',
            hint: 'YYYY',
            maxLength: 4,
            onChanged: (val) => setState(() => _dobYear = int.tryParse(val)),
          ),
          const SizedBox(height: 12),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _errorMessage!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.red[600],
                ),
              ),
            ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyDob,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Verify Identity',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _dobField({
    required String label,
    required String hint,
    required int maxLength,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          keyboardType: TextInputType.number,
          maxLength: maxLength,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
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
      children: digits
          .map(
            (d) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _DigitButton(label: d, onTap: () => onDigit(d)),
            ),
          )
          .toList(),
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