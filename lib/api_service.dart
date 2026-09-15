import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _webhookUrl = 'https://n8n-myxz.srv1923337.hstgr.cloud/webhook/phishing-analysis';

  static Future<String> analyzeText(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['output'] ?? 'No se recibió un análisis válido.';
      } else {
        return 'Error del servidor: HTTP ${response.statusCode}';
      }
    } catch (e) {
      return 'Error de conexión: No se pudo contactar al agente de seguridad.';
    }
  }
}