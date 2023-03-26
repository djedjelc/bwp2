import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

bool isConnected = false;

class PageDuSite extends StatefulWidget {
  const PageDuSite({super.key});

  @override
  State<PageDuSite> createState() => _PageDuSiteState();
}

class _PageDuSiteState extends State<PageDuSite> {
  void checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      setState(() {
        isConnected = true;
      });
    } else {
      setState(() {
        isConnected = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    checkConnectivity();
  }

  late WebViewController _webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Plus d\'options'),
          backgroundColor: Colors.red,
        ),
        body: Stack(
          children: [
            Offstage(
              offstage: isConnected,
              child: Center(
                child: Text('Pas de connexion internet'),
              ),
            ),
            Offstage(
              offstage: !isConnected,
              child: WillPopScope(
                onWillPop: () async {
                  if(await _webViewController.canGoBack()){
                    _webViewController.goBack();
                    return false;
                  } else {
                    return true;
                  }
                },
                child: WebView(
                  initialUrl: ('https://mobileapp.biowinpharma.com/'),
                  javascriptMode: JavascriptMode.unrestricted,
                  onWebViewCreated: (WebViewController controller) {
                    _webViewController = controller;
                  },
                ),
              ),
            ),
          ],
        ));
  }
}
