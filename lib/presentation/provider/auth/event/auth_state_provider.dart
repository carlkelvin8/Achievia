import 'package:achievia/core/di/injection.dart';
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
  late final TextEditingController usernameController;
  late final TextEditingController passwordController;
  late final GlobalKey<FormState> key;

  late final UserUseCase useCase;

  @override
  LoginFormState build() {
    useCase = ref.read(userUseCaseProvider);

    usernameController = TextEditingController();
    key = GlobalKey<FormState>();
    passwordController = TextEditingController();

    ref.onDispose(() {
      usernameController.dispose();
      passwordController.dispose();
    });

    return const LoginFormState(email: '', password: '');
  }

  String? validate(String controller, String value) {
    if (value.isEmpty) {
      return '$controller is required';
    }
    return null;
  }

  Future<void> submit() async {
    final entity = UserEntity(
      id: 0,
      firstName: '',
      middleName: '',
      lastName: '',
      bio: '',
      age: 0,
      username: usernameController.text,
      email: '',
      password: passwordController.text,
      role: '',
      status: '',
      profileImage: '',
    );

    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await useCase.getLogin(entity);
      usernameController.clear();
      passwordController.clear();
      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final loginFormProvider = NotifierProvider<LoginNotifier, LoginFormState>(
  LoginNotifier.new,
);
final userUseCaseProvider = Provider<UserUseCase>((ref) => sl<UserUseCase>());

class LoginFormState {
  final String email;
  final String password;
  final bool isLoading;
  final String? errorMessage;

  const LoginFormState({
    required this.email,
    required this.password,
    this.isLoading = false,
    this.errorMessage,
  });

  LoginFormState copyWith({
    String? email,
    String? password,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
