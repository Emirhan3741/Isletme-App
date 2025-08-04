import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ListState {
  loading,
  loaded,
  error,
  empty,
  loadingMore,
}

abstract class BaseListController<T> extends ChangeNotifier {
  // State management
  ListState _state = ListState.loading;
  String? _errorMessage;
  final List<T> _items = [];

  // Pagination
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  final int _pageSize;

  // Search and filters
  String _searchQuery = '';
  Map<String, dynamic> _filters = {};

  BaseListController({int pageSize = 20}) : _pageSize = pageSize;

  // Getters
  ListState get state => _state;
  String? get errorMessage => _errorMessage;
  List<T> get items => _items;
  bool get hasMore => _hasMore;
  bool get isLoading => _state == ListState.loading;
  bool get isLoadingMore => _state == ListState.loadingMore;
  bool get isEmpty => _state == ListState.empty;
  bool get hasError => _state == ListState.error;
  String get searchQuery => _searchQuery;
  Map<String, dynamic> get filters => _filters;

  // Abstract methods to be implemented by subclasses
  Query<Map<String, dynamic>> buildQuery();
  T fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc);

  // Pagination methods
  Future<void> loadInitial() async {
    try {
      _setState(ListState.loading);
      _items.clear();
      _lastDocument = null;
      _hasMore = true;

      await _loadPage();
    } catch (e) {
      _setError('Veriler yüklenirken hata: $e');
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _state == ListState.loadingMore) return;

    try {
      _setState(ListState.loadingMore);
      await _loadPage();
    } catch (e) {
      _setError('Daha fazla veri yüklenirken hata: $e');
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }

  Future<void> _loadPage() async {
    Query<Map<String, dynamic>> query = buildQuery();

    // Apply search if exists
    if (_searchQuery.isNotEmpty) {
      query = applySearchFilter(query, _searchQuery);
    }

    // Apply filters
    query = applyFilters(query, _filters);

    // Apply pagination
    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    query = query.limit(_pageSize);

    final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();

    if (snapshot.docs.isEmpty) {
      _hasMore = false;
      if (_items.isEmpty) {
        _setState(ListState.empty);
      } else {
        _setState(ListState.loaded);
      }
      return;
    }

    final newItems = snapshot.docs.map((doc) => fromDocument(doc)).toList();
    _items.addAll(newItems);
    _lastDocument = snapshot.docs.last;
    _hasMore = snapshot.docs.length == _pageSize;

    _setState(ListState.loaded);
  }

  // Search and filter methods
  void updateSearch(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        loadInitial();
      });
    }
  }

  Timer? _debounceTimer;

  void updateFilters(Map<String, dynamic> newFilters) {
    _filters = newFilters;
    loadInitial();
  }

  void clearFilters() {
    _filters.clear();
    _searchQuery = '';
    loadInitial();
  }

  // State management helpers
  void _setState(ListState newState) {
    _state = newState;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String error) {
    _state = ListState.error;
    _errorMessage = error;
    notifyListeners();
  }

  // Abstract filter methods to be overridden by subclasses
  Query<Map<String, dynamic>> applySearchFilter(
    Query<Map<String, dynamic>> query,
    String searchQuery,
  ) {
    // Default implementation - subclasses should override
    return query;
  }

  Query<Map<String, dynamic>> applyFilters(
    Query<Map<String, dynamic>> query,
    Map<String, dynamic> filters,
  ) {
    // Default implementation - subclasses should override for specific filters
    return query;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
