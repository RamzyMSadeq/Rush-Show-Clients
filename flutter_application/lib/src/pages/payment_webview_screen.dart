import 'dart:core';

import 'package:flutter/material.dart';
import 'package:markets/src/pages/payment_services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaypalPayment extends StatefulWidget {
  final price;
  final itemName;

  final Function onFinish;
  PaypalPayment({this.price, this.onFinish, this.itemName});

  @override
  State<StatefulWidget> createState() {
    return PaypalPaymentState();
  }
}

class PaypalPaymentState extends State<PaypalPayment> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String checkoutUrl;
  String executeUrl;
  String accessToken;
  PaypalServices services = PaypalServices();

  bool isEnableShipping = false;
  bool isEnableAddress = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      try {
        accessToken = await services.getAccessToken();
        print('assas $accessToken');

        final res = await services.createPayment(accessToken);
        if (res != null) {
          setState(
            () {
              checkoutUrl = res["approvalUrl"];
              print('checkoutUrlcheckoutUrl $checkoutUrl');
              executeUrl = res["executeUrl"];
            },
          );
        }
      } catch (e) {
        print('exception: ' + e.toString());
        final snackBar = SnackBar(
          content: Text(e.toString()),
          duration: Duration(seconds: 10),
          action: SnackBarAction(
            label: 'Close',
            onPressed: () {
              // Some code to undo the change.
            },
          ),
        );
        _scaffoldKey.currentState.showSnackBar(snackBar);
      }
    });
  }

  // item name, price and quantity
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    print(checkoutUrl);

    if (checkoutUrl != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).backgroundColor,
          leading: GestureDetector(
            child: Icon(Icons.arrow_back_ios),
            onTap: () => Navigator.pop(context),
          ),
        ),
        body: WebView(
          initialUrl: checkoutUrl,
          javascriptMode: JavascriptMode.unrestricted,
          navigationDelegate: (NavigationRequest request) {
            print('requestrequestrequest ${request.url}');

            final uri = Uri.parse(request.url);
            print('uriuri $uri');
            final payerID = uri.queryParameters['order_id'];
            print('payerID $payerID');

            if (payerID != null) {
              services.executePayment(payerID, accessToken).then((map) {
                // widget.onFinish(map);
                print('executePayment3 $map');
              });
            } else {
              // Navigator.of(context).pop();
            }

            // if (request.url.contains(cancelURL)) {
            //   Navigator.of(context).pop();
            // }
            return NavigationDecision.navigate;
          },
        ),
      );
    } else {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              }),
          backgroundColor: Colors.black12,
          elevation: 0.0,
        ),
        body: Center(child: Container(child: CircularProgressIndicator())),
      );
    }
  }
}
