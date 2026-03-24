// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Diyanet Awqat Salah API Service
///
/// API Documentation: https://awqatsalah.diyanet.gov.tr/
/// GitHub: https://github.com/DinIsleriYuksekKurulu/AwqatSalah
///
/// Rate Limits:
/// - Each endpoint: 5 requests/day (per parameter combination)
/// - DateRange endpoint: 10 requests/month
/// - First 15 days: 100 requests limit (then drops to 5)
///
/// IMPORTANT: Direct API calls should be minimal due to rate limits.
/// This service will be used by Firebase Cloud Functions for daily data sync.
/// Mobile app will read from Firebase Firestore (cached data).
class DiyanetAwqatSalahService {
  static const String _baseUrl = 'https://awqatsalah.diyanet.gov.tr/api';
  static const String _username = String.fromEnvironment('DIYANET_EMAIL');
  static const String _password = String.fromEnvironment('DIYANET_PASSWORD');

  // Token management
  String? _accessToken;
  DateTime? _tokenExpiry;

  bool get _hasCredentials =>
      _username.trim().isNotEmpty && _password.trim().isNotEmpty;

  void _logError({
    required String scope,
    required String endpoint,
    int? status,
    String? code,
    String? message,
    String? responseBody,
    Object? error,
  }) {
    final normalized = {
      'scope': scope,
      'endpoint': endpoint,
      'status': status,
      'code': code,
      'message': message,
      'responseBody': responseBody == null || responseBody.length < 300
          ? responseBody
          : '${responseBody.substring(0, 300)}...',
      'error': error?.toString(),
    };
    print('❌ Diyanet API Error: $normalized');
  }

  bool _shouldRetryStatus(int statusCode) =>
      statusCode == 429 || statusCode >= 500;

  Future<http.Response?> _requestWithRetry({
    required Future<http.Response> Function() request,
    required String scope,
    required String endpoint,
    int maxRetries = 2,
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await request().timeout(const Duration(seconds: 20));
        if (_shouldRetryStatus(response.statusCode) && attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          continue;
        }
        return response;
      } catch (e) {
        if (attempt == maxRetries) {
          _logError(
            scope: scope,
            endpoint: endpoint,
            code: 'NETWORK_OR_TIMEOUT',
            message: 'Request failed after retries',
            error: e,
          );
          return null;
        }
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }
    return null;
  }

  /// Authentication - Get Access Token
  /// Endpoint: POST /Auth/Login
  Future<bool> authenticate() async {
    if (!_hasCredentials) {
      _logError(
        scope: 'auth',
        endpoint: '/Auth/Login',
        code: 'MISSING_CREDENTIALS',
        message:
            'Diyanet credentials are missing. Pass with --dart-define=DIYANET_EMAIL and --dart-define=DIYANET_PASSWORD',
      );
      return false;
    }

    try {
      const endpoint = '/Auth/Login';
      final url = Uri.parse('$_baseUrl$endpoint');
      final response = await _requestWithRetry(
        scope: 'auth',
        endpoint: endpoint,
        request: () => http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({'email': _username, 'password': _password}),
        ),
      );

      if (response == null) return false;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['accessToken'] ?? data['token'];
        if (_accessToken == null || _accessToken!.isEmpty) {
          _logError(
            scope: 'auth',
            endpoint: endpoint,
            status: response.statusCode,
            code: 'TOKEN_MISSING',
            message:
                'Authentication response does not include token/accessToken',
            responseBody: response.body,
          );
          return false;
        }

        // Token typically expires in 45 minutes
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 45));

        print('✅ Diyanet API: Authentication successful');
        return true;
      } else {
        _logError(
          scope: 'auth',
          endpoint: endpoint,
          status: response.statusCode,
          code: 'AUTH_FAILED',
          message: 'Authentication request failed',
          responseBody: response.body,
        );
        return false;
      }
    } catch (e) {
      _logError(
        scope: 'auth',
        endpoint: '/Auth/Login',
        code: 'AUTH_EXCEPTION',
        message: 'Unexpected authentication exception',
        error: e,
      );
      return false;
    }
  }

  Future<http.Response?> _authorizedGet({
    required String endpoint,
    required String scope,
    Map<String, String>? query,
  }) async {
    if (!await _ensureAuthenticated()) {
      _logError(
        scope: scope,
        endpoint: endpoint,
        code: 'AUTH_REQUIRED',
        message: 'Authentication required before request',
      );
      return null;
    }

    final url = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: query);
    return _requestWithRetry(
      scope: scope,
      endpoint: endpoint,
      request: () => http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Accept': 'application/json',
        },
      ),
    );
  }

  Map<String, dynamic>? _decodeMap(http.Response response) {
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>>? _decodeList(http.Response response) {
    try {
      final decoded = json.decode(response.body);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Check if token is valid
  bool _isTokenValid() {
    if (_accessToken == null || _tokenExpiry == null) return false;
    return DateTime.now().isBefore(_tokenExpiry!);
  }

  /// Ensure we have a valid token
  Future<bool> _ensureAuthenticated() async {
    if (_isTokenValid()) return true;
    return await authenticate();
  }

  /// Get Prayer Times for a specific date and location
  /// Endpoint: GET /PrayerTime/Daily
  /// Parameters:
  /// - CountryCode: TR
  /// - StateCode: Ankara state code
  /// - CityCode: City code
  /// - Date: YYYY-MM-DD
  Future<Map<String, dynamic>?> getDailyPrayerTimes({
    required String countryCode,
    required String stateCode,
    required String cityCode,
    required String date,
  }) async {
    const endpoint = '/PrayerTime/Daily';
    final response = await _authorizedGet(
      endpoint: endpoint,
      scope: 'prayer_daily',
      query: {
        'CountryCode': countryCode,
        'StateCode': stateCode,
        'CityCode': cityCode,
        'Date': date,
      },
    );

    if (response == null) return null;
    if (response.statusCode == 200) {
      final data = _decodeMap(response);
      if (data != null) {
        print('✅ Diyanet API: Daily prayer times fetched for $date');
      }
      return data;
    }

    _logError(
      scope: 'prayer_daily',
      endpoint: endpoint,
      status: response.statusCode,
      code: 'REQUEST_FAILED',
      message: 'Failed to fetch daily prayer times',
      responseBody: response.body,
    );
    return null;
  }

  /// Get Prayer Times for a date range (MONTHLY/YEARLY)
  /// Endpoint: GET /PrayerTime/DateRange
  /// WARNING: Limited to 10 requests per MONTH!
  /// Parameters:
  /// - CountryCode: TR
  /// - StateCode: State code
  /// - CityCode: City code
  /// - StartDate: YYYY-MM-DD
  /// - EndDate: YYYY-MM-DD
  Future<List<Map<String, dynamic>>?> getDateRangePrayerTimes({
    required String countryCode,
    required String stateCode,
    required String cityCode,
    required String startDate,
    required String endDate,
  }) async {
    const endpoint = '/PrayerTime/DateRange';
    final response = await _authorizedGet(
      endpoint: endpoint,
      scope: 'prayer_date_range',
      query: {
        'CountryCode': countryCode,
        'StateCode': stateCode,
        'CityCode': cityCode,
        'StartDate': startDate,
        'EndDate': endDate,
      },
    );

    if (response == null) return null;
    if (response.statusCode == 200) {
      final data = _decodeList(response);
      if (data != null) {
        print(
          '✅ Diyanet API: Date range prayer times fetched (${data.length} days)',
        );
      }
      return data;
    }

    _logError(
      scope: 'prayer_date_range',
      endpoint: endpoint,
      status: response.statusCode,
      code: 'REQUEST_FAILED',
      message: 'Failed to fetch date range prayer times',
      responseBody: response.body,
    );
    return null;
  }

  /// Get Hijri Calendar for a specific Gregorian date
  /// Endpoint: GET /HijriCalendar/Gregorian
  /// Parameters:
  /// - Date: YYYY-MM-DD
  Future<Map<String, dynamic>?> getHijriCalendar({
    String? date,
    String? gregorianDate,
  }) async {
    final targetDate = date ?? gregorianDate;
    if (targetDate == null || targetDate.isEmpty) {
      _logError(
        scope: 'hijri_calendar',
        endpoint: '/HijriCalendar/Gregorian',
        code: 'MISSING_DATE',
        message: 'date or gregorianDate parameter must be provided',
      );
      return null;
    }

    const endpoint = '/HijriCalendar/Gregorian';
    final response = await _authorizedGet(
      endpoint: endpoint,
      scope: 'hijri_calendar',
      query: {'Date': targetDate},
    );

    if (response == null) return null;
    if (response.statusCode == 200) {
      final data = _decodeMap(response);
      if (data != null) {
        print('✅ Diyanet API: Hijri calendar fetched for $targetDate');
      }
      return data;
    }

    _logError(
      scope: 'hijri_calendar',
      endpoint: endpoint,
      status: response.statusCode,
      code: 'REQUEST_FAILED',
      message: 'Failed to fetch Hijri calendar',
      responseBody: response.body,
    );
    return null;
  }

  /// Get Qibla Direction for a location
  /// Endpoint: GET /Qibla
  /// Parameters:
  /// - CountryCode: TR
  /// - StateCode: State code
  /// - CityCode: City code
  Future<Map<String, dynamic>?> getQiblaDirection({
    required String countryCode,
    required String stateCode,
    required String cityCode,
  }) async {
    const endpoint = '/Qibla';
    final response = await _authorizedGet(
      endpoint: endpoint,
      scope: 'qibla',
      query: {
        'CountryCode': countryCode,
        'StateCode': stateCode,
        'CityCode': cityCode,
      },
    );

    if (response == null) return null;
    if (response.statusCode == 200) {
      final data = _decodeMap(response);
      if (data != null) {
        print('✅ Diyanet API: Qibla direction fetched');
      }
      return data;
    }

    _logError(
      scope: 'qibla',
      endpoint: endpoint,
      status: response.statusCode,
      code: 'REQUEST_FAILED',
      message: 'Failed to fetch Qibla direction',
      responseBody: response.body,
    );
    return null;
  }

  /// Get Daily Content (Ayet, Hadis, Dua)
  /// Endpoint: GET /DailyContent
  /// Parameters:
  /// - Date: YYYY-MM-DD (optional, defaults to today)
  Future<Map<String, dynamic>?> getDailyContent({String? date}) async {
    const endpoint = '/DailyContent';
    final dateParam = date ?? DateTime.now().toIso8601String().split('T')[0];
    final response = await _authorizedGet(
      endpoint: endpoint,
      scope: 'daily_content',
      query: {'Date': dateParam},
    );

    if (response == null) return null;
    if (response.statusCode == 200) {
      final data = _decodeMap(response);
      if (data != null) {
        print('✅ Diyanet API: Daily content fetched for $dateParam');
      }
      return data;
    }

    _logError(
      scope: 'daily_content',
      endpoint: endpoint,
      status: response.statusCode,
      code: 'REQUEST_FAILED',
      message: 'Failed to fetch daily content',
      responseBody: response.body,
    );
    return null;
  }

  /// Get Religious Days and Nights
  /// Endpoint: GET /ReligiousDays
  /// Parameters:
  /// - Year: YYYY (optional, defaults to current year)
  Future<List<Map<String, dynamic>>?> getReligiousDays({int? year}) async {
    const endpoint = '/ReligiousDays';
    final targetYear = (year ?? DateTime.now().year).toString();
    final response = await _authorizedGet(
      endpoint: endpoint,
      scope: 'religious_days',
      query: {'Year': targetYear},
    );

    if (response == null) return null;
    if (response.statusCode == 200) {
      final data = _decodeList(response);
      if (data != null) {
        print(
          '✅ Diyanet API: Religious days fetched for $targetYear (${data.length} items)',
        );
      }
      return data;
    }

    _logError(
      scope: 'religious_days',
      endpoint: endpoint,
      status: response.statusCode,
      code: 'REQUEST_FAILED',
      message: 'Failed to fetch religious days',
      responseBody: response.body,
    );
    return null;
  }

  /// Get Country List
  /// Endpoint: GET /Countries
  Future<List<Map<String, dynamic>>?> getCountries() async {
    const endpoint = '/Countries';
    final response = await _authorizedGet(
      endpoint: endpoint,
      scope: 'countries',
    );

    if (response == null) return null;
    if (response.statusCode == 200) {
      final data = _decodeList(response);
      if (data != null) {
        print('✅ Diyanet API: Countries fetched (${data.length} items)');
      }
      return data;
    }

    _logError(
      scope: 'countries',
      endpoint: endpoint,
      status: response.statusCode,
      code: 'REQUEST_FAILED',
      message: 'Failed to fetch countries',
      responseBody: response.body,
    );
    return null;
  }

  /// Get States for a country
  /// Endpoint: GET /States
  /// Parameters:
  /// - CountryCode: TR
  Future<List<Map<String, dynamic>>?> getStates({
    required String countryCode,
  }) async {
    const endpoint = '/States';
    final response = await _authorizedGet(
      endpoint: endpoint,
      scope: 'states',
      query: {'CountryCode': countryCode},
    );

    if (response == null) return null;
    if (response.statusCode == 200) {
      final data = _decodeList(response);
      if (data != null) {
        print(
          '✅ Diyanet API: States fetched for $countryCode (${data.length} items)',
        );
      }
      return data;
    }

    _logError(
      scope: 'states',
      endpoint: endpoint,
      status: response.statusCode,
      code: 'REQUEST_FAILED',
      message: 'Failed to fetch states',
      responseBody: response.body,
    );
    return null;
  }

  /// Get Cities for a state
  /// Endpoint: GET /Cities
  /// Parameters:
  /// - CountryCode: TR
  /// - StateCode: State code
  Future<List<Map<String, dynamic>>?> getCities({
    required String countryCode,
    required String stateCode,
  }) async {
    const endpoint = '/Cities';
    final response = await _authorizedGet(
      endpoint: endpoint,
      scope: 'cities',
      query: {'CountryCode': countryCode, 'StateCode': stateCode},
    );

    if (response == null) return null;
    if (response.statusCode == 200) {
      final data = _decodeList(response);
      if (data != null) {
        print(
          '✅ Diyanet API: Cities fetched for $stateCode (${data.length} items)',
        );
      }
      return data;
    }

    _logError(
      scope: 'cities',
      endpoint: endpoint,
      status: response.statusCode,
      code: 'REQUEST_FAILED',
      message: 'Failed to fetch cities',
      responseBody: response.body,
    );
    return null;
  }
}
