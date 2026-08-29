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
  late final TextEditingController emailControllerLogin;
  late final TextEditingController passwordController;
  late final TextEditingController firstNameController;
  late final TextEditingController middleNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController schoolController;
  late final TextEditingController emailController;
  late final TextEditingController passwordControllerSignup;
  late final TextEditingController confirmPasswordControllerSignup;
  late final TextEditingController userNameControllerSignup;

  late final UserUseCase useCase;

  @override
  LoginFormState build() {
    useCase = ref.read(userUseCaseProvider);

    emailControllerLogin = TextEditingController();
    passwordController = TextEditingController();
    firstNameController = TextEditingController();
    middleNameController = TextEditingController();
    lastNameController = TextEditingController();
    schoolController = TextEditingController();
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
      emailControllerLogin.clear();
      passwordController.clear();
      state = state.copyWith(isLoading: false, errorMessage: null);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<SignupResult?> submitSignup() async {
    final entity = UserEntity(
      firstName: firstNameController.text,
      middleName: middleNameController.text,
      lastName: lastNameController.text,
      bio: '',
      age: 0,
      username: userNameControllerSignup.text,
      email: emailController.text,
      password: passwordControllerSignup.text,
      role: 'USER',
      status: '',
      profileImage: '',
      university: schoolController.text,
    );

    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final result = await useCase.getSignup(entity);
      firstNameController.clear();
      middleNameController.clear();
      lastNameController.clear();
      schoolController.clear();
      userNameControllerSignup.clear();
      emailController.clear();
      passwordControllerSignup.clear();
      confirmPasswordControllerSignup.clear();
      state = state.copyWith(isLoading: false, errorMessage: null);
      return result;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: userFacingAuthError(e),
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: userFacingAuthError(e),
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

  final String email;
  final String password;
  final bool isLoading;
  final bool isToggled;
  final String? errorMessage;

  const LoginFormState({
    required this.email,
    required this.password,
    this.isLoading = false,
    this.isToggled = true,
    this.errorMessage,
  });

  LoginFormState copyWith({
    String? email,
    String? password,
    bool? isLoading,
    Object? errorMessage = _errorMessageUnset,
    bool? isToggled,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _errorMessageUnset)
          ? this.errorMessage
          : errorMessage as String?,
      isToggled: isToggled ?? this.isToggled,
    );
  }
}
