import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:kimper_server/src/generated/protocol.dart';

class KimchiPremiumService {
  static final _delaySecond = 10;
  final _controller = StreamController.broadcast();
  final _receivePort = ReceivePort();

  Stream get stream => _controller.stream;

  Future<void> start() async {
    _receivePort.listen((data) => _controller.add(data));
    await Isolate.spawn(_getData, _receivePort.sendPort);
  }

  static Future<void> _getData(SendPort sendPort) async {
    while (true) {
      final upbitXrpPrice = await _getPrice(Exchange.upbit, Ticker.xrp);
      final bybitXrpPrice = await _getPrice(Exchange.bybit, Ticker.xrp);

      sendPort.send(
        KimchiPremium(
          ticker: Ticker.xrp,
          koreaExchange: Exchange.upbit,
          koreaExchangePrice: upbitXrpPrice,
          foreignExchange: Exchange.bybit,
          foreignExchangePrice: bybitXrpPrice,
          kimchiPrimeum: 0,
        ),
      );
      await Future.delayed(Duration(seconds: _delaySecond));
    }
  }

  static Future<Response> _get(Uri url) async {
    print('## get ${DateTime.now()} $url');

    final response = await Dio().getUri(url);

    return switch (response.statusCode) {
      HttpStatus.ok => response,
      _ =>
        throw '## Fetcher._get error - ${response.statusCode} ${response.statusMessage}'
    };
  }

  static Future<double> _getPrice(Exchange exchange, Ticker ticker) async {
    final url = switch (exchange) {
      Exchange.upbit => switch (ticker) {
          Ticker.xrp =>
            Uri.parse('https://api.upbit.com/v1/ticker?markets=KRW-XRP')
        },
      Exchange.bybit => switch (ticker) {
          Ticker.xrp => Uri.parse(
              'https://api.bybit.com/spot/v3/public/quote/ticker/price?symbol=XRPUSDT')
        },
    };

    final response = await _get(url);

    return switch (exchange) {
      Exchange.upbit => response.data.first['trade_price'],
      Exchange.bybit => double.parse(response.data['result']['price']),
    };
  }
}
