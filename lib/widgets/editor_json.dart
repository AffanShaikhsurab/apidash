
import 'dart:math' as math;
import 'package:apidash/consts.dart';
import 'package:apidash/widgets/json_error_message.dart';
import 'package:apidash/widgets/json_validator.dart';
import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_text_field/json_text_field.dart';

class JsonTextFieldEditor extends StatefulWidget {
  const JsonTextFieldEditor({
    super.key,
    required this.fieldKey,
    this.onChanged,
    this.initialValue,
    this.hintText = kHintJson,
    this.autofocus = false,
    this.readOnly = false,
  });

  final String fieldKey;
  final Function(String)? onChanged;
  final String? initialValue;
  final String hintText;
  final bool autofocus;
  final bool readOnly;

  @override
  State<JsonTextFieldEditor> createState() => JsonTextFieldEditorState();
}

class JsonTextFieldEditorState extends State<JsonTextFieldEditor> {
  final JsonTextFieldController controller = JsonTextFieldController();
  late final FocusNode editorFocusNode;
  late final JsonValidator validator;
  
  bool hasError = false;
  String? errorMessage;
  int? errorLine;
  int? errorColumn;
  String? expected;
  
  // Utility method for inserting tabs
  void insertTab() {
    String sp = "  ";
    int offset = math.min(
        controller.selection.baseOffset, controller.selection.extentOffset);
    String text = controller.text.substring(0, offset) +
        sp +
        controller.text.substring(offset);
    controller.value = TextEditingValue(
      text: text,
      selection: controller.selection.copyWith(
        baseOffset: controller.selection.baseOffset + sp.length,
        extentOffset: controller.selection.extentOffset + sp.length,
      ),
    );
    widget.onChanged?.call(text);
  }

  // Scroll to error line for better UX
  void _scrollToErrorLine() {
    if (errorLine == null) return;
    
    try {
      final lines = controller.text.split('\n');
      
      if (errorLine! <= lines.length) {
        int offset = 0;
        
        for (int i = 0; i < errorLine! - 1; i++) {
          offset += lines[i].length + 1; // +1 for newline
        }
        
        final columnOffset = errorColumn != null ? 
            math.min(errorColumn! - 1, lines[errorLine! - 1].length) : 0;
        
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: offset + columnOffset),
        );
        
        editorFocusNode.requestFocus();
      }
    } catch (e) {
      print('Error scrolling to line: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    editorFocusNode = FocusNode(debugLabel: "Editor Focus Node");
    // Initialize validator with callback
    validator = JsonDocumentValidator(
      onValidationResult: (hasError, errMsg, line, column, expected) {
        setState(() {
          this.hasError = hasError;
          this.errorMessage = errMsg;
          this.errorLine = line;
          this.errorColumn = column;
          this.expected = expected;
          
          if (hasError && line != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToErrorLine();
            });
          }
        });
      }
    );
        
    // Set initial value if provided
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      controller.text = widget.initialValue!;
      validator.validate(widget.initialValue!);
    }
  }
  
  @override
  void didUpdateWidget(JsonTextFieldEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && 
        widget.initialValue != controller.text) {
      controller.text = widget.initialValue ?? '';
      validator.validate(controller.text);
    }
  }

  @override
  void dispose() {
    validator.dispose();
    controller.dispose();
    editorFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Editor section
        Expanded(
          child: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.tab): () {
                if (!widget.readOnly) {
                  insertTab();
                }
              },
            },
            child: JsonTextField(
              // Core configuration
              errorContainerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(
                      kForegroundOpacity,
                    ),
                borderRadius: kBorderRadius8,
              ),
              key: Key(widget.fieldKey),
              controller: controller,
              focusNode: editorFocusNode,
              keyboardType: TextInputType.multiline,
              expands: true,
              maxLines: null,
              style: kCodeStyle.copyWith(
                fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
              ),
              readOnly: widget.readOnly,
              autofocus: widget.autofocus,
              textAlignVertical: TextAlignVertical.top,
              onChanged: (value) {
                validator.validate(value);
                widget.onChanged?.call(value);
              },
              
              // Improved decoration with theme-aware colors
              decoration: InputDecoration(
                hintText: widget.hintText ,
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: kBorderRadius8,
                  borderSide: BorderSide(
                    color: hasError 
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary.withOpacity(
                            kHintOpacity,
                          ),
                    width: hasError ? 1.5 : 1.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: kBorderRadius8,
                  borderSide: BorderSide(
                    color: hasError
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                    width: hasError ? 1.5 : 1.0,
                  ),
                ),
                filled: true,
                hoverColor: kColorTransparent,
                fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
              ),
            ),
          ),
        ),
        
        // Error display widget
        if (hasError)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: JsonErrorWidget(
            errorMessage: errorMessage,
            errorLine: errorLine,
            errorLineText: errorLine != null && 
                errorLine! <= controller.text.split('\n').length 
                ? controller.text.split('\n')[errorLine! - 1] 
                : null,
            errorColumn: errorColumn,
            expected: expected,
          ),
        ),
      ],
    );
  }
}