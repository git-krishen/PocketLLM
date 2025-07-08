import 'package:flutter/material.dart';
import 'package:pocket_llm/screens/download.dart';

class AlertHelper {
  static Dialog downloadChoiceDialog(BuildContext context) {
    return Dialog(
      backgroundColor: Color.fromARGB(191, 0, 0, 0),
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
                        return AlertHelper.curatedModelDialog(context);
                      }
                    );
                  }, 
                  child: Text(
                    "Choose a curated model",
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showDialog(context: context,
                      builder: (BuildContext context) {
                        return AlertHelper.customModelDialog(context);
                      }
                    );
                  },
                  child: Text(
                    "Import custom model",
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

  static Dialog curatedModelDialog(BuildContext context) {
    return Dialog(
      backgroundColor: Color.fromARGB(191, 0, 0, 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.0))
      ),
      child: SizedBox(
        height: 200,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Text(
                  "Select model to use",
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DownloadPage(downloadlink: 'asdfghjkl'))
                    );
                  }, 
                  child: Text(
                    "asdfghjkl",
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DownloadPage(downloadlink: 'qwertyuiop'))
                    );
                  },
                  child: Text(
                    "qwertyuiop",
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DownloadPage(downloadlink: 'zxcvbnm'))
                    );
                  },
                  child: Text(
                    "zxcvbnm",
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

  static Dialog customModelDialog(BuildContext context) {
    final textController = TextEditingController();
    return Dialog(
      backgroundColor: Color.fromARGB(191, 0, 0, 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.0))
      ),
      child: SizedBox(
        height: 200,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  "Import model",
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  "Enter huggingface link to a .gguf file",
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 0, bottom: 30),
                child: Expanded(
                  child: TextField(
                    controller: textController,
                    autocorrect: false,
                    style: TextStyle(
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'huggingface.co/<user>/<model>',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                      )
                    ),
                  )
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AlertHelper.inputIsValid(textController.text) ? Colors.white : Colors.grey,
                  ),
                  onPressed: () {
                    if (AlertHelper.inputIsValid(textController.text)) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DownloadPage(downloadlink: textController.text))
                      );
                    }
                  },
                  child: Text(
                    "Continue",
                    style: TextStyle(color:Colors.black),
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

  static bool inputIsValid(String str) {
    RegExp pattern = RegExp("^(https?:\/\/)?huggingface\.co\/(?=[a-zA-Z0-9-]{1,255}\/)(?![\d]+\/)[a-zA-Z0-9]+(?:-[a-zA-Z0-9]+)*\/[a-zA-Z0-9-_\.]{1,255}\$");
    return pattern.hasMatch(str);
  }  
}