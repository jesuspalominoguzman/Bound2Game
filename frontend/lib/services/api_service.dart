// Este archivo es el corazón de la comunicación con el servidor. Aquí definimos todas las llamadas para el login, la biblioteca, las ofertas y demás.
// He intentado dejarlo bien organizado para no volverme loco cuando tenga que añadir rutas nuevas en el backend.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';
import '../models/deal_model.dart';
import '../models/user_model.dart';

// Cómo nos llega un juego desde el backend. He intentado que soporte todo: tiempos de HLTB, precios, requisitos...
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

  // Estos campos son específicos de cuando el juego ya está en la biblioteca de alguien.
  final String? entryId;
  final String? status;          // Backlog | Playing | Completed | Abandoned
  final String? personalNote;
  final String? platform;
  final DateTime? addedAt;
  final double? rentability;
  final String? pcRequirements;
  final List<String> rawgPlatforms; 
  final int? userPlaytime;
  final int? releaseYear;
  final List<String> genres;
  final int? metacritic;
  final String? esrbRating;

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
    this.releaseYear,
    this.genres = const [],
    this.metacritic,
    this.esrbRating,
  });

  factory ApiGame.fromJson(Map<String, dynamic> json) {
    // A veces los datos vienen anidados en 'gameId' o 'game' dependiendo de la ruta.
    final gameData = json['gameId'] as Map<String, dynamic>? ?? json['game'] as Map<String, dynamic>? ?? json;
    final gameDetails = json['gameDetails'] as Map<String, dynamic>?;
    final hltb     = gameData['hltb'] as Map<String, dynamic>?;

    final steamId  = gameDetails?['id']?.toString() ?? gameData['steamAppID']?.toString();
    final title    = gameDetails?['name']?.toString() ?? gameData['title']?.toString() ?? 'Sin título';
    
    // Si no tenemos imagen, intentamos pillarla de Steam usando su ID.
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
      releaseYear:      (gameData['releaseYear'] as num?)?.toInt(),
      genres:           List<String>.from(gameData['genres'] ?? []),
      metacritic:       (gameData['metacritic'] as num?)?.toInt(),
      esrbRating:       gameData['esrbRating']?.toString(),
    );
  }

  // Un pequeño apaño para convertir cualquier cosa a número decimal sin que la app pete.
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  // Si no hay portada, ponemos una genérica de Unsplash para que no quede el hueco feo.
  String get coverUrl {
    if (imageUrl.isNotEmpty) return imageUrl;
    return 'https://images.unsplash.com/photo-1614294148960-9aa740632a87?w=400&q=80';
  }
}

// Los datos básicos que necesitamos cuando buscamos a alguien para agregarlo.
class UserSearchResult {
  final String  id;
  final String  username;
  final String? avatarUrl;
  final int     karma;
  final String? friendStatus; // 'none', 'pending', 'accepted', 'friends'

  const UserSearchResult({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.karma = 0,
    this.friendStatus,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> j) => UserSearchResult(
    id:           j['_id']?.toString() ?? j['id']?.toString() ?? '',
    username:     j['username']?.toString() ?? '',
    avatarUrl:    j['avatarUrl']?.toString(),
    karma:        (j['karma'] as num?)?.toInt() ?? 0,
    friendStatus: j['friendStatus']?.toString(),
  );

  UserSearchResult copyWith({String? friendStatus}) {
    return UserSearchResult(
      id: id,
      username: username,
      avatarUrl: avatarUrl,
      karma: karma,
      friendStatus: friendStatus ?? this.friendStatus,
    );
  }
}

// Para mostrar en el perfil cuántos juegos tenemos en total, cuántos hemos terminado, etc.
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

// Cómo nos llega una oferta desde el backend.
class ApiDeal {
  final String  gameId;
  final String  gameTitle;
  final String? gameCover;
  final String  store;           
  final String  storeName;       
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

// Para cuando el servidor nos suelta un error, que la app sepa qué ha pasado.
class ApiException implements Exception {
  final String message;
  final int?   statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

// Aquí es donde hacemos las peticiones HTTP reales al servidor.
class ApiService {

  // La URL base del backend en la nube. Siempre viene del archivo .env (API_URL).
  static String get baseUrl => dotenv.env['API_URL'] ?? '';

  static const _timeout = Duration(seconds: 20);
  static const String rawgKey = '42709b841ddd4990af559a90c96b8b0e';

  // Preparamos las cabeceras, metiendo el token de seguridad si hace falta.
  static Future<Map<String, String>> _headers({bool withAuth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (withAuth) {
      final token = await AuthService.getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Este método se encarga de leer lo que nos dice el servidor. Si algo va mal, lanza un error.
  static Map<String, dynamic> _parse(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      try {
        return jsonDecode(r.body) as Map<String, dynamic>;
      } catch (_) {
        throw ApiException('El servidor ha respondido algo raro...', statusCode: r.statusCode);
      }
    }
    try {
      final body = jsonDecode(r.body) as Map<String, dynamic>? ?? {};
      final msg  = body['error']?.toString() ?? 'Error ${r.statusCode}';
      throw ApiException(msg, statusCode: r.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Vaya, parece que el servidor está caído (${r.statusCode})',
          statusCode: r.statusCode);
    }
  }

  // --- RUTAS DE AUTENTICACIÓN ---

  // Para entrar en la app. Si todo va bien, guardamos la sesión.
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

  // Para crear una cuenta nueva.
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

    _parse(r); 
  }

  // Para guardar qué PC tenemos.
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
    
    // Actualizamos la sesión guardada para que los cambios se vean al momento.
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

  // Para vincular cuentas de Steam, Epic, etc.
  static Future<void> updatePlatforms({
    String? steamId,
    String? epicId,
    String? xboxId,
    String? discordId,
  }) async {
    final body = <String, dynamic>{};
    if (steamId != null) body['steamId'] = steamId;
    if (epicId != null) body['epicId'] = epicId;
    if (xboxId != null) body['xboxId'] = xboxId;
    if (discordId != null) body['discordId'] = discordId;

    final r = await http
        .put(
          Uri.parse('$baseUrl/api/users/me/platforms'),
          headers: await _headers(withAuth: true),
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    _parse(r);
  }

  // --- RUTAS DE USUARIOS Y AMIGOS ---

  // Pillamos nuestro propio perfil.
  static Future<User> fetchMyProfile() async {
    final res = await http.get(Uri.parse('$baseUrl/api/users/me'), headers: await _headers(withAuth: true));
    final data = _parse(res);
    return User.fromJson(data['user']);
  }

  // Pedimos la lista de amigos.
  static Future<List<User>> fetchFriends() async {
    final res = await http.get(Uri.parse('$baseUrl/api/users/friends'), headers: await _headers(withAuth: true));
    final data = _parse(res);
    final friendsList = data['friends'] as List? ?? [];
    return friendsList.map((j) => User.fromJson(j as Map<String, dynamic>)).toList();
  }

  // Miramos si alguien nos ha mandado una solicitud de amistad.
  static Future<List<UserSearchResult>> getPendingRequests() async {
    final r = await http
        .get(
          Uri.parse('$baseUrl/api/users/pending-requests'),
          headers: await _headers(withAuth: true),
        )
        .timeout(_timeout);

    final data = _parse(r);
    final list = (data['pendingRequests'] as List?) ?? [];
    return list.map((u) => UserSearchResult.fromJson(u as Map<String, dynamic>)).toList();
  }

  // Ver el perfil de otro jugador.
  static Future<User> getUserProfilePublic(String userId) async {
    final r = await http
        .get(
          Uri.parse('$baseUrl/api/users/$userId/profile-public'),
          headers: await _headers(withAuth: true),
        )
        .timeout(_timeout);

    final data = _parse(r);
    return User.fromJson(data['profile'] as Map<String, dynamic>);
  }

  // Darle un "me gusta" o "no me gusta" a alguien.
  static Future<Map<String, dynamic>> rateUser(String userId, String action) async {
    final r = await http
        .post(
          Uri.parse('$baseUrl/api/users/$userId/rate'),
          headers: await _headers(withAuth: true),
          body: jsonEncode({'action': action}),
        )
        .timeout(_timeout);

    return _parse(r);
  }

  // Buscar gente por su nombre de usuario.
  static Future<List<UserSearchResult>> searchUsers(String q) async {
    if (q.isEmpty) return [];
    final uri = Uri.parse('$baseUrl/api/users/search')
        .replace(queryParameters: {'q': q});
    final r = await http
        .get(uri, headers: await _headers(withAuth: true))
        .timeout(_timeout);
    final data = _parse(r);
    final users = data['users'] as List? ?? [];
    return users
        .map((j) => UserSearchResult.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // Mandar una solicitud de amistad o aceptar una que nos hayan mandado.
  static Future<String> sendFriendRequest(String targetId) async {
    final r = await http
        .post(
          Uri.parse('$baseUrl/api/users/friend-request'),
          headers: await _headers(withAuth: true),
          body: jsonEncode({'targetId': targetId}),
        )
        .timeout(_timeout);
    if (r.statusCode == 409) {
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      return body['status']?.toString() ?? 'error';
    }
    final data = _parse(r);
    return data['status']?.toString() ?? 'pending';
  }

  // Ver qué juegos tiene un amigo.
  static Future<List<ApiGame>> getFriendLibrary(String friendId) async {
    final r = await http
        .get(
          Uri.parse('$baseUrl/api/users/$friendId/library-public'),
          headers: await _headers(withAuth: true),
        )
        .timeout(_timeout);
    final data    = _parse(r);
    final entries = (data['library'] as List?) ?? [];
    return entries
        .map((e) => ApiGame.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Echar un ojo a la biblioteca de alguien antes de agregarlo.
  static Future<List<ApiGame>> getUserLibraryPreview(String userId) async {
    if (userId.isEmpty) return [];
    final r = await http
        .get(
          Uri.parse('$baseUrl/api/users/$userId/library-preview'),
          headers: await _headers(withAuth: true),
        )
        .timeout(_timeout);
    final data    = _parse(r);
    final entries = (data['library'] as List?) ?? [];
    return entries
        .map((e) => ApiGame.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // --- RUTAS DE BIBLIOTECA ---

  // Pillamos nuestra propia lista de juegos.
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

  // Miramos las estadísticas de nuestra biblioteca (cuántos terminados, etc).
  static Future<LibraryStats> getStats(String userId) async {
    final r = await http
        .get(
          Uri.parse('$baseUrl/api/users/$userId/stats'),
          headers: await _headers(withAuth: true),
        )
        .timeout(_timeout);

    return LibraryStats.fromJson(_parse(r));
  }

  // Para añadir un juego nuevo a nuestra colección.
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
    return data['entry']?['_id']?.toString();
  }

  // Para cambiar el estado de un juego o poner una nota personal.
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

  // Pillamos todos los detalles de un juego de nuestra biblioteca.
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

  // Para borrar un juego de la biblioteca.
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

  // --- RUTAS DE BÚSQUEDA Y OFERTAS ---

  // Buscamos un juego por su título para ver sus detalles.
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

  // Pillamos las ofertas más destacadas.
  static Future<List<Deal>> fetchDeals({int limit = 120}) async {
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

  // Pillamos los juegos que están gratis ahora mismo. ¡Lo que más nos gusta!
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

  // Buscamos si un juego concreto tiene alguna oferta activa.
  static Future<List<Deal>> fetchDealsByGame(String title) async {
    final uri = Uri.parse('$baseUrl/api/games/deals/${Uri.encodeComponent(title)}');
    final r = await http
        .get(uri, headers: await _headers())
        .timeout(_timeout);

    final data  = _parse(r);
    final deals = (data['deals'] as List?) ?? [];
    return deals
        .map((d) => Deal.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  // Miramos qué juegos van a salir pronto.
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

  // --- NUEVAS RUTAS PARA AVATARES (RAWG) ---

  // Buscar avatares en RAWG (personajes o juegos)
  static Future<List<String>> fetchRawgAvatars(String query) async {
    // Si no hay búsqueda, traemos juegos populares para dar opciones variadas
    final q = query.trim().isEmpty ? 'top' : query;
    final uri = Uri.parse('https://api.rawg.io/api/games?key=$rawgKey&search=$q&page_size=40');
    
    try {
      final r = await http.get(uri).timeout(_timeout);
      if (r.statusCode != 200) return [];
      
      final data = jsonDecode(r.body);
      final results = data['results'] as List? ?? [];
      
      // Filtramos las imágenes que vengan vacías
      return results
          .map((g) => g['background_image']?.toString())
          .where((url) => url != null && url.isNotEmpty)
          .cast<String>()
          .toList();
    } catch (e) {
      print('Error al buscar avatares en RAWG: $e');
      return [];
    }
  }

  // Actualizar el avatar en nuestro backend
  static Future<void> updateAvatar(String? avatarUrl) async {
    final r = await http
        .put(
          Uri.parse('$baseUrl/api/users/me/avatar'),
          headers: await _headers(withAuth: true),
          body: jsonEncode({'avatarUrl': avatarUrl}),
        )
        .timeout(_timeout);

    final data = _parse(r);

    // Actualizamos la sesión local para que el cambio sea instantáneo en toda la app
    final session = await AuthService.loadSession();
    if (session != null) {
      final updatedUser = AuthUser(
        id: session.user.id,
        username: session.user.username,
        email: session.user.email,
        avatarUrl: data['avatarUrl']?.toString() ?? '',
        reputation: session.user.reputation,
        pcComponents: session.user.pcComponents,
      );
      await AuthService.saveSession(session.token, updatedUser);
    }
  }
}
