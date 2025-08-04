import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ai_chat_models.dart';

/// 🤖 Dialogflow API Entegrasyon Servisi
class DialogflowService {
  static const String _baseUrl = 'https://dialogflow.googleapis.com/v2';
  
  // Her dil için farklı Dialogflow Project ID'leri
  static const Map<String, String> _projectIds = {
    'tr': 'locapo-turkish-agent',      // Türkçe agent
    'en': 'locapo-english-agent',      // İngilizce agent
    'de': 'locapo-german-agent',       // Almanca agent
    'es': 'locapo-spanish-agent',      // İspanyolca agent
    'fr': 'locapo-french-agent',       // Fransızca agent
  };

  // Demo mode için sabit yanıtlar (API yokken test için)
  static const Map<String, List<String>> _demoResponses = {
    'tr': [
      'Merhaba! Size nasıl yardımcı olabilirim?',
      'Randevu işlemleri için size yardımcı olabilirim.',
      'Bu konuda daha fazla bilgi verebilir misiniz?',
      'Anlıyorum. Başka bir şey var mı?',
      'Size yardımcı olabildiğim için mutluyum!',
    ],
    'en': [
      'Hello! How can I help you today?',
      'I can assist you with appointment management.',
      'Could you provide more information about this?',
      'I understand. Is there anything else?',
      'I\'m happy to help you!',
    ],
    'de': [
      'Hallo! Wie kann ich Ihnen heute helfen?',
      'Ich kann Ihnen bei der Terminverwaltung helfen.',
      'Können Sie mehr Informationen dazu geben?',
      'Ich verstehe. Gibt es noch etwas anderes?',
      'Ich helfe Ihnen gerne!',
    ],
    'es': [
      '¡Hola! ¿Cómo puedo ayudarte hoy?',
      'Puedo ayudarte con la gestión de citas.',
      '¿Podrías dar más información sobre esto?',
      'Entiendo. ¿Hay algo más?',
      '¡Me alegro de poder ayudarte!',
    ],
    'fr': [
      'Bonjour! Comment puis-je vous aider aujourd\'hui?',
      'Je peux vous aider avec la gestion des rendez-vous.',
      'Pourriez-vous donner plus d\'informations à ce sujet?',
      'Je comprends. Y a-t-il autre chose?',
      'Je suis heureux de pouvoir vous aider!',
    ],
  };

  final http.Client _httpClient;
  bool _isDemoMode = true; // Firebase Functions hazır olmadan demo mode

  DialogflowService({http.Client? httpClient}) 
      : _httpClient = httpClient ?? http.Client();

  /// 🎯 Ana mesaj gönderme metodu
  Future<DialogflowResponse> detectIntent({
    required String message,
    required String sessionId,
    required String languageCode,
    required String topic,
  }) async {
    try {
      debugPrint('🤖 Dialogflow: Mesaj gönderiliyor...');
      debugPrint('📝 Mesaj: $message');
      debugPrint('🌍 Dil: $languageCode');
      debugPrint('🎯 Konu: $topic');

      // Demo mode aktifse demo yanıt döndür
      if (_isDemoMode) {
        return _getDemoResponse(message, languageCode, topic);
      }

      // Gerçek Dialogflow API çağrısı
      return await _callDialogflowAPI(message, sessionId, languageCode, topic);

    } catch (e) {
      debugPrint('❌ Dialogflow Hata: $e');
      
      // Hata durumunda fallback yanıt
      return DialogflowResponse.empty(message, languageCode);
    }
  }

  /// 🔥 Gerçek Dialogflow API çağrısı
  Future<DialogflowResponse> _callDialogflowAPI(
    String message,
    String sessionId,
    String languageCode,
    String topic,
  ) async {
    final projectId = _projectIds[languageCode] ?? _projectIds['tr']!;
    
    // Access token alma (Firebase Functions üzerinden)
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      throw Exception('Access token alınamadı');
    }

    // API endpoint oluştur
    final endpoint = '$_baseUrl/projects/$projectId/agent/sessions/$sessionId:detectIntent';
    
    // Request body oluştur
    final requestBody = {
      'queryInput': {
        'text': {
          'text': message,
          'languageCode': languageCode,
        }
      },
      'queryParams': {
        'contexts': [
          {
            'name': 'projects/$projectId/agent/sessions/$sessionId/contexts/topic-context',
            'parameters': {
              'topic': topic,
            }
          }
        ]
      }
    };

    debugPrint('🌐 API Endpoint: $endpoint');

    // HTTP POST isteği
    final response = await _httpClient.post(
      Uri.parse(endpoint),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    debugPrint('📊 Response Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      debugPrint('✅ Dialogflow Yanıt: ${responseData['queryResult']['fulfillmentText']}');
      
      return DialogflowResponse.fromJson(responseData);
    } else {
      debugPrint('❌ API Hata: ${response.statusCode} - ${response.body}');
      throw Exception('Dialogflow API Hatası: ${response.statusCode}');
    }
  }

  /// 🎭 Demo mode yanıt generator
  DialogflowResponse _getDemoResponse(String message, String languageCode, String topic) {
    final responses = _demoResponses[languageCode] ?? _demoResponses['tr']!;
    
    // Mesaja göre context-aware yanıt seç
    String selectedResponse;
    
    if (message.toLowerCase().contains('merhaba') || message.toLowerCase().contains('hello')) {
      selectedResponse = responses[0]; // Karşılama mesajı
    } else if (message.toLowerCase().contains('randevu') || message.toLowerCase().contains('appointment')) {
      selectedResponse = responses[1]; // Randevu yanıtı
    } else if (message.contains('?')) {
      selectedResponse = responses[2]; // Soru yanıtı
    } else {
      // Random yanıt seç
      selectedResponse = responses[DateTime.now().millisecond % responses.length];
    }

    debugPrint('🎭 Demo Yanıt: $selectedResponse');

    return DialogflowResponse(
      queryText: message,
      fulfillmentText: selectedResponse,
      intentDisplayName: 'demo.intent',
      languageCode: languageCode,
      parameters: {'topic': topic},
    );
  }

  /// 🔐 Access Token alma (Firebase Functions üzerinden)
  Future<String?> _getAccessToken() async {
    try {
      // Firebase Functions endpoint'i
      const functionUrl = 'https://us-central1-your-project.cloudfunctions.net/getDialogflowToken';
      
      final response = await _httpClient.post(
        Uri.parse(functionUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['accessToken'];
      } else {
        debugPrint('❌ Token alma hatası: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Token alma exception: $e');
      return null;
    }
  }

  /// 🎯 Demo mode açma/kapama
  void setDemoMode(bool enabled) {
    _isDemoMode = enabled;
    debugPrint('🎭 Demo Mode: ${enabled ? "Açık" : "Kapalı"}');
  }

  /// 🗣️ Dil doğrulama
  bool isLanguageSupported(String languageCode) {
    return _projectIds.containsKey(languageCode);
  }

  /// 🧹 Temizlik
  void dispose() {
    _httpClient.close();
  }

  /// 📨 Static mesaj gönderme metodu (istenen format için)
  static Future<String> sendMessage({
    required String text,
    required String languageCode,
    required String email,
  }) async {
    try {
      debugPrint('📨 Static sendMessage çağrıldı');
      debugPrint('📝 Mesaj: $text');
      debugPrint('🌍 Dil: $languageCode');
      debugPrint('📧 Email: $email');

      final service = DialogflowService();
      
      // Fake session ID oluştur
      final sessionId = '${email.hashCode}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Dialogflow yanıtını al
      final response = await service.detectIntent(
        message: text,
        sessionId: sessionId,
        languageCode: languageCode,
        topic: 'general',
      );

      // Firestore'a kaydet
      await FirebaseFirestore.instance
          .collection('ai_chat_logs')
          .add({
            'email': email,
            'language': languageCode,
            'message': text,
            'response': response.fulfillmentText,
            'timestamp': FieldValue.serverTimestamp(),
            'sessionId': sessionId,
          });

      debugPrint('✅ Static mesaj gönderildi: ${response.fulfillmentText}');
      return response.fulfillmentText;

    } catch (e) {
      debugPrint('❌ Static sendMessage hatası: $e');
      // Fallback yanıt
      return _getErrorResponse(languageCode);
    }
  }

  /// ❌ Hata durumunda dil bazlı yanıt
  static String _getErrorResponse(String languageCode) {
    switch (languageCode) {
      case 'tr':
        return 'Üzgünüm, şu anda teknik bir sorun yaşıyoruz. Lütfen daha sonra tekrar deneyin.';
      case 'en':
        return 'Sorry, we are experiencing technical issues. Please try again later.';
      case 'de':
        return 'Entschuldigung, wir haben technische Probleme. Bitte versuchen Sie es später erneut.';
      case 'es':
        return 'Lo siento, estamos experimentando problemas técnicos. Inténtalo de nuevo más tarde.';
      case 'fr':
        return 'Désolé, nous rencontrons des problèmes techniques. Veuillez réessayer plus tard.';
      default:
        return 'Üzgünüm, şu anda teknik bir sorun yaşıyoruz.';
    }
  }
}

/// 🔧 Firebase Cloud Function Örneği (Node.js)
/*
exports.getDialogflowToken = functions.https.onRequest(async (req, res) => {
  try {
    const { GoogleAuth } = require('google-auth-library');
    
    const auth = new GoogleAuth({
      scopes: ['https://www.googleapis.com/auth/dialogflow']
    });
    
    const accessToken = await auth.getAccessToken();
    
    res.status(200).json({ accessToken });
  } catch (error) {
    console.error('Token error:', error);
    res.status(500).json({ error: 'Token alınamadı' });
  }
});
*/