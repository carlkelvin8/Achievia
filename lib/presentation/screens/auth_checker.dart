import 'package:achievia/presentation/provider/auth/event/token_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthChecker extends ConsumerWidget {
  final Widget authenticated;
  final Widget unauthenticated;
  const AuthChecker({
    super.key,
    required this.authenticated,
    required this.unauthenticated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchRef = ref.watch(tokenStream);
    return watchRef.when(data: (token){
      return token != null ? authenticated : unauthenticated;
    }, 
    loading: () => CircularProgressIndicator(),
    error: (_, __) => unauthenticated,
    );
  }
}
