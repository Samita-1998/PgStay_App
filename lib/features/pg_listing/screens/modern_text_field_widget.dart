import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ModernTextFieldWidget extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;
  final TextInputType keyboardType;
  final bool required;

  const ModernTextFieldWidget({
    Key? key,
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.required = false,
  }) : super(key: key);

  @override
  State<ModernTextFieldWidget> createState() => _ModernTextFieldWidgetState();
}

class _ModernTextFieldWidgetState extends State<ModernTextFieldWidget> {
  late FocusNode _focusNode;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && !_hasInteracted) {
        setState(() {
          _hasInteracted = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF03045E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: GoogleFonts.plusJakartaSans(
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            if (widget.required) ...[
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isDark ? const Color(0xFF2A2A3E) : Colors.white,
                isDark ? const Color(0xFF1E1E32) : const Color(0xFFFAFAFE),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : primaryColor.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: primaryColor.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            maxLines: widget.maxLines,
            keyboardType: widget.keyboardType,
            autovalidateMode: _hasInteracted 
                ? AutovalidateMode.always 
                : AutovalidateMode.disabled,
            inputFormatters: [
              if (widget.keyboardType == TextInputType.number ||
                  widget.keyboardType == TextInputType.phone)
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (newValue.text.contains('-')) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        content: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                const SizedBox(width: 12),
                                Container(
                                  width: 4,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF59E0B),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.priority_high,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Uh oh, something went wrong',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: const Color(0xFF1E293B),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Negative numbers are not allowed.',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: const Color(0xFF9CA3AF),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    ScaffoldMessenger.of(
                                      context,
                                    ).hideCurrentSnackBar();
                                  },
                                  icon: const Icon(
                                    Icons.close,
                                    color: Color(0xFF9CA3AF),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                    return oldValue;
                  }
                  if (!RegExp(r'^[0-9]*$').hasMatch(newValue.text)) {
                    return oldValue;
                  }
                  return newValue;
                }),
            ],
            style: GoogleFonts.plusJakartaSans(
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            validator: (value) {
              if (widget.required && (value == null || value.trim().isEmpty)) {
                return 'This field is required';
              }
              if (widget.keyboardType == TextInputType.phone &&
                  value != null &&
                  value.trim().isNotEmpty) {
                if (value.trim().length != 10) {
                  return 'Please enter a valid 10-digit mobile number';
                }
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF9CA3AF),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: widget.icon != null
                  ? Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(widget.icon, color: primaryColor, size: 20),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF3A3A4E)
                      : const Color(0xFFE5E7EB),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF3A3A4E)
                      : const Color(0xFFE5E7EB),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFEF4444),
                  width: 2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFEF4444),
                  width: 2,
                ),
              ),
              errorStyle: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFEF4444),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
