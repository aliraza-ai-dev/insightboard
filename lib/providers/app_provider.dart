import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/all_models.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/ai_service.dart';
import '../services/workspace_service.dart';

class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DataService _dataService = DataService();
  final AIService _aiService = AIService();
  final WorkspaceService _workspaceService = WorkspaceService();

  // Auth state
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Workspace state
  Workspace? _currentWorkspace;
  Workspace? get currentWorkspace => _currentWorkspace;
  List<Workspace> _workspaces = [];
  List<Workspace> get workspaces => _workspaces;

  // Dataset state
  DatasetModel? _activeDataset;
  DatasetModel? get activeDataset => _activeDataset;
  List<Map<String, dynamic>> _activeDataRows = [];
  List<Map<String, dynamic>> get activeDataRows => _activeDataRows;
  ParsedData? _parsedData;
  ParsedData? get parsedData => _parsedData;

  // Theme
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Services access
  DataService get dataService => _dataService;
  AIService get aiService => _aiService;
  WorkspaceService get workspaceService => _workspaceService;
  AuthService get authService => _authService;

  // ==========================================
  // Auth
  // ==========================================
  Future<void> initAuth() async {
    final user = _authService.currentUser;
    if (user != null) {
      _currentUser = await _authService.getUserData(user.uid);
      if (_currentUser != null && _currentUser!.workspaceIds.isNotEmpty) {
        await loadWorkspaces();
        if (_workspaces.isNotEmpty) {
          _currentWorkspace = _workspaces.first;
        }
      }
      notifyListeners();
    }
  }

  Future<String?> signUp(String email, String password, String name) async {
    try {
      _isLoading = true;
      notifyListeners();
      _currentUser = await _authService.signUp(email, password, name);
      if (_currentUser != null) {
        await loadWorkspaces();
        if (_workspaces.isNotEmpty) _currentWorkspace = _workspaces.first;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      _currentUser = await _authService.signIn(email, password);
      if (_currentUser != null) {
        await loadWorkspaces();
        if (_workspaces.isNotEmpty) _currentWorkspace = _workspaces.first;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    _currentWorkspace = null;
    _workspaces = [];
    _activeDataset = null;
    _activeDataRows = [];
    notifyListeners();
  }

  // ==========================================
  // Workspaces
  // ==========================================
  Future<void> loadWorkspaces() async {
    if (_currentUser == null) return;
    _workspaceService.getUserWorkspaces(_currentUser!.uid).listen((list) {
      _workspaces = list;
      if (_currentWorkspace != null) {
        final updated = list.where((w) => w.id == _currentWorkspace!.id).toList();
        if (updated.isNotEmpty) _currentWorkspace = updated.first;
      }
      notifyListeners();
    });
  }

  void switchWorkspace(Workspace ws) {
    _currentWorkspace = ws;
    _activeDataset = null;
    _activeDataRows = [];
    notifyListeners();
  }

  Future<void> createWorkspace(String name, {String? description, String? emoji}) async {
    if (_currentUser == null) return;
    final ws = await _workspaceService.createWorkspace(
        name, _currentUser!.uid, description: description, emoji: emoji);
    _currentWorkspace = ws;
    notifyListeners();
  }

  // ==========================================
  // Data Upload & Management
  // ==========================================

  // Local parse — works without login/Firebase
  Future<DatasetModel?> parseFileLocally(Uint8List bytes, String fileName) async {
    try {
      _isLoading = true;
      notifyListeners();

      ParsedData parsed;
      if (fileName.toLowerCase().endsWith('.csv')) {
        parsed = await _dataService.parseCSV(bytes, fileName);
      } else {
        parsed = await _dataService.parseExcel(bytes, fileName);
      }
      _parsedData = parsed;

      // Create in-memory dataset (no Firebase)
      final dataset = DatasetModel(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        name: fileName,
        workspaceId: _currentWorkspace?.id ?? 'local',
        uploadedBy: _currentUser?.uid ?? 'local',
        uploadedAt: DateTime.now(),
        rowCount: parsed.rows.length,
        colCount: parsed.headers.length,
        columns: parsed.headers,
        columnTypes: parsed.columnTypes,
        sourceType: fileName.toLowerCase().endsWith('.csv') ? 'csv' : 'excel',
      );

      _activeDataset = dataset;
      // Convert rows to Map format for in-memory use
      _activeDataRows = parsed.rows.map((row) {
        final map = <String, dynamic>{};
        for (int j = 0; j < parsed.headers.length && j < row.length; j++) {
          map[parsed.headers[j]] = row[j];
        }
        return map;
      }).toList();

      return dataset;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<DatasetModel?> uploadFile(Uint8List bytes, String fileName) async {
    // Always parse locally first
    return parseFileLocally(bytes, fileName);
  }

  Future<void> loadDataset(DatasetModel dataset) async {
    _isLoading = true;
    notifyListeners();
    _activeDataset = dataset;
    _activeDataRows = await _dataService.getDatasetRows(dataset.id);
    _isLoading = false;
    notifyListeners();
  }

  void loadSampleData(String type) {
    if (type == 'sales') {
      _parsedData = _dataService.generateSampleSalesData();
    } else {
      _parsedData = _dataService.generateSampleWebAnalytics();
    }
    notifyListeners();
  }

  void clearData() {
    _activeDataset = null;
    _activeDataRows = [];
    _parsedData = null;
    notifyListeners();
  }

  // ==========================================
  // AI Analysis
  // ==========================================
  Future<String> askAI(String question) async {
    if (_activeDataset == null || _activeDataRows.isEmpty) {
      return 'Please upload or select a dataset first.';
    }
    final summary = _parsedData?.getSummary() ?? {};
    return _aiService.analyzeData(
      question: question,
      columns: _activeDataset!.columns,
      columnTypes: _activeDataset!.columnTypes,
      sampleRows: _activeDataRows.take(30).toList(),
      summary: summary,
    );
  }

  // ==========================================
  // Theme
  // ==========================================
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
