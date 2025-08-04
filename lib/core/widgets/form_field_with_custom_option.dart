import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Özelleştirilmiş giriş seçeneği olan form alanı widget'ı
/// Dropdown, FilterChip, Choice widget'ları için "Diğer/Özel" seçeneği ekler
class FormFieldWithCustomOption<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<T> options;
  final String Function(T) optionLabel;
  final String Function(T) optionValue;
  final ValueChanged<T?>? onChanged;
  final ValueChanged<String?>? onCustomValueChanged;
  final String? customValue;
  final String? Function(T?)? validator;
  final String? Function(String?)? customValidator;
  final String? hint;
  final IconData? icon;
  final String customOptionLabel;
  final String customInputLabel;
  final String customInputHint;
  final bool enabled;
  final FormFieldType fieldType;
  final bool isRequired;

  const FormFieldWithCustomOption({
    super.key,
    required this.label,
    this.value,
    required this.options,
    required this.optionLabel,
    required this.optionValue,
    this.onChanged,
    this.onCustomValueChanged,
    this.customValue,
    this.validator,
    this.customValidator,
    this.hint,
    this.icon,
    this.customOptionLabel = 'Diğer',
    this.customInputLabel = 'Özel Değer',
    this.customInputHint = 'Lütfen açıklayın...',
    this.enabled = true,
    this.fieldType = FormFieldType.dropdown,
    this.isRequired = false,
  });

  @override
  State<FormFieldWithCustomOption<T>> createState() =>
      _FormFieldWithCustomOptionState<T>();
}

enum FormFieldType {
  dropdown,
  chips,
  radio,
}

class _FormFieldWithCustomOptionState<T>
    extends State<FormFieldWithCustomOption<T>> {
  late TextEditingController _customController;
  bool _isCustomSelected = false;
  T? _customOptionValue;

  @override
  void initState() {
    super.initState();
    _customController = TextEditingController(text: widget.customValue);

    // Custom option value oluştur (String tipinde "custom" değeri)
    if (T == String) {
      _customOptionValue = 'custom' as T;
    }

    // Eğer value custom option ise, custom mode'a geç
    if (widget.value != null &&
        !widget.options.contains(widget.value) &&
        widget.customValue != null) {
      _isCustomSelected = true;
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FormFieldWithCustomOption<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Custom value değişti mi kontrol et
    if (widget.customValue != oldWidget.customValue) {
      _customController.text = widget.customValue ?? '';
    }

    // Value değişti mi ve custom option mı kontrol et
    if (widget.value != oldWidget.value) {
      _isCustomSelected = widget.value != null &&
          !widget.options.contains(widget.value) &&
          widget.customValue != null;
    }
  }

  void _onOptionChanged(T? newValue) {
    if (newValue == _customOptionValue) {
      // Custom option seçildi
      setState(() {
        _isCustomSelected = true;
      });
      widget.onChanged?.call(newValue);
    } else {
      // Normal option seçildi
      setState(() {
        _isCustomSelected = false;
      });
      widget.onChanged?.call(newValue);

      // Custom value'yu temizle
      if (widget.onCustomValueChanged != null) {
        _customController.clear();
        widget.onCustomValueChanged!('');
      }
    }
  }

  void _onCustomValueChanged(String value) {
    widget.onCustomValueChanged?.call(value);
  }

  List<T> get _enhancedOptions {
    final options = List<T>.from(widget.options);
    if (_customOptionValue != null && !options.contains(_customOptionValue)) {
      options.add(_customOptionValue!);
    }
    return options;
  }

  String _getOptionLabel(T option) {
    if (option == _customOptionValue) {
      return widget.customOptionLabel;
    }
    return widget.optionLabel(option);
  }

  String? _validateField(T? value) {
    // Eğer custom seçildi ise, custom validator kullan
    if (_isCustomSelected) {
      return widget.customValidator?.call(_customController.text);
    }

    // Normal validation
    if (widget.isRequired && value == null) {
      return '${widget.label} seçimi gerekli';
    }

    return widget.validator?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.fieldType) {
      case FormFieldType.dropdown:
        return _buildDropdownField();
      case FormFieldType.chips:
        return _buildChipsField();
      case FormFieldType.radio:
        return _buildRadioField();
    }
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown Field
        DropdownButtonFormField<T>(
          value: _isCustomSelected ? _customOptionValue : widget.value,
          items: _enhancedOptions.map((option) {
            return DropdownMenuItem<T>(
              value: option,
              child: Row(
                children: [
                  if (widget.icon != null && option == _enhancedOptions.first)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(widget.icon,
                          size: 16, color: AppConstants.textSecondary),
                    ),
                  Expanded(child: Text(_getOptionLabel(option))),
                ],
              ),
            );
          }).toList(),
          onChanged: widget.enabled ? _onOptionChanged : null,
          validator: _validateField,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: widget.icon != null
                ? Icon(widget.icon, color: AppConstants.primaryColor)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              borderSide: const BorderSide(color: AppConstants.textLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              borderSide: const BorderSide(color: AppConstants.textLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              borderSide:
                  const BorderSide(color: AppConstants.primaryColor, width: 2),
            ),
            filled: true,
            fillColor: widget.enabled
                ? AppConstants.surfaceColor
                : AppConstants.textLight.withValues(alpha: 0.1),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
              vertical: AppConstants.paddingMedium,
            ),
          ),
        ),

        // Custom Input Field (göster/gizle)
        if (_isCustomSelected) ...[
          const SizedBox(height: AppConstants.paddingSmall),
          TextFormField(
            controller: _customController,
            onChanged: _onCustomValueChanged,
            enabled: widget.enabled,
            validator: widget.customValidator,
            decoration: InputDecoration(
              labelText: widget.customInputLabel,
              hintText: widget.customInputHint,
              prefixIcon:
                  const Icon(Icons.edit, color: AppConstants.primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                borderSide: const BorderSide(color: AppConstants.textLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                borderSide: const BorderSide(color: AppConstants.textLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                borderSide: const BorderSide(
                    color: AppConstants.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: widget.enabled
                  ? AppConstants.surfaceColor
                  : AppConstants.textLight.withValues(alpha: 0.1),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
                vertical: AppConstants.paddingMedium,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChipsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.paddingSmall),

        // Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _enhancedOptions.map((option) {
            final isSelected = _isCustomSelected
                ? option == _customOptionValue
                : option == widget.value;

            return FilterChip(
              label: Text(_getOptionLabel(option)),
              selected: isSelected,
              onSelected: widget.enabled
                  ? (selected) {
                      if (selected) {
                        _onOptionChanged(option);
                      }
                    }
                  : null,
              backgroundColor: AppConstants.surfaceColor,
              selectedColor: AppConstants.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: AppConstants.primaryColor,
            );
          }).toList(),
        ),

        // Custom Input Field
        if (_isCustomSelected) ...[
          const SizedBox(height: AppConstants.paddingSmall),
          TextFormField(
            controller: _customController,
            onChanged: _onCustomValueChanged,
            enabled: widget.enabled,
            validator: widget.customValidator,
            decoration: InputDecoration(
              labelText: widget.customInputLabel,
              hintText: widget.customInputHint,
              prefixIcon:
                  const Icon(Icons.edit, color: AppConstants.primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
              filled: true,
              fillColor: AppConstants.surfaceColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRadioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.paddingSmall),

        // Radio Options
        ..._enhancedOptions.map((option) {
          return RadioListTile<T>(
            title: Text(_getOptionLabel(option)),
            value: option,
            groupValue: _isCustomSelected ? _customOptionValue : widget.value,
            onChanged: widget.enabled ? _onOptionChanged : null,
            activeColor: AppConstants.primaryColor,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),

        // Custom Input Field
        if (_isCustomSelected) ...[
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: TextFormField(
              controller: _customController,
              onChanged: _onCustomValueChanged,
              enabled: widget.enabled,
              validator: widget.customValidator,
              decoration: InputDecoration(
                labelText: widget.customInputLabel,
                hintText: widget.customInputHint,
                prefixIcon:
                    const Icon(Icons.edit, color: AppConstants.primaryColor),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                ),
                filled: true,
                fillColor: AppConstants.surfaceColor,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Helper extension for easier usage
extension FormFieldWithCustomOptionHelper on Widget {
  /// Dropdown ile custom option ekler
  static Widget dropdown<T>({
    required String label,
    T? value,
    required List<T> options,
    required String Function(T) optionLabel,
    required String Function(T) optionValue,
    ValueChanged<T?>? onChanged,
    ValueChanged<String?>? onCustomValueChanged,
    String? customValue,
    String? Function(T?)? validator,
    String? Function(String?)? customValidator,
    String? hint,
    IconData? icon,
    String customOptionLabel = 'Diğer',
    String customInputLabel = 'Özel Değer',
    String customInputHint = 'Lütfen açıklayın...',
    bool enabled = true,
    bool isRequired = false,
  }) {
    return FormFieldWithCustomOption<T>(
      label: label,
      value: value,
      options: options,
      optionLabel: optionLabel,
      optionValue: optionValue,
      onChanged: onChanged,
      onCustomValueChanged: onCustomValueChanged,
      customValue: customValue,
      validator: validator,
      customValidator: customValidator,
      hint: hint,
      icon: icon,
      customOptionLabel: customOptionLabel,
      customInputLabel: customInputLabel,
      customInputHint: customInputHint,
      enabled: enabled,
      fieldType: FormFieldType.dropdown,
      isRequired: isRequired,
    );
  }

  /// Chips ile custom option ekler
  static Widget chips<T>({
    required String label,
    T? value,
    required List<T> options,
    required String Function(T) optionLabel,
    required String Function(T) optionValue,
    ValueChanged<T?>? onChanged,
    ValueChanged<String?>? onCustomValueChanged,
    String? customValue,
    String? Function(String?)? customValidator,
    String customOptionLabel = 'Diğer',
    String customInputLabel = 'Özel Değer',
    String customInputHint = 'Lütfen açıklayın...',
    bool enabled = true,
  }) {
    return FormFieldWithCustomOption<T>(
      label: label,
      value: value,
      options: options,
      optionLabel: optionLabel,
      optionValue: optionValue,
      onChanged: onChanged,
      onCustomValueChanged: onCustomValueChanged,
      customValue: customValue,
      customValidator: customValidator,
      customOptionLabel: customOptionLabel,
      customInputLabel: customInputLabel,
      customInputHint: customInputHint,
      enabled: enabled,
      fieldType: FormFieldType.chips,
    );
  }
}
