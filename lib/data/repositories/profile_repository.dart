import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/pathology.dart';
import '../../domain/models/user_watchlist.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

class ProfileRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user ID
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  /// Fetch user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile(UserProfile profile) async {
    try {
      await _supabase
          .from('user_profiles')
          .update({
            'full_name': profile.fullName,
            'language_pref': profile.languagePref,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', profile.userId);
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  /// Update user language preference
  Future<bool> updateUserLanguage(String userId, String languageCode) async {
    try {
      await _supabase
          .from('user_profiles')
          .update({
            'language_pref': languageCode,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
      return true;
    } catch (e) {
      print('Error updating user language: $e');
      return false;
    }
  }

  /// Get scan count from history table
  Future<int> getScanCount(String userId) async {
    try {
      final response = await _supabase
          .from('history')
          .select('id')
          .eq('user_id', userId);
      return response.length;
    } catch (e) {
      print('Error fetching scan count: $e');
      return 0;
    }
  }

  /// Fetch all pathologies
  Future<List<Pathology>> getPathologies() async {
    try {
      final response = await _supabase.from('pathologies').select('*');

      return response.map((json) => Pathology.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching pathologies: $e');
      return [];
    }
  }

  /// Fetch user's selected pathologies
  Future<Set<String>> getUserPathologies(String userId) async {
    try {
      final response = await _supabase
          .from('user_pathologies')
          .select('pathology_id')
          .eq('user_id', userId);

      return (response as List<dynamic>)
          .map((json) => json['pathology_id'] as String)
          .toSet();
    } catch (e) {
      print('Error fetching user pathologies: $e');
      return {};
    }
  }

  /// Toggle pathology for user (add or remove from user_pathologies table)
  Future<bool> togglePathology(String userId, String pathologyId) async {
    try {
      // Check if already selected
      final existing = await _supabase
          .from('user_pathologies')
          .select('id')
          .eq('user_id', userId)
          .eq('pathology_id', pathologyId);

      if (existing.isNotEmpty) {
        // Remove
        await _supabase
            .from('user_pathologies')
            .delete()
            .eq('user_id', userId)
            .eq('pathology_id', pathologyId);
      } else {
        // Add
        await _supabase.from('user_pathologies').insert({
          'user_id': userId,
          'pathology_id': pathologyId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      return true;
    } catch (e) {
      print('Error toggling pathology: $e');
      return false;
    }
  }

  /// Fetch user watchlist (ingredients)
  Future<List<UserWatchlist>> getUserWatchlist(String userId) async {
    try {
      final response = await _supabase
          .from('user_watchlist')
          .select('*')
          .eq('user_id', userId);

      return (response as List<dynamic>)
          .map((json) => UserWatchlist.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching user watchlist: $e');
      return [];
    }
  }

  /// Add pathology to user watchlist (via lexicon_pathologies)
  Future<bool> addToWatchlist(String userId, String pathologyId) async {
    try {
      // First, find ingredients associated with this pathology
      final response = await _supabase
          .from('lexicon_pathologies')
          .select('ingredient_id')
          .eq('pathology_id', pathologyId);

      if (response.isEmpty) return false;

      // Add all associated ingredients to watchlist
      for (var item in response) {
        final ingredientId = item['ingredient_id'] as String;
        await _supabase.from('user_watchlist').insert({
          'user_id': userId,
          'ingredient_id': ingredientId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return true;
    } catch (e) {
      print('Error adding to watchlist: $e');
      return false;
    }
  }

  /// Remove pathology from user watchlist
  Future<bool> removeFromWatchlist(String userId, String pathologyId) async {
    try {
      // Find ingredients associated with this pathology
      final response = await _supabase
          .from('lexicon_pathologies')
          .select('ingredient_id')
          .eq('pathology_id', pathologyId);

      if (response.isEmpty) return false;

      // Remove all associated ingredients from watchlist
      for (var item in response) {
        final ingredientId = item['ingredient_id'] as String;
        await _supabase
            .from('user_watchlist')
            .delete()
            .eq('user_id', userId)
            .eq('ingredient_id', ingredientId);
      }

      return true;
    } catch (e) {
      print('Error removing from watchlist: $e');
      return false;
    }
  }

  /// Check if a pathology is in user's watchlist
  Future<bool> isPathologyInWatchlist(String userId, String pathologyId) async {
    try {
      final response = await _supabase
          .from('lexicon_pathologies')
          .select('ingredient_id')
          .eq('pathology_id', pathologyId);

      if (response.isEmpty) return false;

      for (var item in response) {
        final ingredientId = item['ingredient_id'] as String;
        final watchlistCheck = await _supabase
            .from('user_watchlist')
            .select('id')
            .eq('user_id', userId)
            .eq('ingredient_id', ingredientId);

        if (watchlistCheck.isNotEmpty) return true;
      }

      return false;
    } catch (e) {
      print('Error checking watchlist: $e');
      return false;
    }
  }
}
