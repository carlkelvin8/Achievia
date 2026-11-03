import 'package:achievia/core/di/injection.dart';
import 'package:achievia/core/utils/auth_error_utils.dart';
import 'package:achievia/domain/entities/api/auth/signup_result.dart';
import 'package:achievia/domain/entities/api/auth/user_entity.dart';
import 'package:achievia/domain/use_cases/auth/user_use_case.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final toggleProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

class LoginNotifier extends Notifier<LoginFormState> {
  late TextEditingController emailControllerLogin;
  late TextEditingController passwordController;
  late TextEditingController firstNameController;
  late TextEditingController middleNameController;
  late TextEditingController lastNameController;
  late TextEditingController schoolController;
  late TextEditingController birthdayController;
  late TextEditingController addressController;
  late TextEditingController emailController;
  late TextEditingController passwordControllerSignup;
  late TextEditingController confirmPasswordControllerSignup;
  late TextEditingController userNameControllerSignup;

  late UserUseCase useCase;

  @override
  LoginFormState build() {
    useCase = ref.read(userUseCaseProvider);

    emailControllerLogin = TextEditingController();
    passwordController = TextEditingController();
    firstNameController = TextEditingController();
    middleNameController = TextEditingController();
    lastNameController = TextEditingController();
    schoolController = TextEditingController();
    birthdayController = TextEditingController();
    addressController = TextEditingController();
    emailController = TextEditingController();
    passwordControllerSignup = TextEditingController();
    confirmPasswordControllerSignup = TextEditingController();
    userNameControllerSignup = TextEditingController();

    ref.onDispose(() {
      emailControllerLogin.dispose();
      passwordController.dispose();
      firstNameController.dispose();
      middleNameController.dispose();
      lastNameController.dispose();
      schoolController.dispose();
      birthdayController.dispose();
      addressController.dispose();
      emailController.dispose();
      passwordControllerSignup.dispose();
      confirmPasswordControllerSignup.dispose();
      userNameControllerSignup.dispose();
    });

    return const LoginFormState(email: '', password: '', isToggled: false);
  }

  void toggleEye() {
    state = state.copyWith(isToggled: !state.isToggled);
  }

  Future<bool> submit() async {
    if (state.isLoading) return false;
    final entity = UserEntity(
      id: 0,
      firstName: '',
      middleName: '',
      lastName: '',
      bio: '',
      age: 0,
      username: emailControllerLogin.text,
      email: '',
      password: passwordController.text,
      role: '',
      status: '',
      profileImage: '',
    );

    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await useCase.getLogin(entity);
      // The form may have been torn down while the request was in flight.
      if (!ref.mounted) return true;
      emailControllerLogin.clear();
      passwordController.clear();
      state = state.copyWith(isLoading: false, errorMessage: null);
      return true;
    } on AuthException catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: userFacingAuthError(e),
      );
      return false;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: userFacingAuthError(e),
      );
      return false;
    }
  }

  /// The date picked in the Birthday field; null until one is chosen.
  DateTime? birthDate;

  /// Whole years completed on [today].
  static int ageOn(DateTime birth, DateTime today) {
    var years = today.year - birth.year;
    final hadBirthday =
        today.month > birth.month ||
        (today.month == birth.month && today.day >= birth.day);
    if (!hadBirthday) years--;
    return years < 0 ? 0 : years;
  }

  static String isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<SignupResult?> submitSignup() async {
    if (state.isLoading) return null;
    final birth = birthDate;
    final entity = UserEntity(
      firstName: firstNameController.text,
      middleName: middleNameController.text,
      lastName: lastNameController.text,
      bio: '',
      // Age is derived from the birthday, so it is saved with the profile.
      age: birth == null ? 0 : ageOn(birth, DateTime.now()),
      birthDate: birth == null ? null : isoDate(birth),
      username: userNameControllerSignup.text,
      email: emailController.text,
      password: passwordControllerSignup.text,
      role: 'USER',
      status: '',
      profileImage: '',
      university: schoolController.text,
      purpose: 'MTLE',
      fullAddress: addressController.text.trim(),
    );

    try {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        emailError: null,
      );
      final result = await useCase.getSignup(entity);
      if (!ref.mounted) return result;
      firstNameController.clear();
      middleNameController.clear();
      lastNameController.clear();
      schoolController.clear();
      birthdayController.clear();
      addressController.clear();
      birthDate = null;
      userNameControllerSignup.clear();
      emailController.clear();
      passwordControllerSignup.clear();
      confirmPasswordControllerSignup.clear();
      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
        emailError: null,
      );
      return result;
    } catch (e, st) {
      logAuthFailure('signup', e, st);
      if (!ref.mounted) return null;
      final message = userFacingAuthError(e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: message,
        emailError: isEmailFailure(e) ? message : null,
      );
      return null;
    }
  }
}

final loginFormProvider = NotifierProvider<LoginNotifier, LoginFormState>(
  LoginNotifier.new,
);
final userUseCaseProvider = Provider<UserUseCase>((ref) => sl<UserUseCase>());

class LoginFormState {
  static const Object _errorMessageUnset = Object();
  static const Object _emailErrorUnset = Object();

  final String email;
  final String password;
  final bool isLoading;
  final bool isToggled;
  final String? errorMessage;

  /// Only set when the failure is about the email itself (invalid or taken).
  final String? emailError;

  const LoginFormState({
    required this.email,
    required this.password,
    this.isLoading = false,
    this.isToggled = true,
    this.errorMessage,
    this.emailError,
  });

  LoginFormState copyWith({
    String? email,
    String? password,
    bool? isLoading,
    Object? errorMessage = _errorMessageUnset,
    Object? emailError = _emailErrorUnset,
    bool? isToggled,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _errorMessageUnset)
          ? this.errorMessage
          : errorMessage as String?,
      emailError: identical(emailError, _emailErrorUnset)
          ? this.emailError
          : emailError as String?,
      isToggled: isToggled ?? this.isToggled,
    );
  }
}
