import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/assembler_user.dart';
import '../models/eol_brand.dart';
import '../models/eol_session.dart';

enum AuthStatus {
  unauthenticated,
  authenticating,
  authenticated,
  needsProfileSetup,
}

class EolAuthService with ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  EolSession? _currentSession;
  bool _isLoading = false;
  String? _errorMessage;
  bool _needsProfileSetup = false;
  User? _pendingFirebaseUser;

  EolSession? get currentSession => _currentSession;
  bool get isLoggedIn => _currentSession != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get needsProfileSetup => _needsProfileSetup;
  User? get pendingFirebaseUser => _pendingFirebaseUser;

  Future<void> loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final stationId = prefs.getString('eol_station_id') ?? 'Station-1';
    final rssi = prefs.getInt('eol_rssi_threshold') ?? -40;

    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      try {
        final doc = await _firestore.collection('assemblers').doc(currentUser.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final brandId = (data['brandId'] as String?) ?? 'cypro';
          final brand = EolBrand.getById(brandId);
          final assembler = AssemblerUser(
            uid: currentUser.uid,
            assemblerId: (data['assemblerId'] as String?) ?? 'ASM-${currentUser.uid.substring(0, 5)}',
            fullName: (data['fullName'] as String?) ?? currentUser.displayName ?? 'Assembler',
            email: currentUser.email ?? (data['email'] as String? ?? ''),
            brandId: brandId,
            brandName: (data['brandName'] as String?) ?? brand.name,
            role: (data['role'] as String?) ?? 'line_assembler',
          );

          _currentSession = EolSession(
            stationId: stationId,
            rssiThresholdDbm: rssi,
            assembler: assembler,
            brand: brand,
          );
          _needsProfileSetup = false;
          notifyListeners();
          return;
        } else {
          // Firebase user exists, but has not completed brand/assembler setup
          _pendingFirebaseUser = currentUser;
          _needsProfileSetup = true;
          notifyListeners();
          return;
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching assembler profile from Firestore: $e. Checking offline cache...');
      }
    }

    // Offline cache fallback
    final brandId = prefs.getString('eol_brand_id');
    final assemblerId = prefs.getString('eol_assembler_id');
    if (brandId != null && assemblerId != null) {
      final brand = EolBrand.getById(brandId);
      final assembler = AssemblerUser(
        uid: prefs.getString('eol_uid') ?? (currentUser?.uid ?? ''),
        assemblerId: assemblerId,
        fullName: prefs.getString('eol_assembler_name') ?? 'Assembler',
        email: prefs.getString('eol_assembler_email') ?? '',
        brandId: brandId,
        brandName: brand.name,
      );

      _currentSession = EolSession(
        stationId: stationId,
        rssiThresholdDbm: rssi,
        assembler: assembler,
        brand: brand,
      );
      notifyListeners();
    }
  }

  /// Sign in using production Firebase Authentication
  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
    String stationId = 'Station-1',
    int rssiThreshold = -40,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _needsProfileSetup = false;
    _pendingFirebaseUser = null;
    notifyListeners();

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('User authentication returned empty session.');
      }

      // Fetch operator profile from Firestore
      final doc = await _firestore.collection('assemblers').doc(user.uid).get();
      if (!doc.exists || doc.data() == null) {
        // User is signed in to Firebase, but needs to map brand and assembler ID
        _pendingFirebaseUser = user;
        _needsProfileSetup = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      final data = doc.data()!;
      final brandId = (data['brandId'] as String?) ?? 'cypro';
      final brand = EolBrand.getById(brandId);
      final assembler = AssemblerUser(
        uid: user.uid,
        assemblerId: (data['assemblerId'] as String?) ?? 'ASM-${user.uid.substring(0, 5)}',
        fullName: (data['fullName'] as String?) ?? user.displayName ?? 'Assembler',
        email: user.email ?? email,
        brandId: brandId,
        brandName: (data['brandName'] as String?) ?? brand.name,
        role: (data['role'] as String?) ?? 'line_assembler',
      );

      await _persistSessionPrefs(
        brandId: brand.id,
        assemblerId: assembler.assemblerId,
        assemblerName: assembler.fullName,
        assemblerEmail: assembler.email,
        uid: user.uid,
        stationId: stationId,
        rssiThreshold: rssiThreshold,
      );

      _currentSession = EolSession(
        stationId: stationId,
        rssiThresholdDbm: rssiThreshold,
        assembler: assembler,
        brand: brand,
      );

      // Record last login in Firestore
      _firestore.collection('assemblers').doc(user.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      }).catchError((_) {});

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Authentication failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register a new production assembler account in Firebase Auth and Firestore
  Future<bool> registerAssembler({
    required String email,
    required String password,
    required String fullName,
    required String assemblerId,
    required EolBrand brand,
    String stationId = 'Station-1',
    int rssiThreshold = -40,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Account creation failed.');
      }

      // Update user display name in Firebase Auth
      await user.updateDisplayName(fullName.trim());

      final resolvedAssemblerId = assemblerId.trim().isNotEmpty
          ? assemblerId.trim()
          : 'ASM-${brand.id.toUpperCase()}-${user.uid.substring(0, 4).toUpperCase()}';

      final assembler = AssemblerUser(
        uid: user.uid,
        assemblerId: resolvedAssemblerId,
        fullName: fullName.trim(),
        email: email.trim(),
        brandId: brand.id,
        brandName: brand.name,
        role: 'line_assembler',
      );

      final assemblerPayload = {
        'uid': user.uid,
        'email': email.trim().toLowerCase(),
        'fullName': fullName.trim(),
        'assemblerId': resolvedAssemblerId,
        'brandId': brand.id,
        'brandName': brand.name,
        'role': 'line_assembler',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      };

      // 1. Write to global assemblers registry in Firestore
      await _firestore.collection('assemblers').doc(user.uid).set(
        assemblerPayload,
        SetOptions(merge: true),
      );

      // 2. Write to brand-isolated assemblers subcollection in Firestore
      await _firestore
          .collection('brands')
          .doc(brand.id)
          .collection('assemblers')
          .doc(user.uid)
          .set(assemblerPayload, SetOptions(merge: true));

      await _persistSessionPrefs(
        brandId: brand.id,
        assemblerId: assembler.assemblerId,
        assemblerName: assembler.fullName,
        assemblerEmail: assembler.email,
        uid: user.uid,
        stationId: stationId,
        rssiThreshold: rssiThreshold,
      );

      _currentSession = EolSession(
        stationId: stationId,
        rssiThresholdDbm: rssiThreshold,
        assembler: assembler,
        brand: brand,
      );

      _needsProfileSetup = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Account registration error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Complete factory profile for a user signed in via Firebase without an assembler doc
  Future<bool> completeProfile({
    required String fullName,
    required String assemblerId,
    required EolBrand brand,
    String stationId = 'Station-1',
    int rssiThreshold = -40,
  }) async {
    final user = _pendingFirebaseUser ?? _firebaseAuth.currentUser;
    if (user == null) {
      _errorMessage = 'No active session found. Please sign in again.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resolvedAssemblerId = assemblerId.trim().isNotEmpty
          ? assemblerId.trim()
          : 'ASM-${brand.id.toUpperCase()}-${user.uid.substring(0, 4).toUpperCase()}';

      final assembler = AssemblerUser(
        uid: user.uid,
        assemblerId: resolvedAssemblerId,
        fullName: fullName.trim(),
        email: user.email ?? '',
        brandId: brand.id,
        brandName: brand.name,
        role: 'line_assembler',
      );

      final assemblerPayload = {
        'uid': user.uid,
        'email': (user.email ?? '').toLowerCase(),
        'fullName': fullName.trim(),
        'assemblerId': resolvedAssemblerId,
        'brandId': brand.id,
        'brandName': brand.name,
        'role': 'line_assembler',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('assemblers').doc(user.uid).set(
        assemblerPayload,
        SetOptions(merge: true),
      );

      await _firestore
          .collection('brands')
          .doc(brand.id)
          .collection('assemblers')
          .doc(user.uid)
          .set(assemblerPayload, SetOptions(merge: true));

      await _persistSessionPrefs(
        brandId: brand.id,
        assemblerId: assembler.assemblerId,
        assemblerName: assembler.fullName,
        assemblerEmail: assembler.email,
        uid: user.uid,
        stationId: stationId,
        rssiThreshold: rssiThreshold,
      );

      _currentSession = EolSession(
        stationId: stationId,
        rssiThresholdDbm: rssiThreshold,
        assembler: assembler,
        brand: brand,
      );

      _needsProfileSetup = false;
      _pendingFirebaseUser = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Profile setup failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateStationSetup({
    required String stationId,
    required int rssiThresholdDbm,
  }) async {
    if (_currentSession == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('eol_station_id', stationId);
    await prefs.setInt('eol_rssi_threshold', rssiThresholdDbm);

    _currentSession = _currentSession!.copyWith(
      stationId: stationId,
      rssiThresholdDbm: rssiThresholdDbm,
    );
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('eol_brand_id');
    await prefs.remove('eol_assembler_id');
    await prefs.remove('eol_assembler_name');
    await prefs.remove('eol_assembler_email');
    await prefs.remove('eol_uid');

    _currentSession = null;
    _needsProfileSetup = false;
    _pendingFirebaseUser = null;
    notifyListeners();
  }

  Future<void> _persistSessionPrefs({
    required String brandId,
    required String assemblerId,
    required String assemblerName,
    required String assemblerEmail,
    required String uid,
    required String stationId,
    required int rssiThreshold,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('eol_brand_id', brandId);
    await prefs.setString('eol_assembler_id', assemblerId);
    await prefs.setString('eol_assembler_name', assemblerName);
    await prefs.setString('eol_assembler_email', assemblerEmail);
    await prefs.setString('eol_uid', uid);
    await prefs.setString('eol_station_id', stationId);
    await prefs.setInt('eol_rssi_threshold', rssiThreshold);
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account exists for this email. Tap "Create New Account" below to register.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please verify and try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Please sign in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'Network connection failed. Please check your factory Wi-Fi / connectivity.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return e.message ?? 'Authentication error (${e.code})';
    }
  }
}
