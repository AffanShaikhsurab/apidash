import 'package:apidash/screens/common_widgets/error_message.dart';
import 'package:flutter/material.dart';

/// JSON-specific error widget that extends the base ErrorMessageWidget
class JsonErrorWidget extends StatelessWidget {
  /// The error message from the JSON parser
  final String? errorMessage;
  
  /// The line number where the error occurred
  final int? errorLine;
  
  /// The text content of the line with the error
  final String? errorLineText;
  
  /// The column number where the error occurred
  final int? errorColumn;
  
  /// What the parser expected to find
  final String? expected;

  const JsonErrorWidget({
    Key? key,
    this.errorMessage,
    this.errorLine,
    this.errorLineText,
    this.errorColumn,
    this.expected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorMessageWidget(
      title: 'Invalid JSON!',
      message: errorLine != null 
          ? 'Error: Parse error on line ${errorLine}:'
          : errorMessage,
      content: _buildJsonErrorContent(context),
      footer: _buildExpectedGotFooter(context),
    );
  }

  /// Builds the code snippet with error pointer
  Widget? _buildJsonErrorContent(BuildContext context) {
    if (errorLineText == null) return null;
    
    final errorColor = Theme.of(context).colorScheme.error;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Code line
        Text(
          errorLineText!,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
          ),
        ),
        
        // Error pointer
        if (errorColumn != null)
          Text(
            '${' ' * (errorColumn! - 1)}^',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: errorColor,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  /// Builds the expected vs got footer section
  Widget? _buildExpectedGotFooter(BuildContext context) {
    if (expected == null) return null;
    
    final errorColor = Theme.of(context).colorScheme.error;
    
    return Text(
      "Expecting '${expected ?? "?"}'",
      style: TextStyle(
        fontSize: 13,
        color: errorColor,
      ),
    );
  }
}