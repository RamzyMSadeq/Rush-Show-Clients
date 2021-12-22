import 'package:dio/dio.dart';
import 'dart:convert' as convert;

class PaypalServices {
  // String domainSandBox = "https://dev.ipay.ge/opay/api/v1";
  String domainLive = "https://ipay.ge/opay/api/v1";

  // String clientIdSandBox = '1006';
  // String secretSandBox = '581ba5eeadd657c8ccddc74c839bd3ad';
  String clientId = '9620';
  String secret = '00c6e154289a88c41e64ebdf634102ca';

  Future<String> getAccessToken() async {
    try {
      String basicAuth = 'Basic ' +
          convert.base64Encode(convert.utf8.encode('$clientId:$secret'));
      Response response = await Dio().post(
        domainLive + '/oauth2/token',
        data: {
          'grant_type': 'client_credentials',
        },
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Authorization': basicAuth,
          },
          validateStatus: (status) => status < 500,
        ),
      );
      if (response.statusCode == 200) {
        final body = response.data;

        print('getAccessToken $body');
        return body["access_token"];
      }
      print('getAccessToken ${response.data}');
      return null;
    } catch (e) {
      rethrow;
    }
  }

  createPayment(accessToken) async {
    try {
      print('accessToken $accessToken');
      Response response = await Dio().post(
        domainLive + '/checkout/orders',
        data: {
          // "intent": "CAPTURE",
          "intent": "AUTHORIZE",
          // "external_transaction": true,
          "redirect_url": "https://san3h.com/success",
          "shop_order_id": "1231231234",
          "locale": "en-US",
          "capture_method": "AUTOMATIC",
          "purchase_units": [
            {
              "amount": {"currency_code": "GEL", "value": "0.1"},
              // "industry_type": "ECOMMERCE"
            }
          ],
          "items": [
            {
              "amount": "0.1",
              "description": "test_product",
              "product_id": 123457,
              "quantity": 1
            }
          ]
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + accessToken
          },
          validateStatus: (status) => status < 500,
        ),
      );
      final body = response.data;
      print('createPayment ${response.data}');
      if (response.statusCode == 200) {
        if (body["links"] != null && body["links"].length > 0) {
          List links = body["links"];

          String executeUrl = "";
          String approvalUrl = "";
          final item = links.firstWhere((o) => o["rel"] == "approve",
              orElse: () => null);
          if (item != null) {
            approvalUrl = item["href"];
          }
          final item1 =
              links.firstWhere((o) => o["rel"] == "self", orElse: () => null);
          if (item1 != null) {
            executeUrl = item1["href"];
          }
          return {"executeUrl": executeUrl, "approvalUrl": approvalUrl};
        }
        return null;
      } else {
        throw Exception(body["message"]);
      }
    } catch (e) {
      print('createPayment $e');
    }
  }

  Future<Map> executePayment(orderId, accessToken) async {
    try {
      var response = await Dio().get(
        domainLive + '/checkout/payment/$orderId',
        options: Options(
          headers: {
            "content-type": "application/json",
            'Authorization': 'Bearer ' + accessToken
          },
        ),
      );

      print('executePayment ${response.data}');
      print('executePayment2 ${response.statusCode}');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return null;
      }
    } catch (e) {
      print('executePayment $e');
      rethrow;
    }
  }
}
