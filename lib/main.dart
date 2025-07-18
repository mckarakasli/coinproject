import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'register_page.dart'; // RegisterPage sayfasını import edin.

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coin Kartları',
      theme: ThemeData(useMaterial3: true),
      home: CoinSayfa(),
    );
  }
}

class CoinSayfa extends StatefulWidget {
  @override
  _CoinSayfaState createState() => _CoinSayfaState();
}

class _CoinSayfaState extends State<CoinSayfa> {
  final List<String> coinler = ['BTCUSDT', 'ETHUSDT', 'XRPUSDT', 'SOLUSDT'];
  Map<String, double> fiyatlar = {};
  Map<String, double> oncekiFiyatlar = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    verileriGetir();
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      verileriGetir();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> verileriGetir() async {
    for (String coin in coinler) {
      final uri = Uri.parse(
        'https://api.binance.com/api/v3/ticker/price?symbol=$coin',
      );
      try {
        final response = await http.get(uri);
        final Map<String, dynamic> jsonData = json.decode(response.body);
        double yeniFiyat = double.parse(jsonData['price']);

        setState(() {
          oncekiFiyatlar[coin] = fiyatlar[coin] ?? yeniFiyat;
          fiyatlar[coin] = yeniFiyat;
        });
      } catch (e) {
        print('Hata: $e');
      }
    }
  }

  Icon yukselisIkonu(String coin) {
    final eski = oncekiFiyatlar[coin];
    final yeni = fiyatlar[coin];

    if (eski == null || yeni == null) {
      return Icon(Icons.remove, color: Colors.grey);
    }

    if (yeni > eski) {
      return Icon(Icons.trending_up, color: Colors.green, size: 20);
    } else if (yeni < eski) {
      return Icon(Icons.trending_down, color: Colors.red, size: 20);
    } else {
      return Icon(Icons.remove, color: Colors.grey, size: 20);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Coin Kartları'),
        centerTitle: true,
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: Icon(Icons.login),
            onPressed: () {
              // Giriş yap sayfasına yönlendirme
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegisterPage()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.grey.shade900],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: EdgeInsets.all(12),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: coinler.map((coin) {
            final fiyat = fiyatlar[coin];
            return GestureDetector(
              onTap: () {
                if (fiyat != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CoinDetaySayfa(coinAdi: coin, fiyat: fiyat),
                    ),
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade800, Colors.grey.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 6,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        coin,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      fiyat != null
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${fiyat.toStringAsFixed(2)} \$',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(width: 6),
                                yukselisIkonu(coin),
                              ],
                            )
                          : Text(
                              'Yükleniyor...',
                              style: TextStyle(color: Colors.white54),
                            ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class CoinDetaySayfa extends StatefulWidget {
  final String coinAdi;
  final double fiyat;

  CoinDetaySayfa({required this.coinAdi, required this.fiyat});

  @override
  State<CoinDetaySayfa> createState() => _CoinDetaySayfaState();
}

class _CoinDetaySayfaState extends State<CoinDetaySayfa> {
  late TextEditingController _hedefController;
  late TextEditingController _stopLossController;
  double hedefSeviye = 0.0;
  double stopLossSeviye = 0.0;

  @override
  void initState() {
    super.initState();
    hedefSeviye = widget.fiyat;
    stopLossSeviye = widget.fiyat;

    _hedefController = TextEditingController(
      text: hedefSeviye.toStringAsFixed(2),
    );
    _stopLossController = TextEditingController(
      text: stopLossSeviye.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _hedefController.dispose();
    _stopLossController.dispose();
    super.dispose();
  }

  double hesaplaYuzdeFark() {
    double fark = hedefSeviye - widget.fiyat;
    return (fark / widget.fiyat) * 100;
  }

  double hesaplaStopLossZarari() {
    double fark = stopLossSeviye - widget.fiyat;
    return (fark / widget.fiyat) * 100;
  }

  Future<void> _veriyiIsleVeKaydet(String islemTuru) async {
    double yuzdeFark = hesaplaYuzdeFark();

    if (yuzdeFark.abs() < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kazanç oranı %5\'ten büyük olmalı.')),
      );
      return;
    }

    final veri = {
      "coin": widget.coinAdi,
      "guncel_fiyat": widget.fiyat,
      "hedef_fiyat": hedefSeviye,
      "stop_loss": stopLossSeviye,
      "kazanc_orani": yuzdeFark,
      "islem": islemTuru,
    };

    try {
      final dosya = await _jsonDosyasiniAl();
      List<dynamic> oncekiVeriler = [];

      if (await dosya.exists()) {
        final icerik = await dosya.readAsString();
        if (icerik.isNotEmpty) {
          oncekiVeriler = json.decode(icerik);
        }
      }

      oncekiVeriler.add(veri);
      await dosya.writeAsString(json.encode(oncekiVeriler));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Veri kaydedildi.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  Future<File> _jsonDosyasiniAl() async {
    // Burada dosyanın kaydedileceği yolu belirtiyoruz. C:/wamp64/www/cryptoPython dizininde dosya kaydedilecek.
    final dosyaYolu = 'C:/wamp64/www/cryptoPython/data.json';
    return File(dosyaYolu);
  }

  @override
  Widget build(BuildContext context) {
    double yuzdeFark = hesaplaYuzdeFark();
    double stopZarari = hesaplaStopLossZarari();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.coinAdi} Detay'),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: Icon(Icons.login),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegisterPage()),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            Text('Coin Adı:', style: yaziStil()),
            SizedBox(height: 6),
            Text(widget.coinAdi, style: degerStil()),
            SizedBox(height: 16),
            Text('Güncel Fiyat:', style: yaziStil()),
            SizedBox(height: 6),
            Text('${widget.fiyat.toStringAsFixed(2)} \$', style: degerStil()),
            SizedBox(height: 24),
            Text('Hedef Seviye:', style: yaziStil()),
            SizedBox(height: 8),
            TextField(
              controller: _hedefController,
              style: TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  hedefSeviye = double.tryParse(value) ?? widget.fiyat;
                });
              },
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black45,
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            Text('Stop Loss Seviyesi:', style: yaziStil()),
            SizedBox(height: 8),
            TextField(
              controller: _stopLossController,
              style: TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  stopLossSeviye = double.tryParse(value) ?? widget.fiyat;
                });
              },
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black45,
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Kazanç Oranı: %.${yuzdeFark.toStringAsFixed(2)}',
              style: yaziStil(),
            ),
            SizedBox(height: 24),
            Text(
              'Stop Loss Zararı: %.${stopZarari.toStringAsFixed(2)}',
              style: yaziStil(),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _veriyiIsleVeKaydet('Alım');
              },
              child: Text('Alım İşlemi'),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                _veriyiIsleVeKaydet('Satım');
              },
              child: Text('Satım İşlemi'),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle yaziStil() {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
  }

  TextStyle degerStil() {
    return TextStyle(fontSize: 18, color: Colors.white70);
  }
}
