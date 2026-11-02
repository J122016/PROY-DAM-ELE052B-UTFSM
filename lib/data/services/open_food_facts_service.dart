import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpDate;

import 'package:http/http.dart' as http;
import 'package:proyecto_dam/data/models/product.dart';

class OpenFoodFactsException implements Exception {
  const OpenFoodFactsException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OpenFoodFactsService {
  OpenFoodFactsService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const _fields =
      'code,product_name,generic_name,image_front_url,nutriments,brands,categories';
  static const _headers = {
    'Accept': 'application/json',
    'User-Agent': 'NutriMarket/0.1 (nutrimarket@usm.cl)',
  };

  DateTime? _blockedUntil;
  final List<DateTime> _searchRequests = [];

  Future<List<Product>> fetchOrganicProducts() async {
    _recordSearchRequest();
    final uri = Uri.https('world.openfoodfacts.org', '/api/v2/search', {
      'categories_tags': 'organic',
      'fields': _fields,
      'page_size': '20',
    });
    return _requestProducts(uri);
  }

  Future<List<Product>> searchProducts(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return const [];
    _recordSearchRequest();
    final uri = Uri.https('world.openfoodfacts.org', '/cgi/search.pl', {
      'search_terms': cleanQuery,
      'search_simple': '1',
      'action': 'process',
      'json': '1',
      'page_size': '20',
      'fields': _fields,
    });
    return _requestProducts(uri);
  }

  void _recordSearchRequest() {
    _checkCooldown();
    final now = DateTime.now();
    _searchRequests.removeWhere(
      (requestAt) => now.difference(requestAt) >= const Duration(minutes: 1),
    );
    if (_searchRequests.length >= 10) {
      throw const OpenFoodFactsException(
        'Límite local de búsqueda alcanzado. Espera un minuto antes de consultar nuevamente.',
      );
    }
    _searchRequests.add(now);
  }

  Future<List<Product>> _requestProducts(Uri uri) async {
    _checkCooldown();
    late final http.Response response;
    try {
      response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw OpenFoodFactsException(
        'La solicitud a Open Food Facts tardó demasiado.',
      );
    } on Exception {
      throw const OpenFoodFactsException(
        'No se pudo conectar con Open Food Facts.',
      );
    }

    if (response.statusCode == 429 || response.statusCode == 503) {
      final retryAfter = _retryAfter(response.headers['retry-after']);
      _blockedUntil = DateTime.now().add(retryAfter);
      final seconds = retryAfter.inSeconds;
      throw OpenFoodFactsException(
        response.statusCode == 503
            ? 'Open Food Facts está temporalmente limitado (HTTP 503). '
                  'Las solicitudes se pausaron durante $seconds segundos; no se reintentará automáticamente.'
            : 'Open Food Facts limitó las solicitudes (HTTP 429). '
                  'Las solicitudes se pausaron durante $seconds segundos.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OpenFoodFactsException(
        'Open Food Facts respondió con HTTP ${response.statusCode}.',
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['products'] is! List) {
        throw const FormatException();
      }
      final products = (decoded['products'] as List)
          .whereType<Map<String, dynamic>>()
          .map(Product.fromOpenFoodFacts)
          .whereType<Product>()
          .take(20)
          .toList(growable: false);
      return products;
    } on FormatException {
      throw const OpenFoodFactsException(
        'Open Food Facts devolvió una respuesta que no se pudo leer.',
      );
    }
  }

  void _checkCooldown() {
    final blockedUntil = _blockedUntil;
    if (blockedUntil == null) return;
    final remaining = blockedUntil.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _blockedUntil = null;
      return;
    }
    throw OpenFoodFactsException(
      'Open Food Facts está en pausa. Intenta nuevamente en ${remaining.inSeconds + 1} segundos.',
    );
  }

  Duration _retryAfter(String? value) {
    if (value == null) return const Duration(minutes: 1);
    final seconds = int.tryParse(value);
    if (seconds != null) return Duration(seconds: seconds.clamp(1, 86400));
    late final DateTime date;
    try {
      date = HttpDate.parse(value).toUtc();
    } on FormatException {
      return const Duration(minutes: 1);
    }
    final delay = date.difference(DateTime.now().toUtc());
    return delay <= Duration.zero
        ? const Duration(minutes: 1)
        : delay > const Duration(days: 1)
        ? const Duration(days: 1)
        : delay;
  }

  void close() => _client.close();
}
