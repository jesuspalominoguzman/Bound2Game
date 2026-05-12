// =============================================================================
// api_service.dart — Bound2Game Flutter
//
// Capa de acceso a la API REST del backend Node.js.
// Detecta automáticamente si el emulador es Android (10.0.2.2)
// o iOS/físico (localhost).
//
// Rutas cubiertas:
//   Auth      POST /api/users/register
//             POST /api/users/login
//   Biblioteca GET    /api/users/:userId/library
//              POST   /api/users/:userId/library
//              PATCH  /api/users/:userId/library/:entryId
//              DELETE /api/users/:userId/library/:entryId
//              GET    /api/users/:userId/stats
//   Juegos    GET /api/games/search?title=...
//             GET /api/games/deals
//             GET /api/games/free
// =============================================================================

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';
import '../models/deal_model.dart';
import '../models/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELOS DE RESPUESTA DEL BACKEND
// ─────────────────────────────────────────────────────────────────────────────

/// Juego tal como lo devuelve el backend (GameCache de MongoDB + datos extra).
/// Contiene exactamente los campos que el backend serializa.
class ApiGame {
  final String  id;
  final String  title;
  final String? steamAppID;
  final String  imageUrl;
  final double? hltbMainStory;
  final double? hltbCompletionist;
  final String? retailPrice;
  final String? currentPrice;
  final String? cheapestStore;
  final String? lowestPriceEver;

  // Para entradas de la biblioteca del usuario
  final String? entryId;
  final String? status;          // Backlog | Playing | Completed | Abandoned
  final String? personalNote;
  final String? platform;
  final DateTime? addedAt;
  final double? rentability;
  final String? pcRequirements;
  final List<String> rawgPlatforms; // Plataformas detectadas por RAWG
  final int? userPlaytime;

  const ApiGame({
    required this.id,
    required this.title,
    this.steamAppID,
    this.imageUrl = '',
    this.hltbMainStory,
    this.hltbCompletionist,
    this.retailPrice,
    this.currentPrice,
    this.cheapestStore,
    this.lowestPriceEver,
    this.entryId,
    this.status,
    this.personalNote,
    this.platform,
    this.addedAt,
    this.rentability,
    this.pcRequirements,
    this.rawgPlatforms = const [],
    this.userPlaytime,
  });

  factory ApiGame.fromJson(Map<String, dynamic> json) {
    // Si viene de UserLibrary poblado, los datos pueden estar en gameDetails o gameId
    final gameData = json['gameId'] as Map<String, dynamic>? ?? json['game'] as Map<String, dynamic>? ?? json;
    final gameDetails = json['gameDetails'] as Map<String, dynamic>?;
    final hltb     = gameData['hltb'] as Map<String, dynamic>?;

    final steamId  = gameDetails?['id']?.toString() ?? gameData['steamAppID']?.toString();
    final title    = gameDetails?['name']?.toString() ?? gameData['title']?.toString() ?? 'Sin título';
    
    // Construir URL de portada
    String cover = gameDetails?['image']?.toString() ?? gameData['imageUrl']?.toString() ?? '';
    if (cover.isEmpty && steamId != null && steamId.isNotEmpty) {
      cover = 'https://cdn.akamai.steamstatic.com/steam/apps/$steamId/header.jpg';
    }

    return ApiGame(
      id:               json['_id']?.toString() ?? gameData['_id']?.toString() ?? '',
      title:            title,
      steamAppID:       steamId,
      imageUrl:         cover,
      hltbMainStory:    _toDouble(gameDetails?['mainTime'] ?? hltb?['mainStory']),
      hltbCompletionist:_toDouble(hltb?['completionist']),
      retailPrice:      gameData['retailPrice']?.toString(),
      currentPrice:     gameDetails?['price']?.toString() ?? gameData['currentPrice']?.toString(),
      cheapestStore:    gameData['cheapestStore']?.toString(),
      lowestPriceEver:  gameData['lowestPriceEver']?.toString(),
      rentability:      _toDouble(gameDetails?['rentability']),
      pcRequirements:   gameData['pcRequirements']?.toString() ?? gameData['requirements']?['minimum']?.toString(),
      // Campos de la entrada de biblioteca
      entryId:          (json['userId'] != null || json['gameId'] != null || json['status'] != null) 
                          ? json['_id']?.toString() 
                          : json['entryId']?.toString(),
      status:           json['status']?.toString(),
      personalNote:     json['personalNote']?.toString(),
      platform:         json['platform']?.toString(),
      addedAt:          json['addedAt'] != null
          ? DateTime.tryParse(json['addedAt'].toString())
          : null,
      userPlaytime:     json['playtime'] != null ? (json['playtime'] as num).toInt() : null,
      rawgPlatforms:    List<String>.from(gameData['rawgPlatforms'] ?? []),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// URL de portada con fallback a Unsplash genérico
  String get coverUrl {
    if (imageUrl.isNotEmpty) return imageUrl;
    return 'https://images.unsplash.com/photo-1614294148960-9aa740632a87?w=400&q=80';
  }
}

/// Estadísticas de la biblioteca del usuario
class LibraryStats {
  final int total;
  final int completed;
  final int playing;
  final int backlog;
  final int abandoned;
  final int estimatedHours;

  const LibraryStats({
    required this.total,
    required this.completed,
    required this.playing,
    required this.backlog,
    required this.abandoned,
    required this.estimatedHours,
  });

  factory LibraryStats.fromJson(Map<String, dynamic> j) => LibraryStats(
    total:          (j['total']          as num?)?.toInt() ?? 0,
    completed:      (j['completed']      as num?)?.toInt() ?? 0,
    playing:        (j['playing']        as num?)?.toInt() ?? 0,
    backlog:        (j['backlog']        as num?)?.toInt() ?? 0,
    abandoned:      (j['abandoned']      as num?)?.toInt() ?? 0,
    estimatedHours: (j['estimatedHours'] as num?)?.toInt() ?? 0,
  );

  static const LibraryStats empty = LibraryStats(
    total: 0, completed: 0, playing: 0,
    backlog: 0, abandoned: 0, estimatedHours: 0,
  );
}

/// Deal/oferta tal como la devuelve el backend normalizado
class ApiDeal {
  final String  gameId;
  final String  gameTitle;
  final String? gameCover;
  final String  store;           // Clave interna (steam, epic, etc.)
  final String  storeName;       // Nombre legible
  final double  originalPrice;
  final double  salePrice;
  final int     discountPercent;
  final bool    isFree;
  final String? dealUrl;
  final String? steamAppID;

  const ApiDeal({
    required this.gameId,
    required this.gameTitle,
    required this.store,
    required this.storeName,
    required this.originalPrice,
    required this.salePrice,
    required this.discountPercent,
    required this.isFree,
    this.gameCover,
    this.dealUrl,
    this.steamAppID,
  });

  factory ApiDeal.fromJson(Map<String, dynamic> j) {
    // Construir portada: preferimos thumb del backend, fallback Steam CDN
    String? cover = j['gameCover']?.toString();
    final sid = j['steamAppID']?.toString();
    if ((cover == null || cover.isEmpty) && sid != null && sid.isNotEmpty) {
      cover = 'https://cdn.akamai.steamstatic.com/steam/apps/$sid/header.jpg';
    }
    return ApiDeal(
      gameId:          j['gameId']?.toString()    ?? '',
      gameTitle:       j['gameTitle']?.toString()  ?? 'Unknown',
      gameCover:       cover,
      store:           j['store']?.toString()      ?? 'steam',
      storeName:       j['storeName']?.toString()  ?? 'Steam',
      originalPrice:   _toDouble(j['originalPrice']),
      salePrice:       _toDouble(j['salePrice']),
      discountPercent: (j['discountPercent'] as num?)?.toInt() ?? 0,
      isFree:          j['isFree'] == true,
      dealUrl:         j['dealUrl']?.toString(),
      steamAppID:      sid,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXCEPCIÓN PERSONALIZADA
// ─────────────────────────────────────────────────────────────────────────────

class ApiException implements Exception {
  final String message;
  final int?   statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

// ─────────────────────────────────────────────────────────────────────────────
// ApiService
// ─────────────────────────────────────────────────────────────────────────────

class ApiService {
  // ── URL base auto-detectada ───────────────────────────────────────────────
  //   Android emulator: las peticiones a "localhost" van al emulador, no al PC.
  //   Por eso usamos la IP especial 10.0.2.2 que apunta al host de Windows.
  //   iOS Simulator / dispositivo físico: localhost o la IP del PC en red local.
  static String get baseUrl {
    // 1. Usar variable de entorno si existe (.env) para móviles físicos
    final envUrl = dotenv.env['API_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }

    // 2. Fallback por defecto de Jesús
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000';
      }
    } catch (_) {}
    return 'http://localhost:3000';
  }

  // ── Timeout global ────────────────────────────────────────────────────────
  static const _timeout = Duration(seconds: 15);

  // ── Cabeceras comunes ─────────────────────────────────────────────────────
  static Future<Map<String, String>> _headers({bool withAuth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (withAuth) {
      final token = await AuthService.getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ── Helper: parsear respuesta ─────────────────────────────────────────────
  static Map<String, dynamic> _parse(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>? ?? {};
    final msg  = body['error']?.toString() ?? 'Error ${r.statusCode}';
    throw ApiException(msg, statusCode: r.statusCode);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AUTH
  // ══════════════════════════════════════════════════════════════════════════

  /// POST /api/users/login — devuelve AuthSession y la persiste
  static Future<AuthSession> login(String email, String password) async {
    final r = await http
        .post(
          Uri.parse('$baseUrl/api/users/login'),
          headers: await _headers(),
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(_timeout);

    final data = _parse(r);
    final token = data['token'] as String;
    final user  = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    await AuthService.saveSession(token, user);
    return AuthSession(token: token, user: user);
  }

  /// POST /api/users/register
  static Future<void> register(
      String username, String email, String password) async {
    final r = await http
        .post(
          Uri.parse('$baseUrl/api/users/register'),
          headers: await _headers(),
          body: jsonEncode({
            'username': username,
            'email':    email,
            'password': password,
          }),
        )
        .timeout(_timeout);

    _parse(r); // lanza ApiException si falla
  }

  /// PUT /api/users/me/pc-components
  static Future<void> updatePcComponents({
    String? cpu,
    String? gpu,
    double? ram,
    String? storage,
  }) async {
    final body = <String, dynamic>{};
    if (cpu != null) body['cpu'] = cpu;
    if (gpu != null) body['gpu'] = gpu;
    if (ram != null) body['ram'] = ram;
    if (storage != null) body['storage'] = storage;

    final r = await http
        .put(
          Uri.parse('$baseUrl/api/users/me/pc-components'),
          headers: await _headers(withAuth: true),
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    final data = _parse(r);
    
    final session = await AuthService.loadSession();
    if (session != null && data['pcComponents'] != null) {
      final updatedUser = AuthUser(
        id: session.user.id,
        username: session.user.username,
        email: session.user.email,
        avatarUrl: session.user.avatarUrl,
        reputation: session.user.reputation,
        pcComponents: data['pcComponents'] as Map<String, dynamic>,
      );
      await AuthService.saveSession(session.token, updatedUser);
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // USUARIOS
  // ───────────────────────────────────────────────────────────────────────────

  /// Obtener perfil propio
  static Future<User> fetchMyProfile() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/users/me'), headers: await _headers(withAuth: true));
      final data = _parse(res);
      return User.fromJson(data['user']);
    } catch (e) {
      print('[ApiService] Error fetching my profile: $e');
      rethrow;
    }
  }

  /// Obtener lista de amigos
  static Future<List<User>> fetchFriends() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/users/friends'), headers: await _headers(withAuth: true));
      final data = _parse(res);
      final friendsList = data['friends'] as List? ?? [];
      return friendsList.map((j) => User.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      print('[ApiService] Error fetching friends: $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BIBLIOTECA DEL USUARIO
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/users/:userId/library
  static Future<List<ApiGame>> getLibrary(String userId) async {
    final r = await http
        .get(
          Uri.parse('$baseUrl/api/users/$userId/library'),
          headers: await _headers(withAuth: true),
        )
        .timeout(_timeout);

    final data    = _parse(r);
    final entries = (data['library'] as List?) ?? [];
    return entries
        .map((e) => ApiGame.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/users/:userId/stats
  static Future<LibraryStats> getStats(String userId) async {
    final r = await http
        .get(
          Uri.parse('$baseUrl/api/users/$userId/stats'),
          headers: await _headers(withAuth: true),
        )
        .timeout(_timeout);

    return LibraryStats.fromJson(_parse(r));
  }

  /// POST /api/users/:userId/library — añadir juego
  static Future<String?> addToLibrary({
    required String userId,
    required String gameTitle,
    String platform = 'Steam',
    String status   = 'Backlog',
  }) async {
    final r = await http
        .post(
          Uri.parse('$baseUrl/api/users/$userId/library'),
          headers: await _headers(withAuth: true),
          body: jsonEncode({
            'gameTitle': gameTitle,
            'platform':  platform,
            'status':    status,
          }),
        )
        .timeout(_timeout);

    final data = _parse(r);
    // El backend devuelve { entry: { _id: '...', ... } }
    return data['entry']?['_id']?.toString();
  }

  /// PATCH /api/users/:userId/library/:entryId — actualizar estado o nota
  static Future<void> updateLibraryEntry({
    required String userId,
    required String entryId,
    String? status,
    String? personalNote,
    int? playtime,
    String? platform,
  }) async {
    final body = <String, dynamic>{};
    if (status       != null) body['status']       = status;
    if (personalNote != null) body['personalNote'] = personalNote;
    if (playtime     != null) body['playtime']     = playtime;
    if (platform     != null) body['platform']     = platform;

    final r = await http
        .patch(
          Uri.parse('$baseUrl/api/users/$userId/library/$entryId'),
          headers: await _headers(withAuth: true),
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    _parse(r);
  }

  /// GET /api/users/:userId/library/:entryId
  static Future<Map<String, dynamic>> getGameDetails({
    required String userId,
    required String entryId,
  }) async {
    final r = await http
        .get(
          Uri.parse('$baseUrl/api/users/$userId/library/$entryId'),
          headers: await _headers(withAuth: true),
        )
        .timeout(_timeout);

    final data = _parse(r);
    final entry = ApiGame.fromJson(data['entry'] as Map<String, dynamic>);
    final compatibility = data['compatibility']?.toString();
    
    return {
      'game': entry,
      'compatibility': compatibility,
    };
  }

  /// DELETE /api/users/:userId/library/:entryId
  static Future<void> removeFromLibrary({
    required String userId,
    required String entryId,
  }) async {
    final r = await http
        .delete(
          Uri.parse('$baseUrl/api/users/$userId/library/$entryId'),
          headers: await _headers(withAuth: true),
        )
        .timeout(_timeout);

    _parse(r);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // JUEGOS — BÚSQUEDA
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/games/search?title=...
  static Future<List<ApiGame>> searchGame(String title) async {
    final uri = Uri.parse('$baseUrl/api/games/search')
        .replace(queryParameters: {'title': title});

    final r = await http
        .get(uri, headers: await _headers())
        .timeout(_timeout);

    if (r.statusCode >= 200 && r.statusCode < 300) {
      final List<dynamic> data = jsonDecode(r.body);
      return data.map((json) => ApiGame.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      final body = jsonDecode(r.body) as Map<String, dynamic>? ?? {};
      throw ApiException(body['error']?.toString() ?? 'Error ${r.statusCode}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DEALS
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/games/deals
  static Future<List<Deal>> fetchDeals({int limit = 20}) async {
    final uri = Uri.parse('$baseUrl/api/games/deals')
        .replace(queryParameters: {'limit': limit.toString()});

    final r = await http
        .get(uri, headers: await _headers())
        .timeout(_timeout);

    final data  = _parse(r);
    final deals = (data['deals'] as List?) ?? [];
    return deals
        .map((d) => Deal.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/games/free
  static Future<List<Deal>> fetchFreeGames() async {
    final r = await http
        .get(
          Uri.parse('$baseUrl/api/games/free'),
          headers: await _headers(),
        )
        .timeout(_timeout);

    final data  = _parse(r);
    final games = (data['freeGames'] as List?) ?? [];
    return games
        .map((g) => Deal.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/games/upcoming
  static Future<List<Deal>> fetchUpcomingGames() async {
    final r = await http
        .get(
          Uri.parse('$baseUrl/api/games/upcoming'),
          headers: await _headers(),
        )
        .timeout(_timeout);

    final data  = _parse(r);
    final games = (data['upcomingGames'] as List?) ?? [];
    return games
        .map((g) => Deal.fromJson(g as Map<String, dynamic>))
        .toList();
  }
}
