import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'design_tokens.dart';

class MenuBubble extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const MenuBubble({
    super.key,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: iconColor, size: 27),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChildAvatar extends StatelessWidget {
  final double size;
  final bool selected;
  final Color? statusColor;
  final Color faceColor;

  const ChildAvatar({
    super.key,
    this.size = 48,
    this.selected = false,
    this.statusColor,
    this.faceColor = const Color(0xFFFFE78A),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 8,
      height: size + 8,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (selected)
            Container(
              width: size + 6,
              height: size + 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.parent, width: 2),
              ),
            ),
          CustomPaint(
            size: Size.square(size),
            painter: _ChildFacePainter(faceColor),
          ),
          if (statusColor != null)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChildFacePainter extends CustomPainter {
  final Color faceColor;

  const _ChildFacePainter(this.faceColor);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    canvas.drawCircle(center, radius, Paint()..color = faceColor);

    final eyePaint = Paint()..color = const Color(0xFF334155);
    final eyeRadius = radius * 0.055;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.32, center.dy - radius * 0.12),
      eyeRadius,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.32, center.dy - radius * 0.12),
      eyeRadius,
      eyePaint,
    );

    final cheekPaint = Paint()..color = const Color(0xFFFFA5A5);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.48, center.dy + radius * 0.18),
      radius * 0.11,
      cheekPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.48, center.dy + radius * 0.18),
      radius * 0.11,
      cheekPaint,
    );

    final smile = Path()
      ..moveTo(center.dx - radius * 0.23, center.dy + radius * 0.12)
      ..quadraticBezierTo(
        center.dx,
        center.dy + radius * 0.52,
        center.dx + radius * 0.23,
        center.dy + radius * 0.12,
      );
    canvas.drawPath(
      smile,
      Paint()
        ..color = const Color(0xFF7C3F2C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, radius * 0.09)
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ChildFacePainter oldDelegate) =>
      oldDelegate.faceColor != faceColor;
}

class HeroCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  const HeroCard({
    super.key,
    required this.child,
    required this.color,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        children: [
          Positioned(
            right: -38,
            top: -56,
            child: _CircleDecoration(color: Colors.white.withValues(alpha: .1)),
          ),
          Positioned(
            right: 18,
            bottom: -92,
            child: _CircleDecoration(color: Colors.white.withValues(alpha: .07)),
          ),
          Container(
            width: double.infinity,
            padding: padding,
            decoration: BoxDecoration(color: color),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _CircleDecoration extends StatelessWidget {
  final Color color;

  const _CircleDecoration({required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 150,
    height: 150,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class ChipSelector extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final Color roleColor;
  final Color softColor;

  const ChipSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.roleColor,
    required this.softColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected == option;
        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => onSelected(option),
          showCheckmark: false,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : roleColor,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
          backgroundColor: softColor,
          selectedColor: roleColor,
          side: BorderSide.none,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 5),
        );
      }).toList(),
    );
  }
}

class LogoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const LogoutButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Keluar akun',
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.logoutBackground,
        foregroundColor: AppColors.logoutForeground,
      ),
      icon: const Icon(Icons.logout_rounded, size: 19),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  final bool isKader;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.isKader,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isKader ? AppColors.kader : AppColors.parent;
    final mid = isKader ? AppColors.kaderMid : AppColors.parentMid;
    final labels = isKader
        ? const ['Beranda', 'Anak', '', 'Jadwal', 'Profil']
        : const ['Beranda', 'Anak', 'Kalender', 'Artikel', 'Profil'];
    final icons = isKader
        ? const [
            Icons.home_outlined,
            Icons.child_care_outlined,
            Icons.monitor_weight_outlined,
            Icons.calendar_month_outlined,
            Icons.person_outline,
          ]
        : const [
            Icons.home_outlined,
            Icons.child_care_outlined,
            Icons.calendar_month_outlined,
            Icons.article_outlined,
            Icons.person_outline,
          ];

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (index) {
            if (isKader && index == 2) {
              return SizedBox(
                width: 58,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Transform.translate(
                    offset: const Offset(0, -18),
                    child: Material(
                      color: primary,
                      shape: const CircleBorder(),
                      elevation: 5,
                      child: InkWell(
                        onTap: () => onTap(index),
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 52,
                          height: 52,
                          child: Icon(
                            Icons.monitor_weight_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
            final selected = index == selectedIndex;
            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? mid : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          icons[index],
                          size: 19,
                          color: selected ? primary : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        labels[index],
                        style: TextStyle(
                          color: selected
                              ? primary
                              : const Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
