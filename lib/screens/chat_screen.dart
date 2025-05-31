import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<int, bool> _expandedMessages = {}; // Track expanded state for each message

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Function to parse simple markdown and return styled text spans
  List<TextSpan> _parseMarkdownText(String text, Color textColor) {
    final List<TextSpan> spans = [];
    final lines = text.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Handle headers
      if (line.startsWith('### ')) {
        spans.add(TextSpan(
          text: line.substring(4) + '\n',
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ));
      } else if (line.startsWith('## ')) {
        spans.add(TextSpan(
          text: line.substring(3) + '\n',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ));
      } else if (line.startsWith('# ')) {
        spans.add(TextSpan(
          text: line.substring(2) + '\n',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ));
      } else {
        // Handle bold text within regular lines
        final processedLine = _processBoldText(line, textColor);
        spans.addAll(processedLine);
        if (i < lines.length - 1) {
          spans.add(TextSpan(
            text: '\n',
            style: TextStyle(color: textColor),
          ));
        }
      }
    }
    
    return spans;
  }

  List<TextSpan> _processBoldText(String text, Color textColor) {
    final List<TextSpan> spans = [];
    final RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in boldRegex.allMatches(text)) {
      // Add text before the bold part
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            height: 1.4,
          ),
        ));
      }

      // Add the bold text
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
      ));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          height: 1.4,
        ),
      ));
    }

    // If no bold text was found, return the original text
    if (spans.isEmpty) {
      spans.add(TextSpan(
        text: text,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          height: 1.4,
        ),
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prenatal Care Assistant'),
        backgroundColor: Colors.pink[300],
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          if (!provider.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.initializationError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Initialization Error: ${provider.initializationError.toString()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.retryInitialization(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.pink[50],
                child: Text(
                  'Week ${provider.pregnancyWeek} of Pregnancy',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    final message = provider.messages[index];
                    return _buildMessageBubble(context, message, index);
                  },
                ),
              ),
              if (provider.isLoading)
                LinearProgressIndicator(color: Colors.pink[300])
              else
                const SizedBox.shrink(),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Type your question...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        onSubmitted: (_) => _sendMessage(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      onPressed: () => _sendMessage(context),
                      backgroundColor: Colors.pink[300],
                      mini: true,
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message, int index) {
    final isUser = message.role == MessageRole.user;
    final isExpanded = _expandedMessages[index] ?? false;
    final shouldShowMore = !isUser && message.text.length > 500;
    
    // For long messages, show truncated version when collapsed
    String displayText = message.text;
    if (!isUser && shouldShowMore && !isExpanded) {
      displayText = message.text.substring(0, 500) + '...';
    }

    final textColor = isUser ? Colors.white : Colors.black87;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isUser ? Colors.pink[300] : Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
          minHeight: 50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isUser)
              // For user messages, use simple text
              Text(
                displayText,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  height: 1.4,
                ),
                softWrap: true,
              )
            else
              // For AI messages, use styled text with markdown parsing
              RichText(
                text: TextSpan(
                  children: _parseMarkdownText(displayText, textColor),
                ),
                softWrap: true,
              ),
            if (shouldShowMore) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _expandedMessages[index] = !isExpanded;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.pink[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isExpanded ? 'Show less' : 'More...',
                    style: TextStyle(
                      color: Colors.pink[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _sendMessage(BuildContext context) {
    final messageText = _textController.text.trim();
    if (messageText.isNotEmpty) {
      final provider = Provider.of<ChatProvider>(context, listen: false);
      provider.sendMessage(messageText).catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('API_KEY')
                  ? 'API configuration error. Please contact support.'
                  : 'Failed to send message. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      });
      _textController.clear();
    }
  }

  void _showSettings(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    final weekController =
        TextEditingController(text: provider.pregnancyWeek.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weekController,
              decoration: const InputDecoration(
                labelText: 'Pregnancy Week (1-42)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                provider.clearChat();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Clear Chat History'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final week = int.tryParse(weekController.text) ?? 1;
              provider.updatePregnancyWeek(week.clamp(1, 42));
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}