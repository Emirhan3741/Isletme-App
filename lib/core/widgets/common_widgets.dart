import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

// Ortak Kart Widget'ı
class CommonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const CommonCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(AppConstants.paddingSmall),
      child: Material(
        color: color ?? AppConstants.surfaceColor,
        elevation: elevation ?? 2,
        borderRadius:
            borderRadius ?? BorderRadius.circular(AppConstants.radiusMedium),
        child: InkWell(
          onTap: onTap,
          borderRadius:
              borderRadius ?? BorderRadius.circular(AppConstants.radiusMedium),
          child: Padding(
            padding:
                padding ?? const EdgeInsets.all(AppConstants.paddingMedium),
            child: child,
          ),
        ),
      ),
    );
  }
}

// Ortak Input Widget'ı (Basit versiyon)
class CommonInput extends StatelessWidget {
  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Function(String)? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;

  const CommonInput({
    super.key,
    this.hintText,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: const BorderSide(color: AppConstants.errorColor),
        ),
        filled: true,
        fillColor: AppConstants.surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: AppConstants.paddingMedium,
        ),
      ),
    );
  }
}

// Ortak Input Field Widget'ı
class CommonTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const CommonTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.onTap,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          onTap: onTap,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              borderSide: const BorderSide(color: AppConstants.errorColor),
            ),
            filled: true,
            fillColor: enabled
                ? AppConstants.surfaceColor
                : AppConstants.backgroundColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
              vertical: AppConstants.paddingMedium,
            ),
          ),
        ),
      ],
    );
  }
}

// Ortak Buton Widget'ı
class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final Widget? icon;
  final bool isLoading;
  final ButtonType type;

  const CommonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.icon,
    this.isLoading = false,
    this.type = ButtonType.primary,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color txtColor;

    switch (type) {
      case ButtonType.primary:
        bgColor = backgroundColor ?? AppConstants.primaryColor;
        txtColor = textColor ?? Colors.white;
        break;
      case ButtonType.secondary:
        bgColor = backgroundColor ?? AppConstants.surfaceColor;
        txtColor = textColor ?? AppConstants.primaryColor;
        break;
      case ButtonType.success:
        bgColor = backgroundColor ?? AppConstants.successColor;
        txtColor = textColor ?? Colors.white;
        break;
      case ButtonType.error:
        bgColor = backgroundColor ?? AppConstants.errorColor;
        txtColor = textColor ?? Colors.white;
        break;
      case ButtonType.warning:
        bgColor = backgroundColor ?? AppConstants.warningColor;
        txtColor = textColor ?? Colors.white;
        break;
    }

    return SizedBox(
      width: width,
      height: height ?? 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: txtColor,
          elevation: type == ButtonType.secondary ? 1 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            side: type == ButtonType.secondary
                ? const BorderSide(color: AppConstants.primaryColor)
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(txtColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: AppConstants.paddingSmall),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

enum ButtonType { primary, secondary, success, error, warning }

// Ortak Loading Widget'ı
class CommonLoading extends StatelessWidget {
  final String? message;
  final double size;

  const CommonLoading({
    super.key,
    this.message,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppConstants.primaryColor),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              message!,
              style: const TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Ortak Empty State Widget'ı
class CommonEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onAction;

  const CommonEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: AppConstants.textLight,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppConstants.textLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppConstants.paddingLarge),
              CommonButton(
                text: actionText!,
                onPressed: onAction,
                type: ButtonType.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Ortak Error Widget'ı
class CommonError extends StatelessWidget {
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const CommonError({
    super.key,
    required this.message,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppConstants.errorColor,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            const Text(
              'Bir hata oluştu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppConstants.paddingLarge),
              CommonButton(
                text: actionText!,
                onPressed: onAction,
                type: ButtonType.error,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Ortak Dropdown Widget'ı (Eski versiyon - sadece backward compatibility için)
class CommonDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final String? hint;

  const CommonDropdown({
    super.key,
    required this.label,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
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
            fillColor: AppConstants.surfaceColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
              vertical: AppConstants.paddingMedium,
            ),
          ),
        ),
      ],
    );
  }
}

// Gelişmiş Dropdown Widget'ı - Custom Option Desteği ile
class CommonDropdownWithCustom<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<T> options;
  final String Function(T) optionLabel;
  final String Function(T) optionValue;
  final Function(T?)? onChanged;
  final Function(String?)? onCustomValueChanged;
  final String? customValue;
  final String? Function(T?)? validator;
  final String? Function(String?)? customValidator;
  final String? hint;
  final IconData? icon;
  final String customOptionLabel;
  final String customInputLabel;
  final String customInputHint;
  final bool enabled;
  final bool isRequired;

  const CommonDropdownWithCustom({
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
    this.isRequired = false,
  });

  @override
  State<CommonDropdownWithCustom<T>> createState() =>
      _CommonDropdownWithCustomState<T>();
}

class _CommonDropdownWithCustomState<T>
    extends State<CommonDropdownWithCustom<T>> {
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
  void didUpdateWidget(CommonDropdownWithCustom<T> oldWidget) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.paddingSmall),

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
            hintText: widget.hint,
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
}

// Ortak Dashboard Card Widget'ı
class CommonDashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;
  final String? trend;
  final bool showTrend;

  const CommonDashboardCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
    this.isLoading = false,
    this.trend,
    this.showTrend = false,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusSmall),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      if (showTrend && trend != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: trend!.startsWith('+')
                                ? AppConstants.successColor
                                    .withValues(alpha: 0.1)
                                : AppConstants.errorColor
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            trend!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: trend!.startsWith('+')
                                  ? AppConstants.successColor
                                  : AppConstants.errorColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppConstants.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppConstants.textLight,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

// Ortak Quick Action Button
class CommonQuickAction extends StatelessWidget {
  final String label;
  final String? title; // Backward compatibility için
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final bool isOutlined;

  const CommonQuickAction({
    super.key,
    this.label = '',
    this.title, // title parametresi eklendi
    required this.icon,
    required this.onTap,
    this.color,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final actionColor = color ?? AppConstants.primaryColor;

    return CommonCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: isOutlined
            ? BoxDecoration(
                border: Border.all(color: actionColor.withValues(alpha: 0.3)),
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusMedium),
              )
            : BoxDecoration(
                color: actionColor.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusMedium),
              ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Overflow'u önlemek için
          children: [
            Flexible(
              // Icon'u flexible yap
              child: Icon(
                icon,
                color: actionColor,
                size: 24, // Boyutu küçült
              ),
            ),
            const SizedBox(height: 4), // Spacing'i küçült
            Flexible(
              // Text'i flexible yap
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10, // Font boyutunu küçült
                  fontWeight: FontWeight.w600,
                  color: actionColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2, // Maksimum 2 satır
                overflow: TextOverflow.ellipsis, // Taşarsa ... göster
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Ortak Activity Item
class CommonActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? time;
  final Color color;
  final VoidCallback? onTap;
  final Widget? trailing;

  const CommonActivityItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.time,
    required this.color,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: AppConstants.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppConstants.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: trailing ??
          (time != null
              ? Text(
                  time!,
                  style: const TextStyle(
                    color: AppConstants.textLight,
                    fontSize: 11,
                  ),
                )
              : null),
    );
  }
}

// Ortak Stats Grid
class CommonStatsGrid extends StatelessWidget {
  final List<CommonDashboardCard> cards;
  final int crossAxisCount;
  final double childAspectRatio;

  const CommonStatsGrid({
    super.key,
    required this.cards,
    this.crossAxisCount = 4,
    this.childAspectRatio = 1.2,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final responsiveCrossAxisCount = screenWidth > 1200
        ? crossAxisCount
        : screenWidth > 800
            ? (crossAxisCount / 2).ceil()
            : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: responsiveCrossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: AppConstants.paddingMedium,
        mainAxisSpacing: AppConstants.paddingMedium,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index],
    );
  }
}

// Ortak Quick Actions Grid
class CommonQuickActionsGrid extends StatelessWidget {
  final List<CommonQuickAction> actions;
  final int crossAxisCount;

  const CommonQuickActionsGrid({
    super.key,
    required this.actions,
    this.crossAxisCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final responsiveCrossAxisCount = screenWidth > 1200
        ? crossAxisCount
        : screenWidth > 800
            ? (crossAxisCount / 2).ceil()
            : 3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: responsiveCrossAxisCount,
        childAspectRatio: 1.0,
        crossAxisSpacing: AppConstants.paddingMedium,
        mainAxisSpacing: AppConstants.paddingMedium,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) => actions[index],
    );
  }
}

// Ortak Page Header
class CommonPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;

  const CommonPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
            ),
          if (leading != null) leading!,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

// Ortak Section Header
class CommonSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final IconData? icon;

  const CommonSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: AppConstants.primaryColor,
              size: 20,
            ),
            const SizedBox(width: AppConstants.paddingSmall),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Ortak sayfa şablonu
class CommonPageTemplate extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color? primaryColor; // Panel rengi için
  final VoidCallback? onAddPressed;
  final String? addButtonText;

  const CommonPageTemplate({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.primaryColor, // Opsiyonel panel rengi
    this.onAddPressed,
    this.addButtonText,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = primaryColor ?? color;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: effectiveColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 64,
                color: effectiveColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (onAddPressed != null)
              ElevatedButton.icon(
                onPressed: onAddPressed,
                icon: const Icon(Icons.add),
                label: Text(addButtonText ?? 'Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: effectiveColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Yakında eklenecek dialog'u göster
  static void showComingSoonDialog(
    BuildContext context, {
    String title = 'Yakında Eklenecek',
    String message = 'Bu özellik yakında eklenecek.',
    IconData icon = Icons.construction,
    Color color = Colors.orange,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Tamam'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
