import 'dart:typed_data';
import 'dart:math';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel;

enum ChatEventType {
  userText,
  userAudio,
  aiText,
  aiAudio,
  dropdownMessage,
  functionCall,
  turnComplete,
  turnStart,
}

class ChatEvent {
  final String id;
  final ChatEventType type;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ChatEvent({
    required this.id,
    required this.type,
    required this.content,
    required this.timestamp,
    this.metadata,
  });
}

class AiAgentSidePanal extends StatefulWidget {
  void Function()? onClosed;
  Future<GenerateContentResponse?> Function(
      List<FunctionCall>, ChatSession chat)? checkFunctionCalls;
  void Function(Usage)? onUsage;
  final List<String>? prompts;

  List<FunctionDeclaration> tools;

  AiAgentSidePanal({
    super.key,
    this.onClosed,
    this.checkFunctionCalls,
    this.onUsage,
    this.prompts,
    required this.tools,
  });

  @override
  State<AiAgentSidePanal> createState() => _AiAgentSidePanalState();
}

class _AiAgentSidePanalState extends State<AiAgentSidePanal> {
  late final GenerativeModel gemini;
  late ChatSession chat;

  List<ChatEvent> chatEvents = [];

  final ImagePicker _picker = ImagePicker();
  SpeechToText? _speechToText;
  bool _isListening = false;
  final ScrollController chatScrollController = ScrollController();
  final TextEditingController messageController = TextEditingController();

  Uint8List? selectedAttachmentsBytes;
  String? selectedAttachmentsName;
  final textMessageTool = FunctionDeclaration(
    'textMessage',
    'Send a text message in Arabic to the user explaining what you did or asking for non selectable data or respond to his inquiry etc ....',
    parameters: {
      'message': Schema.string(description: 'The message to send to the user.'),
    },
  );
  final askConfirmationTool = FunctionDeclaration(
    'askConfirmation',
    'Trigger an alert dialog to ask the user for confirmation before executing a change. Only use this tool to ask the user a yes or no question. Do not display any other text, only call this tool before an action that needs confirmation.',
    parameters: {
      'question': Schema.string(
        description:
            'The question to ask the user for their confirmation to execute a change. The answer to this question is needs to be either "yes" or "no".',
      ),
    },
  );

  final dropdownMessageTool = FunctionDeclaration(
    'dropdownMessage',
    'Send a dropdown message in Arabic to the user asking him for missing data or information that he should provide from a list to continue the process.',
    parameters: {
      'question': Schema.string(
          description:
              'The question to ask the user to select an option from a dropdown menu, mention he could also send it in a new message.'),
      'options': Schema.array(
          items: Schema.string(
              description: 'The options to display in the dropdown menu.')),
    },
  );

  @override
  void initState() {
    gemini = FirebaseAI.vertexAI().generativeModel(
      systemInstruction: Content.text('''
        You are a friendly and helpful ai agent named TechBee.your main language is arabic. Your job is to help the user
        get the best, frictionless app experience. 
        If you have access to a tool that can do what the user wants call it.
        use textMessage tool to interact with the user and give him the ai agent experience.
        Always call the dropdownMessage tool if you need data from the user that should be selected from a list.
        dont ask for the user for optionalParameters if not provided by the user.


        '''),
      //         , cheak fristif it needs confirmation ask the user for confirmation.

      model: 'gemini-2.5-flash',
      toolConfig: ToolConfig(
        functionCallingConfig: FunctionCallingConfig.any(
          [
            dropdownMessageTool,
            textMessageTool,
            // askConfirmationTool,
            ...widget.tools,
          ].map((tool) => tool.name).toSet(),
        ),
      ),
      tools: [
        Tool.functionDeclarations([
          dropdownMessageTool,
          textMessageTool,
          //askConfirmationTool,
          ...widget.tools,
        ]),
      ],
    );

    chat = gemini.startChat();

    super.initState();
    _speechToText = SpeechToText();
  }

  final FlutterTts _flutterTts = FlutterTts();

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage('ar-EG');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(1);
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Widget _buildPromptCard(String text, BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            addChatEvent(ChatEventType.userText, text);
            sendChatMessage(
              Content.text(text),
              context,
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          // Chat panel header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.smart_toy, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'TechBee',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () {
                    widget.onClosed?.call();
                  },
                  icon: Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Chat content area
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: chatEvents.isEmpty
                        ? Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.1),
                                        radius: 16,
                                        child: Icon(
                                          Icons.smart_toy_outlined,
                                          size: 18,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'مرحباً، كيف يمكنني مساعدتك؟',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 24),
                                ...(widget.prompts ??
                                        [
                                          "تقدر تساعدني بايه؟",
                                        ])
                                    .map((text) =>
                                        _buildPromptCard(text, context))
                                    .toList(),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: chatScrollController,
                            itemCount: chatEvents.length,
                            itemBuilder: (context, index) {
                              return _buildChatEventWidget(chatEvents[index]);
                            },
                          ),
                  ),

                  // Accept All button
                  if (chatEvents.any(
                    (event) =>
                        event.type == ChatEventType.functionCall &&
                        !(event.metadata?['is_accepted'] ?? false),
                  ))
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final unacceptedFunctionCalls = chatEvents
                              .where(
                                (event) =>
                                    event.type == ChatEventType.functionCall &&
                                    !(event.metadata?['is_accepted'] ?? false),
                              )
                              .map(
                                (event) => event.metadata!['functionCall']
                                    as FunctionCall,
                              )
                              .toList();

                          if (unacceptedFunctionCalls.isNotEmpty) {
                            setState(() {
                              for (var event in chatEvents) {
                                if (event.type == ChatEventType.functionCall &&
                                    !(event.metadata?['is_accepted'] ??
                                        false)) {
                                  event.metadata!['is_accepted'] = true;
                                }
                              }
                            });
                            GenerateContentResponse? response =
                                await widget.checkFunctionCalls?.call(
                              unacceptedFunctionCalls,
                              chat,
                            );
                            if (response != null) {
                              handelResponse(response);
                            }
                          }
                        },
                        icon: Icon(Icons.check_circle_outline),
                        label: Text('Accept All Pending Functions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),

                  // Image preview section
                  if (selectedAttachmentsBytes != null &&
                      (selectedAttachmentsName?.contains("image") ?? false))
                    Container(
                      margin: EdgeInsets.only(bottom: 16.0),
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.memory(
                                selectedAttachmentsBytes!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => clearSelectedAttachments(),
                            icon: Icon(Icons.close, color: Colors.red),
                          ),
                        ],
                      ),
                    ),

                  // PDF preview section
                  if (selectedAttachmentsBytes != null &&
                      (selectedAttachmentsName?.contains("pdf") ?? false))
                    Container(
                      margin: EdgeInsets.only(bottom: 16.0),
                      padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedAttachmentsName ?? 'Selected PDF',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () => clearSelectedAttachments(),
                            icon: Icon(Icons.close, color: Colors.red),
                          ),
                        ],
                      ),
                    ),

                  // Input area
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: messageController,
                              maxLines: 3,
                              minLines: 1,
                              decoration: InputDecoration(
                                hintText: 'Type your message...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _pickImage,
                            icon: Icon(Icons.image, color: Colors.blue),
                            tooltip: 'Pick Image',
                          ),
                          IconButton(
                            onPressed: _pickAttachments,
                            icon: Icon(Icons.attach_file, color: Colors.red),
                            tooltip: 'Pick Attachments',
                          ),
                          // Speech-to-text button
                          IconButton(
                            onPressed: _listenToSpeech,
                            icon: _isListening
                                ? Icon(Icons.mic, color: Colors.red)
                                : Icon(Icons.mic, color: Colors.green),
                            tooltip: 'Speak to type',
                          ),
                          Spacer(),
                          ElevatedButton.icon(
                            onPressed: () {
                              List<Part> parts = [];
                              String userMessage = '';

                              // Add text if available
                              if (messageController.text.isNotEmpty) {
                                userMessage = messageController.text;

                                parts.add(TextPart(messageController.text));
                                addChatEvent(
                                  ChatEventType.userText,
                                  userMessage,
                                  metadata: {
                                    if (selectedAttachmentsBytes != null)
                                      'fileBytes': selectedAttachmentsBytes,
                                    if (selectedAttachmentsName != null)
                                      'fileName': selectedAttachmentsName,
                                  },
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('ضيف كتابه تشرح فيها طلبك'),
                                  ),
                                );
                                return;
                              }

                              // Add image if available
                              if (selectedAttachmentsBytes != null &&
                                  (selectedAttachmentsName?.contains("image") ??
                                      false)) {
                                parts.add(
                                  InlineDataPart(
                                    'image/jpeg',
                                    selectedAttachmentsBytes!,
                                  ),
                                );
                              }

                              // Add PDF if available
                              if (selectedAttachmentsBytes != null &&
                                  (selectedAttachmentsName?.contains("pdf") ??
                                      false)) {
                                parts.add(
                                  InlineDataPart(
                                    'application/pdf',
                                    selectedAttachmentsBytes!,
                                  ),
                                );
                              }

                              if (parts.isNotEmpty) {
                                sendChatMessage(
                                  Content('user', parts),
                                  context,
                                );
                              }

                              if (_isListening) {
                                _speechToText?.stop();
                                setState(() {
                                  _isListening = false;
                                });
                              }
                              messageController.clear();
                              clearSelectedAttachments();
                              setState(() {});
                            },
                            icon: Icon(Icons.send),
                            label: Text('Send'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<GenerateContentResponse?> sendChatMessage(
    Content input,
    BuildContext context,
  ) async {
    Future.delayed(Duration(milliseconds: 100), () {
      addChatEvent(ChatEventType.aiText, "", metadata: {'isLoading': true});
    });
    try{
    final response = await chat.sendMessage(input);
    chatEvents.removeLast();
    print('response token count: ${response.usageMetadata?.totalTokenCount}');
    handelResponse(response);
  
    return response;
      }catch(e){
            chatEvents.removeLast();
            addChatEvent(ChatEventType.aiText, "error: $e");
            return null;

    }
  }

  handelResponse(GenerateContentResponse response) {
        if (response.usageMetadata != null) {
      widget.onUsage?.call(Usage(
        functionCalls: response.functionCalls.map((e) => e.name).toList(),
        count: 1,
        promptTokenCount: response.usageMetadata!.promptTokenCount!,
        candidatesTokenCount: response.usageMetadata!.candidatesTokenCount!,
        timestamp: DateTime.now(),
      ));
    }

    var functionCalls = response.functionCalls.toList();
    if (context.mounted && functionCalls.isNotEmpty) {
      print('function calls: ${functionCalls.map((e) => e.name).toList()}');
      handleFunctionCalls(context, functionCalls);
    }
  }

  handleFunctionCalls(
    BuildContext context,
    List<FunctionCall> functionCalls,
  ) async {
    for (var functionCall in functionCalls) {
      if (functionCall.name == 'textMessage') {
        String message = functionCall.args['message'] as String;
        addChatEvent(ChatEventType.aiText, message);
        // add text to speech here (message)
        // todo: Speak the message using text-to-speech
        //_speak(message);
      } else if (functionCall.name == 'askConfirmation') {
        var res = await askConfirmationCall(context, functionCall);
        if (res != null) {
          handleFunctionCalls(context, res.functionCalls.toList());
        }
      } else if (functionCall.name == 'dropdownMessage') {
        addChatEvent(ChatEventType.dropdownMessage,
            functionCall.args['question'] as String,
            metadata: {
              'options': functionCall.args['options'],
            });
      } else if (functionCall.name.contains('Info')) {
       GenerateContentResponse? response = await widget.checkFunctionCalls?.call([functionCall], chat);
       if (response != null) {
        handelResponse(response);
       }
      } else {
        addChatEvent(
          ChatEventType.functionCall,
          functionCall.name,
          metadata: {"functionCall": functionCall, 'is_accepted': false},
        );
      }
    }

    // widget.checkFunctionCalls!(functionCalls);
  }

  Future<GenerateContentResponse?> askConfirmationCall(
    BuildContext context,
    FunctionCall functionCall,
  ) async {
    var question = functionCall.args['question']! as String;

    if (context.mounted) {
      final functionResult = await askConfirmation(context, question);

      final response = await chat.sendMessage(
        functionResult
            ? Content.text('Yes, please do that.')
            : Content.text('No, thank you.'),
      );

      return response;
    }
    return null;
  }

  void clearSelectedAttachments() {
    selectedAttachmentsBytes = null;
    selectedAttachmentsName = null;
    setState(() {});
  }

  void addChatEvent(
    ChatEventType type,
    String content, {
    Map<String, dynamic>? metadata,
  }) {
    setState(() {
      chatEvents.add(
        ChatEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: type,
          content: content,
          timestamp: DateTime.now(),
          metadata: metadata,
        ),
      );
    });

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatScrollController.hasClients) {
        chatScrollController.animateTo(
          chatScrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildChatEventWidget(ChatEvent event) {
    switch (event.type) {
      case ChatEventType.userText:
        return _buildUserTextEvent(event);
      case ChatEventType.userAudio:
        return _buildUserAudioEvent(event);
      case ChatEventType.aiText:
        return _buildAiTextEvent(event);
      case ChatEventType.aiAudio:
        return _buildAiAudioEvent(event);
      case ChatEventType.functionCall:
        return _buildFunctionCallEvent(event);
      case ChatEventType.turnComplete:
        return _buildTurnEvent(event, 'Turn Complete');
      case ChatEventType.turnStart:
        return _buildTurnEvent(event, 'Turn Started');
      case ChatEventType.dropdownMessage:
        return _buildDropdownMessageEvent(event);
    }
  }

  Widget _buildDropdownMessageEvent(ChatEvent event) {
    String question = event.content;
    print('options: ${event.metadata?['options']}');
    List<String> options = (event.metadata?['options'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    String? selectedValue;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy, color: Colors.blue, size: 16),
                SizedBox(width: 4),
                Text(
                  'TechBee',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              question,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: StatefulBuilder(builder: (context, setState) {
                return Column(
                  children: [
                    DropdownButton<String>(
                      value: selectedValue,
                      isExpanded: true,
                      hint: Text('اختر من القائمة'),
                      underline: SizedBox(),
                      items: options.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedValue = newValue;
                        });
                      },
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: selectedValue == null
                          ? null
                          : () {
                              sendChatMessage(
                                Content.text(
                                    "here is the selected value:$selectedValue ,now you have the data you need,continue the task please"),
                                context,
                              );
                            },
                      child: Text('إرسال'),
                    ),
                  ],
                );
              }),
            ),
            SizedBox(height: 4),
            Text(
              _formatTime(event.timestamp),
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTextEvent(ChatEvent event) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(event.content, style: TextStyle(color: Colors.white)),
            SizedBox(height: 4),
            if (event.metadata != null &&
                event.metadata!['fileBytes'] != null &&
                (event.metadata!['fileName']?.contains("image") ?? false))
              Image.memory(event.metadata!['fileBytes'] as Uint8List),
            if (event.metadata != null &&
                event.metadata!['fileBytes'] != null &&
                (event.metadata!['fileName']?.contains("pdf") ?? false))
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      event.metadata!['fileName'] ?? 'PDF Attachment',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 4),
            Text(
              _formatTime(event.timestamp),
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAudioEvent(ChatEvent event) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(event.content, style: TextStyle(color: Colors.white)),
            SizedBox(width: 8),
            Text(
              _formatTime(event.timestamp),
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiTextEvent(ChatEvent event) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy, color: Colors.blue, size: 16),
                SizedBox(width: 4),
                Text(
                  'TechBee',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 4),
            if (event.metadata?['isLoading'] == true)
              TypingIndicator(
                showIndicator: true,
                bubbleColor: Colors.grey[300]!,
                flashingCircleDarkColor: Colors.grey[700]!,
                flashingCircleBrightColor: Colors.grey[400]!,
              )
            else
              Text(event.content),
            SizedBox(height: 4),
            Text(
              _formatTime(event.timestamp),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiAudioEvent(ChatEvent event) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.volume_up, color: Colors.blue, size: 16),
            SizedBox(width: 8),
            Text(event.content, style: TextStyle(color: Colors.blue[800])),
            SizedBox(width: 8),
            Text(
              _formatTime(event.timestamp),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunctionCallEvent(ChatEvent event) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: Colors.orange, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Function Called: ${event.content}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                    if (event.metadata != null)
                      Text(
                        'Parameters: ${event.metadata?['functionCall']?.args.toString()}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              Text(
                _formatTime(event.timestamp),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!(event.metadata?['is_accepted'] ?? false)) ...[
                TextButton.icon(
                  onPressed: () async {
                    if (event.metadata?['functionCall'] != null) {
                      setState(() {
                        event.metadata!['is_accepted'] = true;
                      });
                      GenerateContentResponse? response =
                          await widget.checkFunctionCalls?.call([
                        event.metadata!['functionCall'],
                      ], chat);
                      if (response != null) {
                        handelResponse(response);
                      }
                    }
                  },
                  icon: Icon(Icons.check, size: 16),
                  label: Text('Accept'),
                  style: TextButton.styleFrom(foregroundColor: Colors.green),
                ),
                SizedBox(width: 8),
                if (event.metadata?['functionCall'].name.contains('_'))
                  TextButton.icon(
                    onPressed: () {
                      if (event.metadata?['functionCall'] != null) {
                        FunctionCall functionCall =
                            event.metadata!['functionCall'] as FunctionCall;
                        FunctionCall newFunctionCall = FunctionCall(
                          functionCall.name + '_dialog',
                          functionCall.args,
                        );

                        widget.checkFunctionCalls
                            ?.call([newFunctionCall], chat);
                      }
                    },
                    icon: Icon(Icons.edit, size: 16),
                    label: Text('Edit'),
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                  ),
              ] else
                Text(
                  'Accepted',
                  style: TextStyle(
                    color: Colors.green,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTurnEvent(ChatEvent event, String label) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          Expanded(child: Divider()),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$label - ${_formatTime(event.timestamp)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
          Expanded(child: Divider()),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }

  Future<Uint8List?> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          selectedAttachmentsBytes = bytes;
          selectedAttachmentsName = "image_" + image.name;
        });
        return bytes;
      }
    } catch (e) {}
    return null;
  }

  Future<void> _listenToSpeech() async {
    if (_isListening) {
      await _speechToText?.stop();
      setState(() {
        _isListening = false;
      });
      return;
    }
    bool available = await _speechToText?.initialize() ?? false;
    if (available) {
      _speechToText?.listen(
        localeId: 'ar-EG',
        onResult: (result) {
          print('result: ${result.recognizedWords}');
          messageController.text = result.recognizedWords;
          setState(() {});
        },
      );
      setState(() {
        _isListening = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech recognition unavailable.')),
      );
    }
  }

  Future<void> _pickAttachments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'xlsx', 'xls'],
      );

      if (result != null) {
        final bytes = result.files.first.bytes;
        final name = result.files.first.name;
        if (bytes != null) {
          if (name.toLowerCase().endsWith('.pdf')) {
            setState(() {
              selectedAttachmentsBytes = bytes;
              selectedAttachmentsName = "pdf_" + name;
            });
          } else if (name.toLowerCase().endsWith('.xlsx') ||
              name.toLowerCase().endsWith('.xls')) {
            // Parse Excel file
            final excelFile = excel.Excel.decodeBytes(bytes);
            String excelContent = '';

            for (var table in excelFile.tables.keys) {
              excelContent += 'Sheet: $table\n';
              for (var row in excelFile.tables[table]!.rows) {
                excelContent +=
                    row.map((cell) => cell?.value.toString() ?? '').join('\t') +
                        '\n';
              }
              excelContent += '\n';
            }

            // Store the Excel content as text
            setState(() {
              messageController.text += '\nExcel Content:\n$excelContent';
            });
          }
        }
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }
}

Future<bool> askConfirmation(BuildContext context, String question) async {
  var response = await showDialog<bool>(
    context: context,
    builder: (context) {
      return Theme(
        data: Theme.of(context),
        child: AlertDialog(
          title: Text('App Manager'),
          content: Text(question),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text('Yes, please'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('No.'),
            ),
          ],
        ),
      );
    },
  );

  return response ?? false;
}

class Usage {

  final int count;

  final int promptTokenCount;
  final int candidatesTokenCount;
  final DateTime timestamp;
  final List<String> functionCalls;

  Usage({
    required this.count,
    required this.promptTokenCount,
    required this.candidatesTokenCount,
    required this.timestamp,
    required this.functionCalls,
  });

  factory Usage.fromJson(Map<String, dynamic> json) {
    return Usage(
      count: 1,
      promptTokenCount: json['promptTokenCount'],
      candidatesTokenCount: json['candidatesTokenCount'],
      timestamp: DateTime.parse(json['timestamp']),
      functionCalls: List<String>.from(json['functionCalls']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'promptTokenCount': promptTokenCount,
      'candidatesTokenCount': candidatesTokenCount,
      'timestamp': timestamp.toIso8601String(),
      'functionCalls': functionCalls,
    };
  }

  static List<Usage> dateUsageList(List<Usage> usages, DateTime startDate, DateTime endDate) {
    List<Usage> thisMonthUsages = usages
        .where((usage) => usage.timestamp.isAfter(startDate) && usage.timestamp.isBefore(endDate))
        .toList();
    return thisMonthUsages;
  }

  static Usage dateUsage(List<Usage> usages, DateTime startDate, DateTime endDate) {
    List<Usage> thisMonthUsages = dateUsageList(usages, startDate, endDate);
    return Usage(
      count: thisMonthUsages.length,
      promptTokenCount:
          thisMonthUsages.fold(0, (sum, usage) => sum + usage.promptTokenCount),
      candidatesTokenCount: thisMonthUsages.fold(
          0, (sum, usage) => sum + usage.candidatesTokenCount),
      timestamp: DateTime.now(),
      functionCalls: thisMonthUsages.fold(
          [], (sum, usage) => sum + usage.functionCalls),
    );
  }
  
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({
    super.key,
    this.showIndicator = false,
    this.bubbleColor = const Color(0xFF646b7f),
    this.flashingCircleDarkColor = const Color(0xFF333333),
    this.flashingCircleBrightColor = const Color(0xFFaec1dd),
  });

  final bool showIndicator;
  final Color bubbleColor;
  final Color flashingCircleDarkColor;
  final Color flashingCircleBrightColor;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _appearanceController;
  late Animation<double> _indicatorSpaceAnimation;
  late AnimationController _repeatingController;
  final List<Interval> _dotIntervals = const [
    Interval(0.25, 0.8),
    Interval(0.35, 0.9),
    Interval(0.45, 1.0),
  ];

  @override
  void initState() {
    super.initState();

    _appearanceController = AnimationController(
      vsync: this,
    )..addListener(() {
        setState(() {});
      });

    _indicatorSpaceAnimation = CurvedAnimation(
      parent: _appearanceController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      reverseCurve: const Interval(0.0, 1.0, curve: Curves.easeOut),
    ).drive(Tween<double>(
      begin: 0.0,
      end: 60.0,
    ));

    _repeatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.showIndicator) {
      _showIndicator();
    }
  }

  @override
  void didUpdateWidget(TypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.showIndicator != oldWidget.showIndicator) {
      if (widget.showIndicator) {
        _showIndicator();
      } else {
        _hideIndicator();
      }
    }
  }

  @override
  void dispose() {
    _appearanceController.dispose();
    _repeatingController.dispose();
    super.dispose();
  }

  void _showIndicator() {
    _appearanceController
      ..duration = const Duration(milliseconds: 750)
      ..forward();
    _repeatingController.repeat();
  }

  void _hideIndicator() {
    _appearanceController
      ..duration = const Duration(milliseconds: 150)
      ..reverse();
    _repeatingController.stop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _indicatorSpaceAnimation,
      builder: (context, child) {
        return Container(
          height: 35,
          child: Stack(
            children: [
              _buildDot(0),
              _buildDot(1),
              _buildDot(2),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDot(int index) {
    return Positioned(
      left: 8.0 + (index * 12),
      bottom: 8,
      child: AnimatedBuilder(
        animation: _repeatingController,
        builder: (context, child) {
          final circleFlashPercent = _dotIntervals[index].transform(
            _repeatingController.value,
          );
          final circleColorPercent = sin(pi * circleFlashPercent);

          return Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(
                widget.flashingCircleDarkColor,
                widget.flashingCircleBrightColor,
                circleColorPercent,
              ),
            ),
          );
        },
      ),
    );
  }
}
