import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chat_models.dart';

/// Dialogflow REST API servisi
/// Çoklu dil desteği ile AI yanıtları alır
class DialogflowService {
  static final DialogflowService _instance = DialogflowService._internal();
  factory DialogflowService() => _instance;
  DialogflowService._internal();

  // Dialogflow yapılandırması
  static const String _baseUrl = 'https://dialogflow.googleapis.com/v2';
  
  // Dil bazlı project ID'leri
  static const Map<String, String> _projectIds = {
    'tr': 'randevu-erp-tr', // Türkçe agent
    'en': 'randevu-erp-en', // İngilizce agent  
    'de': 'randevu-erp-de', // Almanca agent
    'es': 'randevu-erp-es', // İspanyolca agent
    'fr': 'randevu-erp-fr', // Fransızca agent
  };

  // Session timeout (30 dakika)
  static const int _sessionTimeoutMinutes = 30;
  
  // Cache for session management
  final Map<String, DateTime> _activeSessions = {};

  /// Dialogflow'a mesaj gönder ve yanıt al
  Future<DialogflowResponse> sendMessage({
    required String message,
    required String sessionId,
    required String language,
    String? topic,
    Map<String, dynamic>? context,
  }) async {
    try {
      debugPrint('🤖 Dialogflow: Mesaj gönderiliyor...');
      debugPrint('   💬 Message: ${message.length > 50 ? "${message.substring(0, 50)}..." : message}');
      debugPrint('   🌍 Language: $language');
      debugPrint('   🎯 Topic: $topic');
      
      // Session kontrolü
      await _validateSession(sessionId);
      
      // Project ID'yi dile göre seç
      final projectId = _getProjectIdForLanguage(language);
      
      // Request body oluştur
      final requestBody = _buildRequestBody(
        message: message,
        sessionId: sessionId,
        language: language,
        topic: topic,
        context: context,
      );
      
      // API endpoint
      final url = '$_baseUrl/projects/$projectId/agent/sessions/$sessionId:detectIntent';
      
      // HTTP request gönder
      final response = await _sendHttpRequest(url, requestBody);
      
      // Yanıtı parse et
      final dialogflowResponse = _parseResponse(response, language);
      
      debugPrint('✅ Dialogflow: Yanıt alındı');
      debugPrint('   🎯 Intent: ${dialogflowResponse.intentName}');
      debugPrint('   📊 Confidence: ${dialogflowResponse.confidence.toStringAsFixed(2)}');
      debugPrint('   💬 Response: ${dialogflowResponse.text.length > 100 ? "${dialogflowResponse.text.substring(0, 100)}..." : dialogflowResponse.text}');
      
      return dialogflowResponse;
      
    } catch (e) {
      debugPrint('❌ Dialogflow error: $e');
      return _handleError(e, language);
    }
  }

  /// Session'ı doğrula ve yenile
  Future<void> _validateSession(String sessionId) async {
    final now = DateTime.now();
    final lastActivity = _activeSessions[sessionId];
    
    if (lastActivity == null || 
        now.difference(lastActivity).inMinutes > _sessionTimeoutMinutes) {
      _activeSessions[sessionId] = now;
      debugPrint('🔄 Dialogflow: Session yenilendi - $sessionId');
    } else {
      _activeSessions[sessionId] = now;
    }
  }

  /// Dile göre project ID döndür
  String _getProjectIdForLanguage(String language) {
    final projectId = _projectIds[language] ?? _projectIds['tr']!;
    debugPrint('🎯 Dialogflow: Project ID - $projectId for language $language');
    return projectId;
  }

  /// Request body oluştur
  Map<String, dynamic> _buildRequestBody({
    required String message,
    required String sessionId,
    required String language,
    String? topic,
    Map<String, dynamic>? context,
  }) {
    final body = {
      'queryInput': {
        'text': {
          'text': message,
          'languageCode': language,
        },
      },
      'queryParams': {
        'timeZone': 'Europe/Istanbul',
        'contexts': _buildContexts(topic: topic, context: context),
      },
    };

    debugPrint('📤 Dialogflow Request Body: ${jsonEncode(body)}');
    return body;
  }

  /// Context'leri oluştur
  List<Map<String, dynamic>> _buildContexts({
    String? topic,
    Map<String, dynamic>? context,
  }) {
    final contexts = <Map<String, dynamic>>[];

    // Topic context'i ekle
    if (topic != null) {
      contexts.add({
        'name': 'topic-context',
        'lifespanCount': 10,
        'parameters': {
          'topic': topic,
          'topicDisplayName': ChatTopic.getDisplayName(topic),
        },
      });
    }

    // Ek context'leri ekle
    if (context != null && context.isNotEmpty) {
      contexts.add({
        'name': 'user-context',
        'lifespanCount': 5,
        'parameters': context,
      });
    }

    return contexts;
  }

  /// HTTP request gönder
  Future<Map<String, dynamic>> _sendHttpRequest(
    String url, 
    Map<String, dynamic> body,
  ) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${await _getAccessToken()}',
    };

    debugPrint('📡 Dialogflow: HTTP Request gönderiliyor...');
    debugPrint('   🔗 URL: $url');

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw TimeoutException('Dialogflow timeout', 30),
    );

    debugPrint('📥 Dialogflow: Response alındı - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      debugPrint('❌ Dialogflow HTTP Error: ${response.statusCode}');
      debugPrint('❌ Response Body: ${response.body}');
      throw HttpException(
        'Dialogflow API error: ${response.statusCode} - ${response.reasonPhrase}',
      );
    }
  }

  /// Access token al (Firebase Functions üzerinden veya service account)
  Future<String> _getAccessToken() async {
    try {
      // TODO: Firebase Functions'dan access token al
      // Bu örnekte placeholder token kullanıyoruz
      
      if (kIsWeb) {
        // Web için Firebase Functions endpoint
        return await _getTokenFromFirebaseFunction();
      } else {
        // Mobile için service account key (güvenli storage'dan)
        return await _getTokenFromServiceAccount();
      }
    } catch (e) {
      debugPrint('❌ Access token alınamadı: $e');
      // Fallback: Demo mode
      return 'demo-token';
    }
  }

  /// Firebase Functions'dan token al
  Future<String> _getTokenFromFirebaseFunction() async {
    try {
      const functionUrl = 'https://us-central1-randevu-erp.cloudfunctions.net/getDialogflowToken';
      
      final response = await http.get(
        Uri.parse(functionUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['accessToken'] ?? '';
      } else {
        throw Exception('Token function error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Firebase Functions token error: $e');
      return 'demo-token'; // Demo mode
    }
  }

  /// Service account'tan token al
  Future<String> _getTokenFromServiceAccount() async {
    try {
      // TODO: Güvenli storage'dan service account key al
      // JWT oluştur ve Google OAuth2'dan token al
      debugPrint('📱 Mobile: Service account token alınıyor...');
      return 'mobile-demo-token'; // Demo mode
    } catch (e) {
      debugPrint('❌ Service account token error: $e');
      return 'demo-token';
    }
  }

  /// Dialogflow yanıtını parse et
  DialogflowResponse _parseResponse(
    Map<String, dynamic> response, 
    String language,
  ) {
    try {
      final queryResult = response['queryResult'] as Map<String, dynamic>? ?? {};
      
      // Fulfillment text al
      String fulfillmentText = queryResult['fulfillmentText'] ?? '';
      
      // Eğer boşsa, alternative responses'lara bak
      if (fulfillmentText.isEmpty) {
        final messages = queryResult['fulfillmentMessages'] as List? ?? [];
        for (final message in messages) {
          if (message['text']?['text'] != null) {
            final textList = message['text']['text'] as List;
            if (textList.isNotEmpty) {
              fulfillmentText = textList[0].toString();
              break;
            }
          }
        }
      }

      // Fallback response
      if (fulfillmentText.isEmpty) {
        fulfillmentText = _getFallbackResponse(language);
      }

      return DialogflowResponse(
        text: fulfillmentText,
        intentName: queryResult['intent']?['displayName'] ?? 'Unknown',
        parameters: Map<String, dynamic>.from(queryResult['parameters'] ?? {}),
        confidence: (queryResult['intentDetectionConfidence'] ?? 0.0).toDouble(),
        followupEvent: queryResult['followupEventInput']?['name'],
        suggestions: _extractSuggestions(queryResult),
      );
      
    } catch (e) {
      debugPrint('❌ Response parsing error: $e');
      return DialogflowResponse.error(_getFallbackResponse(language));
    }
  }

  /// Suggestions'ları çıkar
  List<String>? _extractSuggestions(Map<String, dynamic> queryResult) {
    try {
      final messages = queryResult['fulfillmentMessages'] as List? ?? [];
      for (final message in messages) {
        if (message['quickReplies']?['quickReplies'] != null) {
          return List<String>.from(message['quickReplies']['quickReplies']);
        }
        if (message['suggestions']?['suggestions'] != null) {
          final suggestions = message['suggestions']['suggestions'] as List;
          return suggestions.map((s) => s['title'].toString()).toList();
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Suggestions extraction error: $e');
      return null;
    }
  }

  /// Hata durumunda response oluştur
  DialogflowResponse _handleError(dynamic error, String language) {
    String errorMessage;
    
    if (error is TimeoutException) {
      errorMessage = _getErrorMessage('timeout', language);
    } else if (error is HttpException) {
      errorMessage = _getErrorMessage('network', language);
    } else if (error.toString().contains('401') || error.toString().contains('403')) {
      errorMessage = _getErrorMessage('auth', language);
    } else {
      errorMessage = _getErrorMessage('general', language);
    }

    return DialogflowResponse.error(errorMessage);
  }

  /// Dile göre hata mesajı
  String _getErrorMessage(String errorType, String language) {
    final messages = <String, Map<String, String>>{
      'timeout': {
        'tr': 'Üzgünüm, yanıt verirken zaman aşımı oldu. Lütfen tekrar deneyin.',
        'en': 'Sorry, response timeout occurred. Please try again.',
        'de': 'Entschuldigung, Antwort-Timeout aufgetreten. Bitte versuchen Sie es erneut.',
        'es': 'Lo siento, se agotó el tiempo de respuesta. Por favor intenta de nuevo.',
        'fr': 'Désolé, délai de réponse dépassé. Veuillez réessayer.',
      },
      'network': {
        'tr': 'Bağlantı sorunu yaşanıyor. İnternet bağlantınızı kontrol edin.',
        'en': 'Connection problem occurred. Please check your internet connection.',
        'de': 'Verbindungsproblem aufgetreten. Bitte überprüfen Sie Ihre Internetverbindung.',
        'es': 'Problema de conexión. Por favor verifica tu conexión a internet.',
        'fr': 'Problème de connexion. Veuillez vérifier votre connexion internet.',
      },
      'auth': {
        'tr': 'Kimlik doğrulama sorunu. Lütfen daha sonra tekrar deneyin.',
        'en': 'Authentication problem. Please try again later.',
        'de': 'Authentifizierungsproblem. Bitte versuchen Sie es später erneut.',
        'es': 'Problema de autenticación. Por favor intenta más tarde.',
        'fr': 'Problème d\'authentification. Veuillez réessayer plus tard.',
      },
      'general': {
        'tr': 'Bir hata oluştu. Lütfen daha sonra tekrar deneyin.',
        'en': 'An error occurred. Please try again later.',
        'de': 'Ein Fehler ist aufgetreten. Bitte versuchen Sie es später erneut.',
        'es': 'Ocurrió un error. Por favor intenta más tarde.',
        'fr': 'Une erreur s\'est produite. Veuillez réessayer plus tard.',
      },
    };

    return messages[errorType]?[language] ?? 
           messages[errorType]?['tr'] ?? 
           'Bir hata oluştu.';
  }

  /// Fallback response
  String _getFallbackResponse(String language) {
    final responses = {
      'tr': 'Üzgünüm, sizi anlayamadım. Lütfen farklı şekilde ifade edin.',
      'en': 'Sorry, I didn\'t understand. Please rephrase your question.',
      'de': 'Entschuldigung, ich habe Sie nicht verstanden. Bitte formulieren Sie Ihre Frage anders.',
      'es': 'Lo siento, no entendí. Por favor reformula tu pregunta.',
      'fr': 'Désolé, je n\'ai pas compris. Veuillez reformuler votre question.',
    };

    return responses[language] ?? responses['tr']!;
  }

  /// Session'ı temizle
  void clearSession(String sessionId) {
    _activeSessions.remove(sessionId);
    debugPrint('🗑️ Dialogflow: Session temizlendi - $sessionId');
  }

  /// Tüm session'ları temizle
  void clearAllSessions() {
    _activeSessions.clear();
    debugPrint('🗑️ Dialogflow: Tüm session\'lar temizlendi');
  }

  /// Aktif session sayısı
  int get activeSessionCount => _activeSessions.length;

  /// Demo mode kontrolü
  bool get isDemoMode => kDebugMode; // Debug mode'da demo çalışır
}

/// Timeout exception'ı için
class TimeoutException implements Exception {
  final String message;
  final int timeoutSeconds;
  
  const TimeoutException(this.message, this.timeoutSeconds);
  
  @override
  String toString() => 'TimeoutException: $message (${timeoutSeconds}s)';
}