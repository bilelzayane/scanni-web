import 'package:supabase_flutter/supabase_flutter.dart';
void main() async {
  final count = await Supabase.instance.client.from('history').select().count(CountOption.exact);
  int x = count;
}
