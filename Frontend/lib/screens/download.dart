import 'dart:io';
import 'package:background_downloader/background_downloader.dart' hide PermissionStatus;
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:flutter/material.dart';
import 'package:pocket_llm/screens/homepage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:pocket_llm/screens/welcome.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadPage extends StatefulWidget {
    const DownloadPage({super.key, required this.downloadlink});
    final String downloadlink;

    @override
    State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  double _progress = 0.0;
  double _recieved = 0;
  double _downloadSize = 0;
  late SharedPreferences _preferences;
  late Future<void> _downloadFuture;
  late DownloadTask task;

  @override
  void initState() {
    super.initState();
    final uri = Uri.parse(widget.downloadlink);
    String filename = p.basenameWithoutExtension(uri.path); 
    _downloadFuture = _downloadFile(widget.downloadlink, filename);
  }

  @override
  void dispose() {
    _cancelDownload();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: downloadScreen(),
    );
  }

  Future<String> getAppFilePath(String filename) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    return p.join(appDocPath, filename);
  }

  Future<PermissionStatus> requestPermissions() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status;
  }

  static bool isValidPath(String str) {
    RegExp pattern = RegExp('^(?:\/)?(?:[a-zA-Z0-9 ._-]+\/[a-zA-Z0-9 ._-]+(?:\/[a-zA-Z0-9 ._-]+)*)(?:\/)?\$');
    return pattern.hasMatch(str) && str.isNotEmpty;
  }

  // If returned string doesn't match file pattern, it's an error
  Future<void> _downloadFile(String url, String filename) async {
    String path;
    _preferences = await SharedPreferences.getInstance();

    try {
      // if (Platform.isAndroid) {
      //   var status = await requestPermissions();
      //   if (status.isDenied) {
      //     return "Download permission denied. Cannot download file.";
      //   }
      //   if (status.isPermanentlyDenied) {
      //     return "Download permission permanently denied. Please enable downloads in settings";
      //   }
      // }

      path = (await getApplicationDocumentsDirectory()).path;

      if (isValidPath(path)) {
        task = DownloadTask(
          url: url,
          filename: filename,
          directory: 'models',
          updates: Updates.statusAndProgress,
          retries: 5,
        );

        _downloadSize = (await task.expectedFileSize() + 0.0)/(1<<20);
        DiskSpacePlus d = DiskSpacePlus();
        double freeStorageMB = await d.getFreeDiskSpace ?? 0.0;

        if (_downloadSize < freeStorageMB) {
            await FileDownloader().download(
              task,
              onProgress: (progress) {
                _progress = progress;
                setState(() {
                  if (progress >= 0 && _downloadSize > 0) {
                      _recieved = (progress*_downloadSize);
                  }
                });
              },
              onStatus: (status) {
                if (mounted && status == TaskStatus.canceled) {
                  Navigator.pop(context);
                } else if (mounted && status == TaskStatus.complete) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const HomePage())
                  );
                  _preferences.setBool('setupComplete', true);
                } else if (mounted && (status == TaskStatus.failed || status == TaskStatus.notFound)) {
                  showDialog(
                    context: context, 
                    builder: (BuildContext context) {
                      return errorDialog('');
                    }
                  );
                }
              }
            );
        } else {
          if (mounted) {
            showDialog(
              context: context, 
              builder: (BuildContext context) {
                return errorDialog('Not enough storage to download');
              }
            );
          }
        }
      } else {
        if (mounted) {
          showDialog(
            context: context, 
            builder: (BuildContext context) {
              return errorDialog('Invalid file path was generated.');
            }
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context, 
          builder: (BuildContext context) {
            return errorDialog('Download encountered an ${e.runtimeType} error: $e');
          }
        );
      }
    }
  }

  Future<void> _cancelDownload() async {
    if (!(await FileDownloader().tasksFinished())) {
      await FileDownloader().cancelTaskWithId(task.taskId);
    }
  }

  Widget downloadScreen() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Download',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 40
            ),
          ),
          Icon(
            Icons.download_rounded,
            color: Colors.white,
            size: screenHeight * 0.4,
          ),
          Padding(
            padding: const EdgeInsetsGeometry.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('${_recieved.toStringAsFixed(2)} mb'),
                    Text('${_downloadSize.toStringAsFixed(2)} mb')
                  ],
                ),
                Padding(
                  padding:const EdgeInsetsGeometry.only(top: 10, bottom: 30, right: 10, left: 10),
                  child: LinearProgressIndicator(
                    value: _progress
                  )
                ),
                ElevatedButton(
                  onPressed: () {
                    _cancelDownload();
                  }, 
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24
                    ),
                  )
                )
              ],
            )
          ),
        ],
      )
    );
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
                onPressed: () async {
                  await _cancelDownload();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const WelcomePage()),
                      (Route<dynamic> route) => false
                    );
                  }
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
}