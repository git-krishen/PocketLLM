import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pocket_llm/models/modeloption.dart';
import 'package:pocket_llm/screens/download.dart';
import 'package:pocket_llm/screens/homepage.dart';
import 'package:pocket_llm/screens/welcome.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelsPage extends StatefulWidget {
  const ModelsPage({super.key});

  @override
  State<ModelsPage> createState() => _ModelsPageState();
}

class _ModelsPageState extends State<ModelsPage> {
  final TextEditingController _downloadTextController = TextEditingController();
  late SharedPreferences _preferences;
  var _modelToDownload;
  String _downloadLink = '';
  late Future<List> _downloadedModels;
 
  @override
  void initState() {
    super.initState();
    _downloadedModels = _loadInfo();
  }

  @override
  void dispose() {
    super.dispose();
    _downloadTextController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 0, 18),
        leading: IconButton(
          onPressed: () {
            // Bring up menu
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return menuDialog();
              }
            );
          }, 
          icon: const Icon(Icons.menu),
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsetsGeometry.only(left: 20, right: 20),
        child: FutureBuilder(
          future: _downloadedModels, 
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                itemBuilder: (context, index) {
                  if(index<snapshot.data!.length) {
                    String path = snapshot.data![index].path;
                    String modelName = path.split('/').last;
                    return ListTile(
                      tileColor: Colors.deepPurple,
                      leading: Text(
                        modelName,
                        style: const TextStyle(
                          color: Colors.white,
                        )
                      ),
                      trailing: IconButton(
                        onPressed: () async {
                          try {
                            final file = File(path);
                            if (await file.exists()) {
                              await file.delete();
                              _preferences.setString('selectedModelPath', '');
                              if (mounted) {
                                setState(() {
                                  _downloadedModels = _loadDownloadedModels();
                                });
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              showDialog(
                                context: context, 
                                builder: (BuildContext context) {
                                  return errorDialog('Error deleting file: $e');
                                }
                              );
                            }
                          }
                        }, 
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }
                }
              );
            } else {
              return const Center(
                child: Expanded(
                  child: Padding(
                    padding: EdgeInsetsGeometry.all(20), 
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }
          }
        ),
      ),
    );
  }

  Future<List> _loadDownloadedModels() async {
    String directory = (await getApplicationDocumentsDirectory()).path;
    var models = Directory('$directory/models/').listSync();
    return models;
  }

  Future<List> _loadInfo() async {
    var models = await _loadDownloadedModels();
    _preferences = await SharedPreferences.getInstance();
    return models;
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
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const ModelsPage()),
                      (Route<dynamic> route) => false
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
                    Navigator.pushAndRemoveUntil(
                      context, 
                      MaterialPageRoute(builder: (context) => const HomePage()), 
                      (Route<dynamic> route) => false
                    );
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
                      Navigator.of(context).pop();
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
                      Navigator.of(context).pop();
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
                      Navigator.of(context).pop();
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
                    child: Expanded(
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
                    ),
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
                          Navigator.of(context).pop();
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
      final response = await http.get(Uri.http(
        '10.0.2.2:5000',
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

  Dialog errorDialog(String errorText) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0)
      ),
      child: SizedBox(
        height: 200,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Error',
                style: TextStyle(
                  fontSize: 24
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                errorText,
                textAlign: TextAlign.center,
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                }, 
                child: const Text(
                  'Ok'
                )
              )
            ],
          ),
        ),
      ),
    );
  }

  static bool inputIsValid(String str) {
    RegExp pattern = RegExp('^(https?:\/\/)?huggingface\.co\/(?=[a-zA-Z0-9-]{1,255}\/)(?![\d]+\/)[a-zA-Z0-9]+(?:-[a-zA-Z0-9]+)*\/[a-zA-Z0-9-_\.]{1,255}\$');
    return pattern.hasMatch(str);
  }
}