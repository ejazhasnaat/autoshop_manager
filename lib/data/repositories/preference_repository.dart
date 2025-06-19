// lib/data/repositories/preference_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert'; // Added for json.decode

// Data class to hold user preferences
class UserPreferences {
  final String defaultCurrency;

  UserPreferences({this.defaultCurrency = 'PKR'}); // Default to PKR

  UserPreferences.fromJson(Map<String, dynamic> json)
    : defaultCurrency = json['defaultCurrency'] as String? ?? 'PKR';

  Map<String, dynamic> toJson() => {'defaultCurrency': defaultCurrency};
}

// Provider for PreferenceRepository
final preferenceRepositoryProvider = Provider<PreferenceRepository>((ref) {
  return PreferenceRepository();
});

class PreferenceRepository {
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;
  late final String _appId;

  PreferenceRepository() {
    try {
      // Access global variables provided by the Canvas environment.
      // These are injected as Dart string constants via fromEnvironment.
      _appId = const String.fromEnvironment('APP_ID', defaultValue: 'default-app-id');

      // The __firebase_config is expected to be a JSON string.
      final String firebaseConfigString = const String.fromEnvironment('FIREBASE_CONFIG', defaultValue: '{}');
      final Map<String, dynamic> firebaseConfig = firebaseConfigString.isEmpty
          ? {}
          : Map<String, dynamic>.from(
                json.decode(firebaseConfigString) as Map<dynamic, dynamic>, // Use json.decode
              );

      // Initialize Firebase only if it's not already initialized
      if (Firebase.apps.isEmpty) {
        Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: firebaseConfig['apiKey'] as String? ?? '',
            appId: firebaseConfig['appId'] as String? ?? '',
            messagingSenderId: firebaseConfig['messagingSenderId'] as String? ?? '',
            projectId: firebaseConfig['projectId'] as String? ?? '',
            authDomain: firebaseConfig['authDomain'] as String?,
            databaseURL: firebaseConfig['databaseURL'] as String?,
            storageBucket: firebaseConfig['storageBucket'] as String?,
            measurementId: firebaseConfig['measurementId'] as String?,
          ),
        );
      }
    } catch (e) {
      print('Error initializing Firebase or retrieving global vars: $e');
      _appId = 'default-app-id'; // Fallback in case of any parsing/access error
    }

    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;

    _signInAnonymouslyIfNeeded(); // Ensure auth state
  }

  Future<void> _signInAnonymouslyIfNeeded() async {
    if (_auth.currentUser == null) {
      try {
        final String initialAuthToken = const String.fromEnvironment('INITIAL_AUTH_TOKEN', defaultValue: '');

        if (initialAuthToken.isNotEmpty) {
          await _auth.signInWithCustomToken(initialAuthToken);
        } else {
          await _auth.signInAnonymously();
        }
        print('Firebase authenticated as: ${_auth.currentUser?.uid}');
      } catch (e) {
        print('Error during Firebase anonymous sign-in: $e');
      }
    }
  }

  // Helper to get the user-specific document reference
  DocumentReference _getUserPreferencesDocRef() {
    final userId = _auth.currentUser?.uid ?? 'anonymous_user';
    return _firestore
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(userId)
        .collection('preferences')
        .doc('userPreferences');
  }

  /// Fetches user preferences as a stream for real-time updates.
  Stream<UserPreferences> getUserPreferencesStream() {
    _signInAnonymouslyIfNeeded();

    return _getUserPreferencesDocRef()
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            // Cast snapshot.data() to Map<String, dynamic> for fromJson constructor
            return UserPreferences.fromJson(
              snapshot.data()! as Map<String, dynamic>,
            );
          }
          return UserPreferences();
        })
        .handleError((e) {
          print('Error fetching user preferences: $e');
          return UserPreferences();
        });
  }

  /// Updates the default currency for the user.
  Future<bool> updateDefaultCurrency(String currencySymbol) async {
    try {
      await _signInAnonymouslyIfNeeded();
      await _getUserPreferencesDocRef().set({
        'defaultCurrency': currencySymbol,
      }, SetOptions(merge: true));
      print('Default currency updated to: $currencySymbol');
      return true;
    } catch (e) {
      print('Error updating default currency: $e');
      return false;
    }
  }
}

