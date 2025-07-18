import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

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

  // JSON'a veri kaydetme
  void veriKaydet(String alSat) {
    double yuzdeFark = hesaplaYuzdeFark();
    print("bastım");
    if (yuzdeFark < 5) {
      // Yüzde fark 5'ten azsa uyarı ver
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yüzdesel fark %5\'ten yüksek olmalı!')),
      );
      return;
    }

    // JSON'a veri kaydet
    Map<String, dynamic> coinData = {
      'coinAdi': widget.coinAdi,
      'gunlukFiyat': widget.fiyat,
      'hedefFiyat': hedefSeviye,
      'stopLossFiyat': stopLossSeviye,
      'kazancOrani': yuzdeFark,
      'alSat': alSat,
    };

    // JSON dosyasına veri ekle
    File file = File('data.json');
    List<dynamic> coinList = [];

    if (file.existsSync()) {
      String jsonData = file.readAsStringSync();
      coinList = jsonDecode(jsonData);
    }

    coinList.add(coinData);

    String updatedJsonData = jsonEncode(coinList);

    // JSON dosyasına yazma
    file.writeAsStringSync(updatedJsonData);

    // İşlem tamamlandığında kullanıcıya bilgi ver
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$alSat işlemi başarıyla kaydedildi!')),
    );

    // Konsola yazdırarak verilerin kaydedilip kaydedilmediğini kontrol et
    print('Veri kaydedildi: $coinData');
  }

  @override
  Widget build(BuildContext context) {
    double yuzdeFark = hesaplaYuzdeFark();
    double stopZarari = hesaplaStopLossZarari();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.coinAdi} Detay'),
        backgroundColor: Colors.black87,
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
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Hedef fiyat giriniz',
                hintStyle: TextStyle(color: Colors.white38),
              ),
              onChanged: (deger) {
                setState(() {
                  hedefSeviye = double.tryParse(deger) ?? widget.fiyat;
                });
              },
            ),
            SizedBox(height: 24),
            Text('Stop-Loss:', style: yaziStil()),
            SizedBox(height: 8),
            TextField(
              controller: _stopLossController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Stop-loss fiyatını giriniz',
                hintStyle: TextStyle(color: Colors.white38),
              ),
              onChanged: (deger) {
                setState(() {
                  stopLossSeviye = double.tryParse(deger) ?? widget.fiyat;
                });
              },
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    veriKaydet('Al');
                  },
                  child: Text('Al'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: Size(150, 50),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    veriKaydet('Sat');
                  },
                  child: Text('Sat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: Size(150, 50),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),
            Text(
              'Hedef Seviye: ${hedefSeviye.toStringAsFixed(2)} \$',
              style: yaziStil(),
            ),
            SizedBox(height: 12),
            Text(
              'Yüzdesel Fark: ${yuzdeFark.toStringAsFixed(2)}%',
              style: TextStyle(color: Colors.amber, fontSize: 18),
            ),
            SizedBox(height: 24),
            Text(
              'Stop-Loss Fiyatı: ${stopLossSeviye.toStringAsFixed(2)} \$',
              style: yaziStil(),
            ),
            SizedBox(height: 12),
            Text(
              'Stop Zarar Oranı: ${stopZarari.toStringAsFixed(2)}%',
              style: TextStyle(color: Colors.red, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle yaziStil() => TextStyle(color: Colors.white70, fontSize: 16);
  TextStyle degerStil() =>
      TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold);
}
