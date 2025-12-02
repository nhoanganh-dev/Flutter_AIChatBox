import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRepository {
  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => Supabase.instance.client.auth;
  static RealtimeClient get realtime => Supabase.instance.client.realtime;
}
