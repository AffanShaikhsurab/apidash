import 'dart:async';
import 'dart:convert';
import 'dart:math';

abstract class JsonValidator {
  void validate(String value);
  void dispose();
}

class JsonDocumentValidator implements JsonValidator {
  // Removed the last String? parameter (got)
  final Function(bool, String?, int?, int?, String?) onValidationResult;
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 500);

  JsonDocumentValidator({required this.onValidationResult});

  @override
  void validate(String value) {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(_debounceDuration, () {
      if (value.trim().isEmpty) {
        // Removed last null parameter
        onValidationResult(false, null, null, null, null);
        return;
      }

      try {
        json.decode(value);
        // Removed last null parameter
        onValidationResult(false, null, null, null, null);
      } catch (e) {
        _handleJsonError(e, value);
      }
    });
  }

  @override
  void dispose() => _debounceTimer?.cancel();

  void _handleJsonError(dynamic error, String value) {
    final errMsg = error.toString().replaceAll('FormatException: ', '');
    final positionRegex = RegExp(r'(?:at line |on line )(\d+)(?:, (?:character|column) (\d+))?');
    final match = positionRegex.firstMatch(errMsg);

    int? line = match != null ? int.tryParse(match.group(1)!) : null;
    int? column = match?.group(2) != null ? int.tryParse(match!.group(2)!) : null;

    // Fallback to offset-based position detection
    if (line == null || column == null) {
      _extractPositionFromOffset(errMsg, value, (l, c) {
        line = l;
        column = c;
      });
    }

    // Still extract the unexpected character for internal use
    final unexpectedChar = _extractUnexpectedCharacter(value, line, column);
    final expected = _determineExpectedValue(errMsg, unexpectedChar, value, line, column);
    
    // Removed the unexpectedChar parameter from the callback
    onValidationResult(true, errMsg, line, column, expected);
  }

  void _extractPositionFromOffset(String error, String json, Function(int, int) setPosition) {
    final offsetMatch = RegExp(r'position (\d+)').firstMatch(error);
    if (offsetMatch == null) return;

    final offset = int.parse(offsetMatch.group(1)!);
    int currentLine = 1;
    int currentColumn = 1;

    for (int i = 0; i < offset && i < json.length; i++) {
      if (json[i] == '\n') {
        currentLine++;
        currentColumn = 1;
      } else {
        currentColumn++;
      }
    }

    setPosition(currentLine, currentColumn);
  }

  String? _extractUnexpectedCharacter(String value, int? line, int? column) {
    if (line == null || column == null) return null;

    final lines = value.split('\n');
    if (line > lines.length) return null;

    final errorLine = lines[line - 1];
    return column <= errorLine.length ? errorLine[column - 1] : null;
  }

  String _determineExpectedValue(String error, String? char, String json, int? line, int? column) {
    // Prioritize string termination checks
    if (line != null && column != null) {
      final unclosedString = _checkForUnclosedString(json, line, column);
      if (unclosedString) {
        return 'closing quote for string';
      }

      final context = _analyzeStringContext(json, line, column);
      if (context != null) {
        return context;
      }
    }

    // Check specifically for unclosed string scenarios
    if (error.contains('unterminated string literal') ||
        error.contains('unexpected end of input')) {
      return 'closing quote for string';
    }

    // Handle specific unexpected characters
    switch (char) {
      case ']':
        return 'value or closing bracket';
      case '}':
        return 'property name or closing brace';
      case ',':
        return 'value after comma';
      case ':':
        return 'value after colon';
    }

    // Analyze JSON structure context
    if (line != null && column != null) {
      return _analyzeJsonContext(json, line, column) ?? 'valid JSON syntax';
    }

    return error.contains('unexpected character') ? 'valid JSON syntax' : error;
  }

  String? _analyzeStringContext(String json, int line, int column) {
    final lines = json.split('\n');
    if (line > lines.length) return null;

    final errorLine = lines[line - 1].substring(0, column);
    final quoteCount = '"'.allMatches(errorLine).length;

    // Check if we're inside an unclosed string (odd number of quotes)
    if (quoteCount % 2 != 0) {
      return 'closing quote for string';
    }

    // Check if there are unescaped characters after the last quote
    final lastQuoteIndex = errorLine.lastIndexOf('"');
    if (lastQuoteIndex != -1 &&
        errorLine.substring(lastQuoteIndex + 1).contains(RegExp(r'[^\\]'))) {
      return 'properly escaped string content';
    }

    return null;
  }

  String? _analyzeJsonContext(String json, int line, int column) {
    final lines = json.split('\n');
    if (line > lines.length) return null;

    final context = lines[line - 1].substring(0, column);
    final stack = <String>[];

    for (final char in context.split('')) {
      switch (char) {
        case '{':
          stack.add('}');
          break;
        case '[':
          stack.add(']');
          break;
        case '}':
        case ']':
          if (stack.isNotEmpty && stack.last == char) stack.removeLast();
          break;
      }
    }


    if (stack.isNotEmpty) {
      final last = stack.last;
      return last == '}' ? 'property name or closing brace' : 'value or closing bracket';
    }

    if (context.trim().endsWith(':')) return 'value after colon';
    if (context.trim().endsWith(',')) return 'value after comma';

    return null;
  }

  // New helper method to specifically check for unclosed strings
  bool _checkForUnclosedString(String json, int line, int column) {
    final lines = json.split('\n');
    if (line > lines.length) return false;

    // Check the current line up to the error position
    final lineContent = lines[line - 1];
    final relevantPart = lineContent.substring(0, min(column, lineContent.length));

    // Count quotes to see if we have an unclosed string
    int quoteCount = 0;
    bool escaped = false;

    for (int i = 0; i < relevantPart.length; i++) {
      final char = relevantPart[i];

      if (char == '\\') {
        escaped = !escaped;
      } else if (char == '"' && !escaped) {
        quoteCount++;
      } else {
        escaped = false;
      }
    }
    // Odd number of quotes means unclosed string
    return quoteCount % 2 != 0;
  }
}