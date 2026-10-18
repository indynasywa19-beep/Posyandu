import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kAuthBlue = Color(0xFF1D4ED8);
const Color kAuthGreen = Color(0xFF15803D);

const LinearGradient kAuthGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF1D4ED8), Color(0xFF0F766E), Color(0xFF15803D)],
  stops: [0, 0.55, 1],
);

/// Wajah anak bulat yang lucu (digambar dengan CustomPaint).
class SmileyFace extends StatelessWidget {
  final Color color;
  final double size;
  const SmileyFace({super.key, required this.color, this.size = 76});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FacePainter(color)),
    );
  }
}

class _FacePainter extends CustomPainter {
  final Color bg;
  _FacePainter(this.bg);

  @override
  void paint(Canvas canvas, Size s) {
    final r = s.width / 2;
    canvas.drawCircle(Offset(r, r), r, Paint()..color = bg);

    final eye = Paint()..color = const Color(0xFF1F2937);
    canvas.drawCircle(Offset(s.width * .35, s.height * .45), s.width * .05, eye);
    canvas.drawCircle(Offset(s.width * .65, s.height * .45), s.width * .05, eye);

    final blush = Paint()..color = const Color(0x80FB7185);
    canvas.drawCircle(Offset(s.width * .24, s.height * .58), s.width * .06, blush);
    canvas.drawCircle(Offset(s.width * .76, s.height * .58), s.width * .06, blush);

    final smile = Paint()
      ..color = const Color(0xFF1F2937)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * .05
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(s.width * .35, s.height * .63)
      ..quadraticBezierTo(s.width * .5, s.height * .78, s.width * .65, s.height * .63);
    canvas.drawPath(path, smile);
  }

  @override
  bool shouldRepaint(covariant _FacePainter old) => old.bg != bg;
}

/// Kerangka halaman login/daftar: header gradasi + lembaran putih melengkung.
class AuthLayout extends StatelessWidget {
  final double headerHeight;
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final Widget child;

  const AuthLayout({
    super.key,
    required this.headerHeight,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _header(context),
                Transform.translate(
                  offset: const Offset(0, -34),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(36)),
                    ),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      height: headerHeight + topInset,
      width: double.infinity,
      decoration: const BoxDecoration(gradient: kAuthGradient),
      child: Stack(
        children: [
          Positioned(
            left: -40,
            top: -50,
            child: _bubble(170, 0.12),
          ),
          Positioned(
            right: -50,
            bottom: 10,
            child: _bubble(150, 0.10),
          ),
          if (onBack != null)
            Positioned(
              left: 8,
              top: topInset + 8,
              child: IconButton(
                tooltip: 'Kembali',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(top: topInset, bottom: 30),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ringFace(const Color(0xFFBFDBFE)),
                      Transform.translate(
                        offset: const Offset(-18, 0),
                        child: _ringFace(const Color(0xFFBBF7D0)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: GoogleFonts.fredoka(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.nunito(fontSize: 13.5, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );

  Widget _ringFace(Color c) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: SmileyFace(color: c, size: 76),
      );
}

/// Input bulat dengan ikon; password otomatis punya ikon mata.
class AuthField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _obscure = true;

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(27),
        borderSide: BorderSide(color: c, width: 2),
      );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: widget.isPassword && _obscure,
      validator: widget.validator,
      style: GoogleFonts.nunito(fontSize: 15, color: const Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: GoogleFonts.nunito(color: const Color(0xFF64748B)),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIcon: Icon(widget.icon, color: const Color(0xFF475569)),
        suffixIcon: widget.isPassword
            ? IconButton(
                tooltip: _obscure ? 'Tampilkan password' : 'Sembunyikan password',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF64748B),
                ),
              )
            : null,
        border: _border(const Color(0xFFE2E8F0)),
        enabledBorder: _border(const Color(0xFFE2E8F0)),
        focusedBorder: _border(kAuthBlue),
        errorBorder: _border(const Color(0xFFDC2626)),
        focusedErrorBorder: _border(const Color(0xFFDC2626)),
      ),
    );
  }
}

/// Tombol utama bergradasi biru-hijau.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.7 : 1,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: kAuthGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: kAuthBlue.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onPressed,
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        label,
                        style: GoogleFonts.fredoka(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Titik keterangan role kecil di bawah halaman login.
class RoleDot extends StatelessWidget {
  final Color color;
  final String label;
  const RoleDot({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}