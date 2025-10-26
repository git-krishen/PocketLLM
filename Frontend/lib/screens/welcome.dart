import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pocket_llm/models/modeloption.dart';
import 'package:pocket_llm/screens/download.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class WelcomePage extends StatefulWidget {
    const WelcomePage({super.key});

    @override
    State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late final TextEditingController _textController = TextEditingController();
  var _selectedModel;
  String _downloadLink = '';

    @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

    @override
    Widget build(BuildContext context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      return Scaffold(
          body: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                      Text(
                          'Download a model', 
                          style: GoogleFonts.lexendDeca(
                              color: Colors.white,
                              fontSize: 40,
                          )
                      ),
                      Image(
                        image: const AssetImage('assets/PocketLLM.png'),
                        width: screenHeight * 0.5,
                        height: screenHeight * 0.5,
                      ),
                      ElevatedButton(
                          onPressed: () {
                              showDialog(
                                context: context,
                                barrierColor: Colors.black.withAlpha(200),
                                builder: (BuildContext context) {
                                  return downloadChoiceDialog();
                                }
                              );
                          }, 
                          child: Text(
                          'Get Started', 
                          style: GoogleFonts.lexendDeca(
                              color: Colors.black,
                              fontSize: 32,
                          )),
                      )
                  ],
              ),
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
              bool valid = inputIsValid(_textController.text);

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
                            valid = inputIsValid(_textController.text);
                          })
                        },
                        controller: _textController,
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
                      future: getModelsFromAPI(_textController.text),
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
                            value: _selectedModel,
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
                                _selectedModel = value;
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
                        if (_downloadLink.isNotEmpty && inputIsValid(_textController.text)) {
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

class CustomException implements Exception {
  String cause;
  CustomException(this.cause);

  @override
  String toString() {
    return cause;
  }
}


