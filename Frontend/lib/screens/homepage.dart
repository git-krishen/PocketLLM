import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_local_llm/flutter_local_llm.dart';
// import 'package:aub_ai/data/prompt_template.dart';
import 'package:flutter/material.dart';
// import 'package:pocket_llm/models/model_params.dart';
import 'package:pocket_llm/models/modeloption.dart';
import 'package:pocket_llm/screens/download.dart';
import 'package:pocket_llm/screens/models.dart';
import 'package:pocket_llm/screens/welcome.dart';
import 'package:flutter_local_llm/data/model_params.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
    const HomePage({super.key});

    @override
    State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _chatTextController = TextEditingController();
  final TextEditingController _downloadTextController = TextEditingController();
  late Future<List<String>> _retrievedChats;
  List<String> _chats = List<String>.empty();
  late SharedPreferences _preferences;
  var _modelToDownload;
  String _downloadLink = '';
  List _downloadedModels = List.empty();
  String _selectedModelPath = '';
  bool _userCanAsk = true;

  @override
  void initState() {
    super.initState();
    _retrievedChats = _loadSavedInfo();
  }

  @override
  void dispose() {
    super.dispose();
    _chatTextController.dispose();
    _downloadTextController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 0, 18),
        leading: IconButton(
          onPressed: () {
            // Bring up menu
            if (_userCanAsk) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return menuDialog();
                }
              );
            }
          }, 
          icon: const Icon(Icons.menu),
          color: Colors.white,
        ),
        actions: [
          IconButton(
          onPressed: () {
            if (_userCanAsk) {
              showDialog(
                context: context, 
                builder: (BuildContext context) {
                  return chooseModelDialog();
                }
              );
            }
          }, 
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 30,
          ),
          color: Colors.white,
        ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: FutureBuilder(
                future: _retrievedChats, 
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return UnconstrainedBox(
                      child: SizedBox(
                        width: screenHeight * 0.1,
                        height: screenHeight * 0.1,
                        child: const CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (_selectedModelPath.isEmpty) {
                    return const Center(
                      child: Text(
                        'Select a model from the menu in the top-right corner',
                        style: TextStyle(
                          fontSize: 24,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  } else if (_chats.isEmpty) {
                    return const Center(
                      child: Text(
                        'Ask a question to begin',
                        style: TextStyle(
                          fontSize: 24,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  } else {
                    return ListView.builder(
                      reverse: true,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        if (index<_chats.length) {
                          return chatBubble(_chats[index]);
                        }
                      }
                    );
                  }
                }
              )
            ),
            Padding(
              padding: const EdgeInsetsGeometry.only(top: 10, bottom: 30, left: 10, right: 10),
              child: TextField(
                onSubmitted: (text) async {
                  if (text.isNotEmpty && _selectedModelPath.isNotEmpty && _userCanAsk) {
                    _chats.insert(0, 'user: $text');
                    setState(() {
                      _chatTextController.clear();
                    });
                    await _getAIResponse(_selectedModelPath, text);
                  }
                },
                controller: _chatTextController,
                autocorrect: false,
                style: const TextStyle(
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _userCanAsk ? Colors.white : Colors.grey,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30))
                  ),
                  hintText: 'Enter a query',
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                  )
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<List<String>> _loadChatHistory() async {
    _preferences = await SharedPreferences.getInstance();
    List<String> history = _preferences.getStringList('chatHistory') ?? List<String>.empty(growable: true);
    _chats = history;
    return history;
  }

  Future<List<String>> _loadSavedInfo() async {
    List<String> history = await _loadChatHistory();
    _selectedModelPath = _preferences.getString('selectedModelPath') ?? '';
    return history;
  }

  Future<List> _listDownloadedModels() async {
    String directory = (await getApplicationDocumentsDirectory()).path;
    setState(() {
      _downloadedModels = Directory('$directory/models/').listSync();
    });
    return _downloadedModels;
  }

  Future<void> _getAIResponse(String modelPath, String prompt) async {
    var rng = Random();
    final modelParams = ModelParams(
      contextSize: 2048,
      randomSeedNumber: rng.nextInt(1<<32),
      temperature: 0.5,
    );

    List<String> chatHistory = _chats.length >= 2 ? _chats.sublist(1).reversed.toList() : List<String>.empty();
    _chats.insert(0, 'ai: ');
    _userCanAsk = false;

    await talkAsync(
      filePathToModel: modelPath,
      modelParams: modelParams,
      prompt: prompt,
      systemPrompt: "You are a helpful assistant. Your objective is to respond to all of the user's questions in a thorough, friendly, accurate, but concise manner.",
      chatHistory: chatHistory,
      onTokenGenerated: (String token) {
        if (mounted && _chats.isNotEmpty) {
          setState(() {
            _chats[0] += token;
          });
        }
      },
    );

    setState(() {
      _userCanAsk = true;
    });

    await _preferences.setStringList('chatHistory', _chats);
  }

  Widget chatBubble(String message) {
    // If message starts with user:, user bubble, else ai bubble
    bool isUser = message.startsWith('user: ');
    message = message.split(':').sublist(1).join(':').trim();
    return Row(
      children: [
        isUser ? const Expanded(
          flex: 1,
          child: UnconstrainedBox()
        ) : const UnconstrainedBox(),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.1,
            ),
            decoration: BoxDecoration(
              color: isUser ? Colors.blueAccent : Colors.deepPurpleAccent,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(15.0),
                topRight: const Radius.circular(15.0),
                bottomLeft: !isUser ? Radius.zero : const Radius.circular(15.0),
                bottomRight: isUser ? Radius.zero : const Radius.circular(15.0),
              ),
            ),
            child: isUser || message.isNotEmpty ? Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.0,
              ),
            ) : const UnconstrainedBox(
              child: SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          ),
        ),
        !isUser ? const Expanded(
          flex: 1,
          child: UnconstrainedBox()
        ) : const UnconstrainedBox()
      ]
    );
  }

  Dialog menuDialog() {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      alignment: Alignment.topCenter,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.0))
      ),
      child: SizedBox(
        height: 300,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context, 
                      builder: (BuildContext context) {
                        return downloadChoiceDialog();
                      }
                    );
                  },
                  child: const Text(
                    'Download models',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ModelsPage()),
                    );
                  },
                  child: const Text(
                    'Manage models',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context, 
                      builder: (BuildContext context) {
                        return confirmDeleteDialog();
                      }
                    );
                  },
                  child: const Text(
                    'Clear history',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Home',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Dialog chooseModelDialog() {
    return Dialog(
      insetPadding: const EdgeInsets.all(0),
      alignment: Alignment.topCenter,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.0))
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 100,
          maxHeight: 300
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose model to use',
                textAlign: TextAlign.center,
              ),
              Flexible(
                child: FutureBuilder(
                  future: _listDownloadedModels(), 
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return ListView.builder(
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          if(index<snapshot.data!.length) {
                            String path = snapshot.data![index].path;
                            String modelName = path.split('/').last;
                            return TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {
                                  _preferences.setString('selectedModelPath', path);
                                  _selectedModelPath = path;
                                });
                              },
                              child: Text(
                                modelName,
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                        }
                      );
                    } else {
                      return const Padding(
                        padding: EdgeInsetsGeometry.all(10), 
                        child: CircularProgressIndicator(),
                      );
                    }
                  }
                ),
              ),
            ],
          )
        ),
      ),
    );
  }

  Dialog confirmDeleteDialog() {
    return Dialog(
      alignment: Alignment.center,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20)
      ),
      child: SizedBox(
        height: 150,
        width: 300,
        child: Padding(
          padding: const EdgeInsetsGeometry.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Are you sure you want to delete your chat history?',
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: const EdgeInsetsGeometry.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsetsGeometry.only(right: 5),
                        child: ElevatedButton(
                          onPressed: () async {
                            await _preferences.setStringList('chatHistory', List<String>.empty(growable: true));
                            setState(() {
                              _chats = List<String>.empty(growable: true);
                            });
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          }, 
                          style: const ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(Colors.green)
                          ),
                          child: const Text(
                            'Yes',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsetsGeometry.only(left: 5),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          }, 
                          style: const ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(Colors.red)
                          ),
                          child: const Text(
                            'No',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
      ),
    );
  }

  Dialog downloadChoiceDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0)
      ),
      child: SizedBox(
        height: 200,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return curatedModelDialog();
                      }
                    );
                  }, 
                  child: const Text(
                    'Choose a curated model',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return customModelDialog();
                      }
                    );
                  },
                  child: const Text(
                    'Import custom model',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Dialog curatedModelDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20)
      ),
      child: SizedBox(
        height: 200,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(
                child: Text(
                  'Select model to use',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    var modelList = await getModelsFromAPI('https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF'); 
                    String link = '';
                    for (var option in modelList) {
                      String quant = option.quantization;
                      if (quant == 'Q6_K_L') {
                        link = option.downloadLink;
                      }
                    }
                    if (mounted && link.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DownloadPage(downloadlink: link))
                      );
                    }
                  }, 
                  child: const Text(
                    'Llama 3.2 3B Instruct Q6_K_L',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    var modelList = await getModelsFromAPI('https://huggingface.co/unsloth/gemma-3-4b-it-qat-GGUF'); 
                    String link = '';
                    for (var option in modelList) {
                      String quant = option.quantization;
                      if (quant == 'UD-Q4_K_XL') {
                        link = option.downloadLink;
                      }
                    }
                    if (mounted && link.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DownloadPage(downloadlink: link))
                      );
                    }
                  }, 
                  child: const Text(
                    'Gemma 3 4B IT QAT Q4_K_XL',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    var modelList = await getModelsFromAPI('https://huggingface.co/unsloth/Phi-4-mini-instruct-GGUF'); 
                    String link = '';
                    for (var option in modelList) {
                      String quant = option.quantization;
                      if (quant == 'Q5_K_M') {
                        link = option.downloadLink;
                      }
                    }
                    if (mounted && link.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DownloadPage(downloadlink: link))
                      );
                    }
                  }, 
                  child: const Text(
                    'Phi 4 Mini Instruct Q5_K_M',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Dialog customModelDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20)
      ),
      child: SizedBox(
        height: 250,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: StatefulBuilder(
            builder: (context, setState) {
              bool valid = inputIsValid(_downloadTextController.text);

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Text(
                      'Import model',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center
                    ),
                  ),
                  const Expanded(
                    flex: 2,
                    child: Text(
                      'Enter huggingface link to a .gguf file',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 0, bottom: 10),
                    // child: Expanded(
                      child: TextField(
                        onSubmitted: (text) => {
                          setState(() {
                            valid = inputIsValid(text);
                          })
                        },
                        onTapOutside: (_) => {
                          setState(() {
                            valid = inputIsValid(_downloadTextController.text);
                          })
                        },
                        controller: _downloadTextController,
                        autocorrect: false,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'huggingface.co/<user>/<model>',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                          )
                        ),
                      )
                    // ),
                  ),
                  Padding(
                    padding: const EdgeInsetsGeometry.only(bottom: 20),
                    child: FutureBuilder<List<ModelOption>>(
                      future: getModelsFromAPI(_downloadTextController.text),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text(
                            snapshot.error.toString(),
                            style: const TextStyle(
                              color: Colors.white
                            ),
                            textAlign: TextAlign.center,
                          );
                        } else if (snapshot.hasData) {
                          var a = snapshot.data;
                          debugPrint('$a');
                          return DropdownButton<ModelOption>(
                            value: _modelToDownload,
                            dropdownColor: Colors.black,
                            hint: const Text(
                              'Select quantization',
                              style: TextStyle(
                                color: Colors.white
                              ),
                            ),
                            // isExpanded: true,
                            // icon: const Icon(Icons.keyboard_arrow_down),
                            items: snapshot.data!.map((item) {
                              return DropdownMenuItem<ModelOption>(
                                value: item,
                                child: Text(
                                  item.quantization,
                                  style: const TextStyle(
                                    color: Colors.white
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _modelToDownload = value;
                                _downloadLink = snapshot.data?.firstOrNull?.downloadLink ?? '';
                              });
                            },
                          );
                        } else {
                          return const Center(child: CircularProgressIndicator());
                        }
                      },
                    )
                  ),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _downloadLink.isNotEmpty && valid ? Colors.white : const Color.fromARGB(255, 65, 65, 65),
                      ),
                      onPressed: () {
                        if (_downloadLink.isNotEmpty && inputIsValid(_downloadTextController.text)) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DownloadPage(downloadlink: _downloadLink))
                          );
                        }
                      },
                      child: const Text(
                        'Continue',
                        style: TextStyle(color:Colors.black),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                ],
              );
            }
          ),
        ),
      ),
    );
  }

  Future<List<ModelOption>> getModelsFromAPI(String modelLink) async {
    try {
      final response = await http.get(Uri.https(
        'pocket-llm.vercel.app',
        '/get-compatible-models',
        {
          'model_url' : modelLink
        }
      ));
      // Yes, this is cursed. I'm not even gonna try to excuse this one.
      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        final bodyList = json.decode(response.body) as List;
        return bodyList.map((dynamic json) {
        final map = json as Map<String, dynamic>;
          return ModelOption(
            downloadLink: map['download_link'] as String, 
            quantization: map['quantization'] as String
          );
        }).toList();
      } else {
        var error = body.values.first;
        throw CustomException('$error');
      }
    } on SocketException {
      throw const SocketException('Unable to connect. Check if you are connected to the internet.');
    } on TimeoutException {
      throw TimeoutException('Connection timed out.');
    } on FormatException {
      throw const FormatException('URL is invalid.');
    }
  }

  static bool inputIsValid(String str) {
    RegExp pattern = RegExp('^(https?:\/\/)?huggingface\.co\/(?=[a-zA-Z0-9-]{1,255}\/)(?![\d]+\/)[a-zA-Z0-9]+(?:-[a-zA-Z0-9]+)*\/[a-zA-Z0-9-_\.]{1,255}\$');
    return pattern.hasMatch(str);
  }
}