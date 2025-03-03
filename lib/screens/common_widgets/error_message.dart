import 'package:flutter/material.dart';

/// A highly reusable base error message widget that can be extended for various error types
class ErrorMessageWidget extends StatelessWidget {
  /// The title displayed at the top of the error message
  final String title;
  
  /// Primary error message text (optional)
  final String? message;
  
  /// Optional custom content widget to display between title and footer
  final Widget? content;
  
  /// Optional footer widget displayed at the bottom
  final Widget? footer;
  
  /// Custom header widget to replace the default title (optional)
  final Widget? customHeader;
  
  /// Whether to show a divider between sections
  final bool showDivider;
  
  /// Custom padding for the entire container
  final EdgeInsets padding;
  
  /// Custom border radius
  final BorderRadius borderRadius;
  
  /// Icon to display next to the title (null for no icon)
  final IconData? icon;
  
  /// Icon size
  final double iconSize;
  
  /// Custom content padding
  final EdgeInsets contentPadding;

  const ErrorMessageWidget({
    Key? key,
    required this.title,
    this.message,
    this.content,
    this.footer,
    this.customHeader,
    this.showDivider = true,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.icon = Icons.error_outline,
    this.iconSize = 16,
    this.contentPadding = const EdgeInsets.only(top: 8),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use theme colors for consistency
    final errorColor = Theme.of(context).colorScheme.error;
    
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: errorColor.withOpacity(0.05),
        borderRadius: borderRadius,
        border: Border.all(
          color: errorColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header - either custom or default
          customHeader ?? _buildDefaultHeader(context, errorColor),
          
          // Divider
          if (showDivider)
            Divider(color: errorColor.withOpacity(0.3), height: 16, thickness: 0.5),
          
          // Message
          if (message != null)
            Padding(
              padding: contentPadding,
              child: Text(
                message!,
                style: TextStyle(
                  fontSize: 13,
                  color: errorColor,
                ),
              ),
            ),
          
          // Custom content
          if (content != null)
            Padding(
              padding: message != null ? const EdgeInsets.only(top: 4) : contentPadding,
              child: content!,
            ),
          
          // Footer
          if (footer != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: footer!,
            ),
        ],
      ),
    );
  }

  /// Builds the default header with title and optional icon
  Widget _buildDefaultHeader(BuildContext context, Color errorColor) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: iconSize,
            color: errorColor,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: errorColor,
          ),
        ),
      ],
    );
  }
}