// import 'package:durub_ali/aiAgent/aiAgentSidePanal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../shared/appProvider.dart';
import '../../services/billing/api_service.dart';
import '../../services/billing/user_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _imageUrlController = TextEditingController();

  // Billing System Controllers
  final _taxNumberController = TextEditingController(text: "178043940");
  final _apiUsernameController = TextEditingController(text: "BX");
  final _apiPasswordController = TextEditingController(text: "123456789Aa@");
  final _activityController = TextEditingController(text: "13462377");
  bool _isBillingLoading = false;
  bool _isBillingConnected = false;

  bool _isLoading = false;
  bool _showPassword = false;
  String? error;
  User? currentUser;
  bool _isUpdatingProfile = false;
  bool _shouldReauthenticate = false;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    _displayNameController.text = currentUser?.displayName ?? '';
    _imageUrlController.text = currentUser?.photoURL ?? '';
    _imageUrlController.text = currentUser?.photoURL ?? '';
    _checkLastSignInTime();
    _checkBillingConnection();
  }

  Future<void> _checkBillingConnection() async {
    final hasCreds = await UserPreferences.hasCredentials();
    final token = await UserPreferences.getToken();
    if (mounted) {
      setState(() {
        _isBillingConnected = hasCreds || token != null;
        if (hasCreds) {
          UserPreferences.getTaxNumber()
              .then((val) => _taxNumberController.text = val ?? '');
          UserPreferences.getUsername()
              .then((val) => _apiUsernameController.text = val ?? '');
        }
      });
    }
  }

  Future<void> _loginToBilling() async {
    if (_taxNumberController.text.isEmpty ||
        _apiUsernameController.text.isEmpty ||
        _activityController.text.isEmpty ||
        _apiPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تعبئة جميع حقول نظام الفوترة')),
      );
      return;
    }

    setState(() => _isBillingLoading = true);
//
    try {
      await ApiService().loginUser({
        "taxNumber": _taxNumberController.text,
        "username": _apiUsernameController.text,
        "password": _apiPasswordController.text,
        // "activity": _activityController.text,
      });

      // Save credentials for auto-login
      await UserPreferences.saveUserCredentials(
        username: _apiUsernameController.text,
        password: _apiPasswordController.text,
        activity: _activityController.text,
        taxNumber: _taxNumberController.text,
      );

      if (mounted) {
        setState(() {
          _isBillingConnected = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم الاتصال بنظام الفوترة بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الاتصال بنظام الفوترة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBillingLoading = false);
    }
  }

  Future<void> _logoutBilling() async {
    await UserPreferences.clearCredentials();
    await UserPreferences.clearToken();
    setState(() {
      _isBillingConnected = false;
      _apiPasswordController.clear();
    });
  }

  void _checkLastSignInTime() {
    final lastSignInTime = currentUser?.metadata.lastSignInTime;
    if (lastSignInTime != null) {
      final difference = DateTime.now().difference(lastSignInTime);
      if (difference.inMinutes > 5) {
        setState(() {
          _shouldReauthenticate = true;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isUpdatingProfile = true);

    try {
      await currentUser?.updateProfile(
        displayName: _displayNameController.text,
        photoURL: _imageUrlController.text.isNotEmpty
            ? _imageUrlController.text
            : null,
      );

      // Refresh the user data
      await currentUser?.reload();
      setState(() {
        currentUser = FirebaseAuth.instance.currentUser;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('حدث خطأ أثناء تحديث الملف الشخصي: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      try {
        await currentUser!.updatePassword(_newPasswordController.text);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')),
          );
          Navigator.pop(context);
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = switch (e.code) {
          'requires-recent-login' => 'الرجاء تسجيل الخروج وإعادة تسجيل الدخول',
          'weak-password' => 'كلمة المرور الجديدة ضعيفة جداً',
          _ => 'حدث خطأ غير معروف'
        };

        if (mounted) {
          setState(() {
            error = errorMessage;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء تسجيل الخروج')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<AppProvider>(builder: (context, appProvider, child) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('إعدادات',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // User Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: theme.colorScheme.primary,
                                backgroundImage: currentUser?.photoURL != null
                                    ? AssetImage(
                                        "assets/images/" + $KcompanyLogo)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (currentUser?.displayName != null)
                                      Text(
                                        currentUser?.displayName ?? '',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    Text(
                                      currentUser?.email ?? '',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    Text(
                                      'آخر تسجيل دخول: ${currentUser?.metadata.lastSignInTime?.toString() ?? 'غير معروف'}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    if (currentUser?.email ==
                                        'admin@durubali.com')
                                      Container(
                                        margin: const EdgeInsets.only(top: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'مدير النظام',
                                          style: TextStyle(
                                            color: theme.colorScheme.onPrimary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _imageUrlController,
                            decoration: InputDecoration(
                              labelText: "الوظيفة",
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: theme.colorScheme.outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: theme.colorScheme.primary, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed:
                                  _isUpdatingProfile ? null : _updateProfile,
                              child: _isUpdatingProfile
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Text('تحديث الملف الشخصي',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      )),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Billing System Connection Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.receipt_long,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'الربط مع نظام الفوترة',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              if (_isBillingConnected)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: const Text(
                                    'متصل',
                                    style: TextStyle(
                                        color: Colors.green, fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                          if (!_isBillingConnected) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _taxNumberController,
                              decoration: InputDecoration(
                                labelText: 'الرقم الضريبي',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _apiUsernameController,
                              decoration: InputDecoration(
                                labelText: 'اسم المستخدم (الفوترة)',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _apiPasswordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'كلمة المرور (الفوترة)',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _activityController,
                              decoration: InputDecoration(
                                labelText: 'رقم النشاط (الفوترة)',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _isBillingLoading ? null : _loginToBilling,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                ),
                                child: _isBillingLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : const Text('تسجيل الدخول لنظام الفوترة'),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _logoutBilling,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.error,
                                  side: BorderSide(
                                      color: theme.colorScheme.error),
                                ),
                                child: const Text('فصل نظام الفوترة'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // System Settings Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.settings_suggest,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'إعدادات النظام',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('التعيين التلقائي (توصيل)',
                                style: TextStyle(fontSize: 14)),
                            subtitle: const Text(
                                'تعيين السائق تلقائياً للتوصيل بناءً على مناطق الجولات عند إضافة طلب جديد',
                                style: TextStyle(fontSize: 12)),
                            value: appProvider.autoAssignEnabled,
                            onChanged: (bool value) {
                              appProvider.updateAutoAssign(value);
                            },
                          ),
                          const Divider(),
                          SwitchListTile(
                            title: const Text('التعيين التلقائي (جلب)',
                                style: TextStyle(fontSize: 14)),
                            subtitle: const Text(
                                'تعيين السائق تلقائياً للجلب (بانتظار التحميل) بناءً على مناطق الجولات عند إضافة طلب جديد',
                                style: TextStyle(fontSize: 12)),
                            value: appProvider.autoCollectionEnabled,
                            onChanged: (bool value) {
                              appProvider.updateAutoCollection(value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text('تغيير كلمة المرور',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (_shouldReauthenticate)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: theme.colorScheme.error),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'يرجى تسجيل الخروج وإعادة تسجيل الدخول للمتابعة',
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildPasswordField(
                      _newPasswordController, 'كلمة المرور الجديدة'),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                      _confirmPasswordController, 'تأكيد كلمة المرور',
                      isConfirm: true),
                  const SizedBox(height: 24),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: theme.colorScheme.onError,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _logout,
                          icon: const Icon(Icons.logout, size: 20),
                          label: const Text('تسجيل الخروج'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _isLoading ? null : _changePassword,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text('حفظ التغييرات',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPasswordField(TextEditingController controller, String label,
      {bool isConfirm = false}) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      obscureText: !_showPassword,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _showPassword ? Icons.visibility_off : Icons.visibility,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'هذا الحقل مطلوب';
        }
        if (value.length < 6) {
          return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
        }
        if (isConfirm && value != _newPasswordController.text) {
          return 'كلمات المرور غير متطابقة';
        }
        return null;
      },
    );
  }

  Widget _buildUsageStatRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _imageUrlController.dispose();
    _taxNumberController.dispose();
    _apiUsernameController.dispose();
    _apiPasswordController.dispose();
    super.dispose();
  }
}
