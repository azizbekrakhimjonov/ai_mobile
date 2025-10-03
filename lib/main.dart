import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'custom_http_override.dart';

void main() {
  // SSL xatosini test rejimida chetlab o'tish
  HttpOverrides.global = MyHttpOverrides();
  runApp(const ChatApiApp());
}

class ChatApiApp extends StatelessWidget {
  const ChatApiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat API',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _userIdController =
  TextEditingController(text: '12345');
  final TextEditingController _promptController = TextEditingController();
  final List<String> _messages = [];
  bool _loading = false;

  // Sizning API URL
  final String apiUrl = 'https://my.weep.uz/chat/';

  Future<void> _sendPrompt() async {
    final userId = _userIdController.text.trim();
    final prompt = _promptController.text.trim();

    if (prompt.isEmpty) return;

    setState(() {
      _loading = true;
      _messages.add('Siz: $prompt');
      _promptController.clear();
    });

    try {
      final body = jsonEncode({
        'user_id': userId,
        'prompt': prompt,
      });

      final response = await http
          .post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      )
          .timeout(const Duration(seconds: 10));

      String reply;

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map) {
            reply = decoded['reply'] ??
                decoded['response'] ??
                decoded['message'] ??
                decoded['text'] ??
                response.body;
          } else {
            reply = response.body;
          }
        } catch (_) {
          reply = response.body.isNotEmpty
              ? response.body
              : 'Server 201 qaytardi, lekin javob bo‘sh.';
        }
      } else {
        reply = 'Xato: Server ${response.statusCode} qaytardi';
      }


      setState(() {
        _messages.add('Bot: $reply');
      });
    } catch (e) {
      setState(() {
        _messages.add('Xato: $e');
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Chat'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _userIdController,
                decoration: const InputDecoration(
                  labelText: 'User ID',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final text = _messages[index];
                  final isUser = text.startsWith('Siz:');
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: isUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Colors.blue[100]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              text,
                              style: TextStyle(
                                color: isUser
                                    ? Colors.blue[900]
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promptController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendPrompt(),
                      decoration: const InputDecoration(
                        hintText: 'Savolingizni kiriting...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _loading
                      ? const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(child: CircularProgressIndicator()),
                  )
                      : IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendPrompt,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
