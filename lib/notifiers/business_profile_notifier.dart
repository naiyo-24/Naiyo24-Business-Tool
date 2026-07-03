import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/business_profile_model.dart';
import '../providers/shared_prefs_provider.dart';

part 'business_profile_notifier.g.dart';

const _kBusinessProfileKey = 'business_profile_data';

@riverpod
class BusinessProfileNotifier extends _$BusinessProfileNotifier {
  @override
  BusinessProfileModel build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final raw = prefs.getString(_kBusinessProfileKey);
    if (raw == null) return const BusinessProfileModel();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return BusinessProfileModel.fromJson(json);
    } catch (_) {
      return const BusinessProfileModel();
    }
  }

  void saveProfile(BusinessProfileModel profile) {
    state = profile;
    final prefs = ref.read(sharedPrefsProvider);
    prefs.setString(_kBusinessProfileKey, jsonEncode(profile.toJson()));
  }
}
