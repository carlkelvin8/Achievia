import 'package:achievia/core/di/injection.dart';
import 'package:achievia/domain/entities/api/auth/user_entity.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/domain/use_cases/auth/user_use_case.dart';
/// 🔹 Simple auth toggle provider
class AuthNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final toggleProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);


class LoginNotifier extends Notifier<LoginFormState> {
  late final TextEditingController usernameController;
  late final TextEditingController passwordController;

  late final UserUseCase useCase;

  @override
  LoginFormState build() {
    // Read useCase from ref
    useCase = ref.read(userUseCaseProvider);

    usernameController = TextEditingController();
    passwordController = TextEditingController();

    ref.onDispose(() {
      usernameController.dispose();
      passwordController.dispose();
    });

    return const LoginFormState(email: '', password: '');
  }

  void setUsername(String value) {
    state = state.copyWith(email: value);
  }

  void setPassword(String value) {
    state = state.copyWith(password: value);
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

    final user = await useCase.getLogin(entity);
    print('Logged in user: ${user.username}');
  }
}

final loginFormProvider = NotifierProvider<LoginNotifier, LoginFormState>(LoginNotifier.new);
final userUseCaseProvider = Provider<UserUseCase>((ref) => sl<UserUseCase>());


class LoginFormState {
  final String email;
  final String password;

  const LoginFormState({
    required this.email,
    required this.password,
  });

  LoginFormState copyWith({String? email, String? password}) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }
}
