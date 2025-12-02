import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final userProvider = Provider<User>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    throw Exception('User not found');
  }
  return user;
});
