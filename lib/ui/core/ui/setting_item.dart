import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SettingItem extends StatefulWidget {
  final ColorScheme colorScheme;
  final String? icon;
  final String title;
  final String? subTitle;
  final String? currentValue;
  final bool switchButton;
  final ValueChanged<bool>? onSwitchChange;
  final bool showBottomLine;
  final bool showSubTitle;
  final bool showIcon;
  final bool showSwitchButton;
  final bool showCurrentValue;

  final GestureTapCallback? onClick;

  const SettingItem({
    super.key,
    required this.colorScheme,
    this.icon,
    required this.title,
    this.subTitle,
    this.currentValue,
    this.showBottomLine = true,
    this.showIcon = true,
    this.showSwitchButton = false,
    this.showCurrentValue = false,
    this.onClick,
    this.showSubTitle = false,
    this.switchButton = false,
    this.onSwitchChange,
  });

  @override
  State<SettingItem> createState() => _SettingItemState();
}

class _SettingItemState extends State<SettingItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _colorAnimation = ColorTween(
      begin: widget.colorScheme.surfaceContainerHigh,
      end: widget.colorScheme.surfaceContainerHigh.withValues(alpha: 0.7),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse().then((_) {
      if (widget.onClick != null) {
        widget.onClick!();
      }
    });
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_animationController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: Container(
              width: double.infinity,
              height: 48.h,
              decoration: widget.showBottomLine
                  ? BoxDecoration(
                color: _colorAnimation.value,
                border: Border(
                  bottom: BorderSide(
                    color: widget.colorScheme.outline.withValues(alpha: 0.5),
                    width: 1.0,
                  ),
                ),
              )
                  : BoxDecoration(
                color: _colorAnimation.value,
              ),
              child: Row(
                children: [
                  if (widget.showIcon)
                    SvgPicture.asset(
                      widget.icon ?? "assets/icons/icon_device.svg",
                      height: 24.h,
                      colorFilter: ColorFilter.mode(
                          widget.colorScheme.onSurfaceVariant, BlendMode.srcIn),
                    ),
                  SizedBox(width: 8.w),
                  Column(
                    mainAxisAlignment: widget.showSubTitle == false
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: widget.showSubTitle == false ? 18.sp : 16.sp,
                          color: widget.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (widget.showSubTitle)
                        Text(
                          widget.subTitle ?? "",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: widget.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                    ],
                  ),
                  Spacer(),
                  if (widget.showCurrentValue)
                    Text(
                      widget.currentValue ?? "",
                      style: TextStyle(
                        fontSize: 18.sp,
                        color: widget.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  if (widget.showSwitchButton)
                    Switch(
                      activeColor: widget.colorScheme.primary,
                      activeTrackColor:
                      widget.colorScheme.primary.withValues(alpha: 0.5),
                      inactiveThumbColor: widget.colorScheme.onSurface
                          .withValues(alpha: 0.38),
                      inactiveTrackColor: widget.colorScheme.surface,
                      value: widget.switchButton,
                      onChanged: widget.onSwitchChange ?? (value) => {},
                    )
                  else
                    Icon(
                      Icons.keyboard_arrow_right,
                      color: widget.colorScheme.onSurfaceVariant,
                      size: 32.r,
                    )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}



