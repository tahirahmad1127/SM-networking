import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../configurations/frontend_configs.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    this.icon = "",
    required this.text,
    this.hintColor,
    required this.onTap,
    this.maxLines = 1,
    this.isPasswordField = false,
    this.isSecure = false,
    this.textInputAction,
    required this.keyBoardType,
    this.readOnly = false, // ← NEW: Optional read-only
    this.suffixIcon,        // ← Optional: Custom suffix
    this.hintText,          // ← Optional: Override hint
  });

  final String icon;
  final String text;
  final TextInputType keyBoardType;
  final TextInputAction? textInputAction;
  final TextEditingController? controller;
  final Color? hintColor;
  final int maxLines;
  final bool isPasswordField;
  final bool isSecure;
  final VoidCallback onTap;
  final bool readOnly;           // ← NEW
  final Widget? suffixIcon;      // ← NEW
  final String? hintText;        // ← NEW

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _isSecure;

  @override
  void initState() {
    super.initState();
    _isSecure = widget.isSecure;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.readOnly ? null : widget.keyBoardType,
      textInputAction: widget.textInputAction,
      maxLines: widget.maxLines,
      obscureText: widget.isPasswordField ? _isSecure : false,
      readOnly: widget.readOnly, // ← Enable read-only
      enableInteractiveSelection: !widget.readOnly, // ← No select/copy
      showCursor: !widget.readOnly, // ← Hide cursor
      onTap: widget.readOnly ? widget.onTap : null, // ← Tap only if readOnly
      style: TextStyle(
        color: widget.readOnly ? Colors.grey.shade700 : null,
        fontWeight: widget.readOnly ? FontWeight.w500 : null,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText ?? widget.text,
        hintStyle: TextStyle(
          color: widget.hintColor ?? FrontendConfigs.kAuthTextColor,
          fontSize: 14,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: FrontendConfigs.kAppBorder,
          borderSide: BorderSide.none,
        ),
        fillColor: widget.readOnly
            ? FrontendConfigs.kTextFieldColor.withOpacity(0.6)
            : FrontendConfigs.kTextFieldColor,
        filled: true,
        suffixIcon: widget.suffixIcon ??
            (widget.isPasswordField
                ? _buildPasswordToggle()
                : (widget.icon.isNotEmpty
                ? _buildIcon()
                : null)),
      ),
    );
  }

  Widget _buildPasswordToggle() {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: InkWell(
        onTap: widget.readOnly
            ? null
            : () {
          setState(() {
            _isSecure = !_isSecure;
          });
          widget.onTap();
        },
        child: Icon(
          _isSecure ? Icons.remove_red_eye_outlined : Icons.visibility_off_outlined,
          color: widget.readOnly ? Colors.grey.shade400 : Colors.grey,
          size: 23,
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: SvgPicture.asset(
        widget.icon,
        color: widget.readOnly ? Colors.grey.shade400 : Colors.grey,
      ),
    );
  }
}