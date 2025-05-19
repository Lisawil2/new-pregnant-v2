import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LlmService {
  final String? apiKey;

  LlmService() : apiKey = dotenv.env['API_KEY'] {
    if (!dotenv.isInitialized) {
      throw Exception('DotEnv not initialized. Ensure dotenv.load() is called before creating LlmService.');
    }
    if (apiKey == null || apiKey!.isEmpty) {
      print('Warning: API_KEY is missing or empty in .env file');
    } else {
      print('LlmService initialized with API_KEY: ${apiKey!.substring(0, 4)}...');
    }
  }

  Future<String> sendMessage(String text, int week) async {
    try {
      if (apiKey == null || apiKey!.isEmpty) {
        throw Exception('API_KEY not configured. Please check your .env file.');
      }

      const String endpoint = 'https://api.openai.com/v1/chat/completions';

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {
              "role": "system",
              "content": "You are BloomMama, a friendly and knowledgeable assistant for pregnant women. Provide accurate and safe advice about prenatal care, tailored to the user's current pregnancy week (week $week). Offer weekly tips and answer questions clearly and empathetically."
            },
            {"role": "user", "content": text},
          ],
          "max_tokens": 300,
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        throw Exception('OpenAI API error: $errorMessage (Status: ${response.statusCode})');
      }
    } catch (e, stackTrace) {
      print('Error in LlmService.sendMessage: $e\n$stackTrace');
      rethrow;
    }
  }
}