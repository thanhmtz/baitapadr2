import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bp_notepad/theme.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class AiDoctorScreen extends StatefulWidget {
  @override
  _AiDoctorScreenState createState() => _AiDoctorScreenState();
}

class _AiDoctorScreenState extends State<AiDoctorScreen> {
  final TextEditingController _questionController = TextEditingController();
  final List<Map<String, String>> _chatHistory = [];
  bool _isLoading = false;
  String _apiKey = '';
  String _model = 'openai/gpt-oss-20b';

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('ai_doctor_history');
    if (historyJson != null) {
      final List<dynamic> decoded = jsonDecode(historyJson);
      setState(() {
        _chatHistory.clear();
        for (var msg in decoded) {
          _chatHistory.add(Map<String, String>.from(msg));
        }
      });
    }
  }

  String _getTimestamp() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String _cleanResponse(String text) {
    if (text.isEmpty) return '';
    String cleaned = text.replaceAll(RegExp(r'\*\*\|---\|\*\*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\*\*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\|---\|'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\|'), '');
    cleaned = cleaned.replaceAll(RegExp(r'^\*+\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s*\*+$'), '');
    cleaned = cleaned.trim();
    return cleaned.isEmpty ? text : cleaned;
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_doctor_history', jsonEncode(_chatHistory));
  }

  @override
  void dispose() {
    _saveChatHistory();
    _questionController.dispose();
    super.dispose();
  }

  void _showMessageOptions(int index, String content) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _editMessage(index, content);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(CupertinoIcons.pencil, size: 20),
                SizedBox(width: 8),
                Text('Chỉnh sửa'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _copyMessage(content);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(CupertinoIcons.doc_on_clipboard, size: 20),
                SizedBox(width: 8),
                Text('Sao chép'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(index);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(CupertinoIcons.delete, size: 20),
                SizedBox(width: 8),
                Text('Xóa'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
      ),
    );
  }

  void _editMessage(int index, String content) {
    final controller = TextEditingController(text: content);
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Chỉnh sửa tin nhắn'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: controller,
            maxLines: 5,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              String newContent = controller.text;
              Navigator.pop(context);
              _updateAndGetResponse(index, newContent);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
    Navigator.pop(context);
  }

  void _deleteMessage(int index) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Xóa tin nhắn?'),
        content: const Text('Tin nhắn này sẽ bị xóa vĩnh viễn.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              setState(() {
                _chatHistory.removeAt(index);
              });
              _saveChatHistory();
              Navigator.pop(context);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAndGetResponse(int index, String newContent) async {
    setState(() {
      _chatHistory[index]['content'] = newContent;
      if (index + 1 < _chatHistory.length && _chatHistory[index + 1]['role'] == 'assistant') {
        _chatHistory.removeAt(index + 1);
      }
      _isLoading = true;
    });
    _saveChatHistory();

    try {
      final response = await _callOpenAI(newContent);
      setState(() {
        if (!response.contains('Invalid argument')) {
          _chatHistory.add({'role': 'assistant', 'content': _cleanResponse(response), 'time': _getTimestamp()});
        }
        _isLoading = false;
      });
      _saveChatHistory();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendQuestion() async {
    if (_questionController.text.trim().isEmpty) return;
    String userQuestion = _questionController.text;
    _questionController.clear();
    setState(() {
      _chatHistory.add({'role': 'user', 'content': userQuestion, 'time': _getTimestamp()});
      _isLoading = true;
    });

    try {
      final response = await _callOpenAI(userQuestion);
      setState(() {
        if (!response.contains('Invalid argument')) {
          _chatHistory.add({'role': 'assistant', 'content': _cleanResponse(response), 'time': _getTimestamp()});
        }
        _isLoading = false;
      });
      _saveChatHistory();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _callOpenAI(String question) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = Duration(seconds: 30);
      final request = await client.postUrl(Uri.parse('https://openrouter.ai/api/v1/chat/completions'));
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.headers.set('Authorization', 'Bearer ' + _apiKey);
      request.headers.set('HTTP-Referer', 'your-app');
      request.headers.set('X-Title', 'AI Doctor App');

      List messages = [
        {'role': 'system', 'content': 'Bạn là trợ lý y tế AI. Trả lời bằng tiếng Việt, ngắn gọn, dễ hiểu. Không chẩn đoán chắc chắn. Nếu nguy hiểm thì khuyên đi khám.'}
      ];

      for (var msg in _chatHistory) {
        if (msg['content'] != null && msg['content'].toString().isNotEmpty) {
          messages.add({'role': msg['role'].toString(), 'content': msg['content'].toString()});
        }
      }

      final body = jsonEncode({'model': _model, 'messages': messages, 'max_tokens': 300});
      request.add(utf8.encode(body));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      final data = jsonDecode(responseBody);
      if (data is Map && data.containsKey('error')) {
        return 'Lỗi API: ' + data['error']['message'].toString();
      }
      if (data is Map && data['choices'] != null && data['choices'].length > 0) {
        return _cleanResponse(data['choices'][0]['message']['content'].toString());
      }
      return 'Không có dữ liệu';
    } catch (e) {
      return 'Lỗi: ' + e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode;
    return Scaffold(
      backgroundColor: AppTheme.background(),
      appBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.surface(),
        middle: Text('Bác sĩ AI', style: TextStyle(color: AppTheme.textPrimary())),
        leading: CupertinoNavigationBarBackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _chatHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.person_crop_circle_fill, size: 80, color: isDark ? const Color(0xFF64D2FF) : const Color(0xFF00BFA5)),
                        const SizedBox(height: 16),
                        Text('Hỏi Bác sĩ AI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary())),
                        const SizedBox(height: 8),
                        Text('Hỏi về sức khỏe, bệnh tật,\nthuốc men, dinh dưỡng...', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary())),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _chatHistory.length,
                    itemBuilder: (context, index) {
                      final message = _chatHistory[index];
                      final isUser = message['role'] == 'user';
                      final timestamp = message['time'] ?? '';
                      return GestureDetector(
                        onLongPress: () => _showMessageOptions(index, message['content'] ?? ''),
                        child: Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUser ? (isDark ? const Color(0xFF64D2FF) : const Color(0xFF00BFA5)) : AppTheme.card(),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (timestamp.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(timestamp, style: TextStyle(fontSize: 10, color: isUser ? Colors.white70 : AppTheme.textSecondary())),
                                  ),
                                Text(message['content'] ?? '', style: TextStyle(color: isUser ? Colors.white : AppTheme.textPrimary())),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CupertinoActivityIndicator(),
                  const SizedBox(width: 8),
                  Text('Đang trả lời...', style: TextStyle(color: AppTheme.textSecondary())),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.surface(), border: Border(top: BorderSide(color: AppTheme.divider()))),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: _questionController,
                      placeholder: 'Nhập câu hỏi...',
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppTheme.background(), borderRadius: BorderRadius.circular(12)),
                      style: TextStyle(color: AppTheme.textPrimary()),
                      placeholderStyle: TextStyle(color: AppTheme.textSecondary()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.all(12),
                    color: isDark ? const Color(0xFF64D2FF) : const Color(0xFF00BFA5),
                    borderRadius: BorderRadius.circular(12),
                    onPressed: _isLoading ? null : _sendQuestion,
                    child: const Icon(CupertinoIcons.arrow_up_circle_fill, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}