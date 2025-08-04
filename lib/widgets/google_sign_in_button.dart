import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_provider_enhanced.dart';
import '../services/auth_service.dart';
import '../core/constants/app_constants.dart';

class GoogleSignInButton extends StatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onError;
  final String? buttonText;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    this.onSuccess,
    this.onError,
    this.buttonText,
    this.isLoading = false,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isLoading = false;

  /// 🎯 Enhanced Google Sign-In implementasyonu (AuthProviderEnhanced kullanarak)
  Future<void> _handleGoogleSignIn() async {
    if (_isLoading || widget.isLoading) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProviderEnhanced>();
      
      debugPrint('🚀 GoogleSignInButton: Google Sign-In başlatılıyor...');
      
      // AuthProviderEnhanced'daki signInWithGoogle methodunu kullan
      final success = await authProvider.signInWithGoogle();
      
      if (success) {
        debugPrint('✅ GoogleSignInButton: Google Sign-In başarılı');
        _showSuccessSnackBar('Google ile giriş başarılı! Hoş geldiniz ${authProvider.user?.name ?? ""}');
        
        // Başarılı giriş callback'i çağır
        widget.onSuccess?.call();
      } else {
        debugPrint('❌ GoogleSignInButton: Google Sign-In başarısız');
        final errorMessage = authProvider.error ?? 'Google ile giriş başarısız';
        _showErrorSnackBar(errorMessage);
        widget.onError?.call();
      }
    } catch (e) {
      debugPrint('❌ GoogleSignInButton: Exception: $e');
      _showErrorSnackBar('Google ile giriş yaparken hata oluştu: $e');
      widget.onError?.call();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppConstants.errorColor,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
  
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isLoading || widget.isLoading;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : _handleGoogleSignIn,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.grey[600]!,
                  ),
                ),
              )
            : Image.asset(
                'assets/images/google_logo.png',
                width: 20,
                height: 20,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.login,
                    size: 20,
                    color: Colors.grey[600],
                  );
                },
              ),
        label: Text(
          isLoading
              ? 'Giriş yapılıyor...'
              : (widget.buttonText ?? 'Google ile Giriş Yap'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey[700],
          elevation: 2,
          shadowColor: Colors.grey.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            side: BorderSide(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Özelleştirilmiş Google Sign-In butonu (küçük boyut)
class GoogleSignInButtonSmall extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButtonSmall({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 40,
      child: GoogleSignInButton(
        onSuccess: onPressed,
        buttonText: 'Google ile Giriş',
        isLoading: isLoading,
      ),
    );
  }
}

/// Icon-only Google Sign-In butonu
class GoogleSignInIconButton extends StatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onError;
  final double size;

  const GoogleSignInIconButton({
    super.key,
    this.onSuccess,
    this.onError,
    this.size = 50,
  });

  @override
  State<GoogleSignInIconButton> createState() => _GoogleSignInIconButtonState();
}

class _GoogleSignInIconButtonState extends State<GoogleSignInIconButton> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential != null) {
        widget.onSuccess?.call();
      } else {
        widget.onError?.call();
      }
    } catch (e) {
      widget.onError?.call();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _isLoading ? null : _handleGoogleSignIn,
      borderRadius: BorderRadius.circular(widget.size / 2),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(widget.size / 2),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: _isLoading
            ? Padding(
                padding: EdgeInsets.all(widget.size * 0.3),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.grey[600]!,
                  ),
                ),
              )
            : Padding(
                padding: EdgeInsets.all(widget.size * 0.2),
                child: Image.asset(
                  'assets/images/google_logo.png',
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.login,
                      size: widget.size * 0.6,
                      color: Colors.grey[600],
                    );
                  },
                ),
              ),
      ),
    );
  }
}