import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart'; // Importar clase de colores

class CustomFormFields {
  // Constantes de estilo para evitar recreaciones innecesarias
  static const double _defaultBorderRadius = 12.0;
  static final Color _defaultFillColor = AppColors.withAlpha(
    AppColors.grisClaro,
    40,
  );
  static const Color _primaryColor = AppColors.primario;

  // Cacheo de bordes comunes para mejorar el rendimiento
  static final _defaultBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(_defaultBorderRadius),
  );

  static final _focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(_defaultBorderRadius),
    borderSide: const BorderSide(color: _primaryColor, width: 2),
  );

  /// Construye un campo de formulario estándar
  static Widget buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    IconData? icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLength,
    bool readOnly = false,
    bool enabled = true,
    String? hintText,
    void Function(String)? onChanged,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    VoidCallback? onTap, // Añadido el parámetro onTap que faltaba
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: _defaultBorder,
        focusedBorder: _focusedBorder,
        filled: true,
        fillColor: enabled ? _defaultFillColor : AppColors.grisClaro,
        counterText: '', // Ocultar contador si se especifica maxLength
        suffixIcon: suffixIcon,
        errorMaxLines: 2, // Mejora display de errores
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 12.0,
        ), // Padding consistente
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLength: maxLength,
      readOnly: readOnly,
      enabled: enabled,
      onChanged: onChanged,
      focusNode: focusNode,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      // Evitar bloqueos con textos largos
      maxLines: obscureText ? 1 : null,
      minLines: 1,
      onTap: onTap, // Usando el parámetro añadido
    );
  }

  /// Construye un botón de acción con indicador de carga
  static Widget buildActionButton({
    required String label,
    required VoidCallback? onPressed,
    required IconData icon,
    bool isLoading = false,
    Color backgroundColor = AppColors.primario,
  }) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed, // Deshabilita durante carga
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: AppColors.claro,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        // Corrección de uso de alpha
        disabledBackgroundColor: backgroundColor.withAlpha(
          (backgroundColor.a * 0.7).round(),
        ),
        disabledForegroundColor: AppColors.withAlpha(
          AppColors.claro,
          178,
        ), // 70% de opacidad
      ),
      icon:
          isLoading
              ? Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(right: 8.0),
                child: CircularProgressIndicator(
                  color: AppColors.claro,
                  strokeWidth: 2,
                ),
              )
              : Icon(icon),
      label: Text(
        isLoading ? "Procesando..." : label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Construye un campo numérico (entero o decimal)
  static Widget buildNumberField({
    required TextEditingController controller,
    required String labelText,
    String? Function(String?)? validator,
    bool decimal = false,
    String? prefixText,
    IconData? icon,
    double? min,
    double? max,
  }) {
    // Expresión regular mejorada para números decimales
    final RegExp decimalRegex = RegExp(r'^-?(\d*\.)?\d*$');

    // Validación adicional para mínimos y máximos
    String? combinedValidator(String? value) {
      if (validator != null) {
        final baseValidation = validator(value);
        if (baseValidation != null) {
          return baseValidation;
        }
      }

      if (value == null || value.isEmpty) return null;

      try {
        final numValue = decimal ? double.parse(value) : int.parse(value);
        if (min != null && numValue < min) {
          return 'El valor debe ser mayor o igual a $min';
        }
        if (max != null && numValue > max) {
          return 'El valor debe ser menor o igual a $max';
        }
      } catch (e) {
        return 'Ingrese un valor numérico válido';
      }

      return null;
    }

    return buildTextFormField(
      controller: controller,
      labelText: labelText,
      keyboardType:
          decimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number,
      validator: combinedValidator,
      icon: icon ?? Icons.attach_money,
      inputFormatters:
          decimal
              ? [FilteringTextInputFormatter.allow(decimalRegex)]
              : [FilteringTextInputFormatter.digitsOnly],
      suffixIcon:
          prefixText != null
              ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                child: Text(
                  prefixText,
                  style: const TextStyle(color: Colors.grey),
                ),
              )
              : null,
    );
  }

  /// Construye un área de texto multilínea
  static Widget buildTextArea({
    required TextEditingController controller,
    required String labelText,
    String? Function(String?)? validator,
    int? maxLength,
    IconData? icon,
    String? hintText,
    int minLines = 3,
    int maxLines = 5, // Limitar líneas para prevenir problemas de rendimiento
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: _defaultBorder,
        focusedBorder: _focusedBorder,
        filled: true,
        fillColor: _defaultFillColor,
        counterText:
            maxLength != null
                ? '${controller.text.length}/$maxLength'
                : '', // Mostrar contador opcional
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 12.0,
        ),
      ),
      validator: validator,
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: minLines,
      buildCounter:
          maxLength != null
              ? (
                BuildContext context, {
                required int currentLength,
                required bool isFocused,
                required int? maxLength,
              }) {
                return Text(
                  '$currentLength/$maxLength',
                  style: TextStyle(
                    color:
                        currentLength > maxLength!
                            ? AppColors.error
                            : AppColors.grisClaro,
                  ),
                );
              }
              : null,
    );
  }

  /// Construye un selector de fecha
  static Widget buildDateField({
    required TextEditingController controller,
    required String labelText,
    required BuildContext context,
    required Function(DateTime) onDateSelected,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String? Function(String?)? validator,
    bool enabled = true,
    String? format,
  }) {
    // Valores por defecto
    initialDate ??= DateTime.now();
    firstDate ??= DateTime(initialDate.year - 100);
    lastDate ??= DateTime(initialDate.year + 10);

    // Formato personalizado opcional o predeterminado (dd/mm/yyyy)
    String formatDate(DateTime date) {
      if (format != null) {
        return format
            .replaceAll('dd', date.day.toString().padLeft(2, '0'))
            .replaceAll('MM', date.month.toString().padLeft(2, '0'))
            .replaceAll('yyyy', date.year.toString())
            .replaceAll('yy', date.year.toString().substring(2));
      }
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    }

    return buildTextFormField(
      controller: controller,
      labelText: labelText,
      icon: Icons.calendar_today,
      readOnly: true,
      enabled: enabled,
      validator: validator,
      onTap:
          enabled
              ? () async {
                // Prevenir múltiples diálogos
                FocusScope.of(context).requestFocus(FocusNode());

                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: initialDate!,
                  firstDate: firstDate!,
                  lastDate: lastDate!,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: _primaryColor,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );

                if (picked != null) {
                  controller.text = formatDate(picked);
                  onDateSelected(picked);
                }
              }
              : null,
    );
  }

  /// Construye un selector desplegable (dropdown)
  static Widget buildDropdownField<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required String labelText,
    String? Function(T?)? validator,
    IconData? icon,
    String? hintText,
    bool isLoading = false,
  }) {
    if (isLoading) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: _defaultBorder,
          focusedBorder: _focusedBorder,
          filled: true,
          fillColor: _defaultFillColor,
        ),
        child: Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primario,
            ),
          ),
        ),
      );
    }

    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: _defaultBorder,
        focusedBorder: _focusedBorder,
        filled: true,
        fillColor: _defaultFillColor,
        errorMaxLines: 2,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 12.0,
        ),
      ),
      validator: validator,
      isExpanded: true, // Evita problemas con textos largos
      menuMaxHeight: 300, // Limitar altura del menú para prevenir problemas
      icon: const Icon(Icons.arrow_drop_down),
      iconSize: 24,
      dropdownColor: AppColors.claro,
    );
  }

  /// Construye un campo específico para contraseña con toggle de visibilidad
  static Widget buildPasswordField({
    required TextEditingController controller,
    required bool passwordVisible,
    required Function(bool) onToggleVisibility,
    String labelText = 'Contraseña',
    String? Function(String?)? validator,
    bool isEditing = false,
    TextInputAction? textInputAction,
  }) {
    return buildTextFormField(
      controller: controller,
      labelText: isEditing ? 'Nueva contraseña (opcional)' : labelText,
      icon: Icons.lock,
      obscureText: !passwordVisible,
      validator: validator,
      textInputAction: textInputAction,
      suffixIcon: IconButton(
        icon: Icon(
          passwordVisible ? Icons.visibility_off : Icons.visibility,
          color: AppColors.grisClaro,
        ),
        tooltip: passwordVisible ? 'Ocultar contraseña' : 'Mostrar contraseña',
        onPressed: () => onToggleVisibility(!passwordVisible),
      ),
    );
  }

  /// Construye un botón de acción secundario (outline)
  static Widget buildSecondaryButton({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    Color color = AppColors.primario,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.claro,
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 15),
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(right: 8.0),
              child: CircularProgressIndicator(color: color, strokeWidth: 2),
            )
          else if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(icon),
            ),
          Text(
            isLoading ? "Procesando..." : label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
