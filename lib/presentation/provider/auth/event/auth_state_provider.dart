import 'package:achievia/core/di/injection.dart';
import 'package:achievia/domain/entities/api/auth/user_entity.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/domain/use_cases/auth/user_use_case.dart';

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
    useCase = ref.read(userUseCaseProvider);

    usernameController = TextEditingController();
    passwordController = TextEditingController();

    ref.onDispose(() {
      usernameController.dispose();
      passwordController.dispose();
    });

    return const LoginFormState(email: '', password: '');
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

    await useCase.getLogin(entity);
    usernameController.clear();
    passwordController.clear();
    
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
