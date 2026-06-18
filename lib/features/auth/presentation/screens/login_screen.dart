import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../providers/login_view_model.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginViewModelProvider);

    ref.listen(loginViewModelProvider, (previous, next) {
      if (next.failure != null && next.failure != previous?.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.failure!.message)),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: switch (state.step) {
              LoginStep.selectMethod => const _MethodSelectView(key: ValueKey('select')),
              LoginStep.enterPhone => const _PhoneEntryView(key: ValueKey('phone')),
              LoginStep.enterOtp => const _OtpEntryView(key: ValueKey('otp')),
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;

  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Icon(Icons.health_and_safety_rounded, color: AppColors.primary, size: 32),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: AppTextStyles.headlineLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: AppTextStyles.bodyMedium),
      ],
    );
  }
}

class _MethodSelectView extends ConsumerWidget {
  const _MethodSelectView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginViewModelProvider);
    final vm = ref.read(loginViewModelProvider.notifier);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Header(
          title: 'Welcome back',
          subtitle: 'Sign in to manage your medications, reminders, and health documents.',
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppPrimaryButton(
          label: 'Continue with Google',
          icon: Icons.g_mobiledata_rounded,
          isLoading: state.isLoading,
          onPressed: vm.signInWithGoogle,
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: state.isLoading ? null : vm.startPhoneEntry,
          icon: const Icon(Icons.phone_iphone_rounded, size: 20),
          label: const SizedBox(
            width: double.infinity,
            child: Text('Continue with phone number', textAlign: TextAlign.center),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: const [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text('or', style: AppTextStyles.bodySmall),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        TextButton(
          onPressed: state.isLoading ? null : vm.continueAsGuest,
          child: const Text('Continue as guest'),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'By continuing, you agree to keep your health data private and secure on this device.',
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PhoneEntryView extends ConsumerStatefulWidget {
  const _PhoneEntryView({super.key});

  @override
  ConsumerState<_PhoneEntryView> createState() => _PhoneEntryViewState();
}

class _PhoneEntryViewState extends ConsumerState<_PhoneEntryView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginViewModelProvider);
    final vm = ref.read(loginViewModelProvider.notifier);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IconButton(
          onPressed: vm.backToMethodSelect,
          icon: const Icon(Icons.arrow_back_rounded),
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
        ),
        const SizedBox(height: AppSpacing.sm),
        const _Header(
          title: 'Enter your phone number',
          subtitle: "We'll send you a one-time code to verify it's you.",
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.phone,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '+1 555 123 4567',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppPrimaryButton(
          label: 'Send code',
          isLoading: state.isLoading,
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              vm.submitPhoneNumber(_controller.text.trim());
            }
          },
        ),
      ],
    );
  }
}

class _OtpEntryView extends ConsumerStatefulWidget {
  const _OtpEntryView({super.key});

  @override
  ConsumerState<_OtpEntryView> createState() => _OtpEntryViewState();
}

class _OtpEntryViewState extends ConsumerState<_OtpEntryView> {
  String _code = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginViewModelProvider);
    final vm = ref.read(loginViewModelProvider.notifier);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IconButton(
          onPressed: vm.backToMethodSelect,
          icon: const Icon(Icons.arrow_back_rounded),
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
        ),
        const SizedBox(height: AppSpacing.sm),
        _Header(
          title: 'Enter verification code',
          subtitle: 'Sent to ${state.phoneNumber}. (Demo code: 1234)',
        ),
        const SizedBox(height: AppSpacing.xl),
        PinCodeTextField(
          appContext: context,
          length: 4,
          onChanged: (v) => _code = v,
          onCompleted: (v) {
            _code = v;
            vm.verifyOtp(v);
          },
          keyboardType: TextInputType.number,
          animationType: AnimationType.fade,
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(AppRadius.md),
            fieldHeight: 56,
            fieldWidth: 56,
            activeColor: AppColors.primary,
            selectedColor: AppColors.primary,
            inactiveColor: AppColors.border,
            activeFillColor: AppColors.surface,
            selectedFillColor: AppColors.surface,
            inactiveFillColor: AppColors.surfaceMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppPrimaryButton(
          label: 'Verify and continue',
          isLoading: state.isLoading,
          onPressed: () {
            if (_code.length == 4) vm.verifyOtp(_code);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: TextButton(
            onPressed: state.isLoading ? null : vm.resendOtp,
            child: const Text("Didn't get a code? Resend"),
          ),
        ),
      ],
    );
  }
}
