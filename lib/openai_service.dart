import 'dart:convert';
import 'package:http/http.dart' as http;

const String OPENAI_API_KEY = 'sk-proj-Hd5xCt433FlgcffSW1yvuAEiW_pT'; 

Future<String> fetchOpenAIResponse(String userMessage) async {
  const endpoint = 'https://api.openai.com/v1/chat/completions';

  final response = await http.post(
    Uri.parse(endpoint),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $OPENAI_API_KEY',
    },
    body: jsonEncode({
      "model": "gpt-3.5-turbo",
      "messages": [
        {
          "role": "system",
          "content":
              "You are BloomMama, a friendly and knowledgeable assistant for pregnant women. Answer questions about prenatal care, offer weekly tips, and provide safe health advice."
        },
        {"role": "user", "content": userMessage},
      ],
      "max_tokens": 300,
      "temperature": 0.7,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'];
  } else {
    return "Sorry, I couldn't get a response. Please try again later.";
  }
}
