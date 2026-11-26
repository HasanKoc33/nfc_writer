import 'dart:developer';

class Debug {
  ///|>==|>==|> Set debug variable false when you make release build. <|==<|==<|

  static const debug = true;
  static const sandboxApiUrl = false;
  static const sandboxVerifyReceiptUrl = true;
  static const googleAd = true;

  static printLog(String tag, String str) {
    if (debug) log("$tag -->> $str");
  }
}
