import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FaceRecognitionModel(),
      child: MaterialApp(
        home: FaceRecognitionScreen(),
      ),
    );
  }
}

class FaceRecognitionModel extends ChangeNotifier {
  File? _image;
  List<Map<String, dynamic>>? _predictions;
  bool _isLoading = false;
  String? _nfcId;
  String? _matchedNik;
  String? _faceNik;
  
  bool _isNfcCheckDisabled = true; // Initially disable NFC check button
  final picker = ImagePicker();

  File? get image => _image;
  List<Map<String, dynamic>>? get predictions => _predictions;
  bool get isLoading => _isLoading;
  String? get nfcId => _nfcId;
  String? get matchedNik => _matchedNik;
  //String? get _faceNik => _faceNik;
  bool get isNfcCheckDisabled => _isNfcCheckDisabled;

  FaceRecognitionModel() {
    // Initialize NFC reading when model is created
    startNfcReading();
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _image = File(pickedFile.path);
      _predictions = null;
      notifyListeners();
      await _predictFaces();
    }
  }

  Future<void> _predictFaces() async {
    if (_image == null) return;
    _isLoading = true;
    notifyListeners();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.100.10:5000/predict'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', _image!.path));
    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      _predictions = List<Map<String, dynamic>>.from(json.decode(responseData));
      
      // Extract NIK from predictions (assuming 'NIK' is the key)
      if (_predictions!.isNotEmpty) {
        _faceNik = _predictions![0]['name']; // Adjust as per your prediction structure
        _isNfcCheckDisabled = false; // Enable NFC check button
      } else {
        _faceNik = null;
        _isNfcCheckDisabled = true; // Disable NFC check button if no predictions
      }
    } else {
      print('Failed to get predictions.');
      _faceNik = null;
      _isNfcCheckDisabled = true; // Disable NFC check button on error
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> startNfcReading() async {
    if (await NfcManager.instance.isAvailable()) {
      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          String? identifier;
          if (Platform.isAndroid) {
            identifier = (
              NfcA.from(tag)?.identifier ??
              NfcB.from(tag)?.identifier ??
              NfcF.from(tag)?.identifier ??
              NfcV.from(tag)?.identifier ??
              Uint8List(0)
            ).toHexString();
          } else if (Platform.isIOS) {
            identifier = (
              FeliCa.from(tag)?.currentIDm ??
              Iso15693.from(tag)?.identifier ??
              Iso7816.from(tag)?.identifier ??
              Uint8List(0)
            ).toHexString();
          }

          _nfcId = identifier?.toUpperCase(); // Convert to uppercase
          notifyListeners();
          print('NFC ID: $_nfcId');

          // Fetch NIK from API based on NFC ID
          await fetchNikFromApi(_nfcId);
        },
      );
    } else {
      print('NFC is not available.');
    }
  }

  Future<void> fetchNikFromApi(String? nfcId) async {
    if (nfcId == null) return;

    final response = await http.get(Uri.parse('http://192.168.100.10:5000/data'));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['card_id_data'] != null) {
        final cardData = jsonData['card_id_data'][nfcId];
        if (cardData != null) {
          _matchedNik = cardData['NIK'].toString();
          _isNfcCheckDisabled = false; // Enable NFC check button once data is fetched
        } else {
          print('Card data not found for NFC ID: $nfcId');
          _matchedNik = null;
          _isNfcCheckDisabled = true; // Disable NFC check button if data not found
        }
      }
    } else {
      print('Failed to fetch data from API.');
      _matchedNik = null;
      _isNfcCheckDisabled = true; // Disable NFC check button on error
    }

    notifyListeners();
  }

  Future<void> checkNikMatch(BuildContext context) async {
    print("NIK API: ${_matchedNik}\nNIK NFC: ${_faceNik} ");
    if (_matchedNik != null && _faceNik != null) {
      // Compare _matchedNik with _nfcId data
      print("NIK API: ${_matchedNik}\nNIK NFC: ${_faceNik} ");
      if (_matchedNik == _faceNik) {
        _showAlertDialog(context, 'NIK KTP & Identifikasi Wajah Cocok');
      } else {
        _showAlertDialog(context, 'NIK KTP Tidak Cocok dengan Identifikasi wajah');
      }
    }
  }

  void _showAlertDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

}

class FaceRecognitionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('KTP Face Recognition'),
      ),
      body: Consumer<FaceRecognitionModel>(
        builder: (context, model, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                model.image == null
                    ? Text('Belum ada gambar yang dipilih')
                    : Column(
                        children: [
                          //_buildSelectedImage(model.image!),
                          SizedBox(height: 16),
                        ],
                      ),
                model.isLoading
                    ? CircularProgressIndicator()
                    : model.predictions == null
                        ? Container()
                        : Expanded(
                            child: ListView(
                              children: model.predictions!
                                  .map((pred) => CardId(
                                        nik: pred['name'] ?? '',
                                        info: pred['info'] ?? {},
                                        imageUrl: model.image!.path,
                                      ))
                                  .toList(),
                            ),
                          ),
                SizedBox(height: 16),
                Text(
                  model.matchedNik != null
                      ? 'NIK KTP: ${model.matchedNik}'
                      : 'KTP belum diidentifikasi',
                  style: TextStyle(fontSize: 18),
                ),
                ElevatedButton(
                  onPressed: model.isNfcCheckDisabled
                      ? null
                      : () {
                          model.checkNikMatch(context); // Pass context here
                        },
                  child: Text('Check kecocokan NIK Kartu & Wajah'),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<FaceRecognitionModel>().pickImage();
        },
        tooltip: 'Pick Image',
        child: Icon(Icons.add_a_photo),
      ),
    );
  }

  Widget _buildSelectedImage(File image) {
    return Container(
      margin: EdgeInsets.all(16.0),
      width: 200.0,
      height: 200.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        image: DecorationImage(
          image: FileImage(image),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class CardId extends StatelessWidget {
  final String nik;
  final Map<String, dynamic> info;
  final String imageUrl;

  const CardId({
    super.key,
    required this.nik,
    required this.info,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 122, 194, 253),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 330,
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'PROVINSI ${info['NAMA_PROP']}\nKABUPATEN ${info['NAMA_KAB']}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NIK: $nik',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      buildInfoRow('Nama', '${info['NAMA_LGKP']}'),
                      buildInfoRow(
                          'Tempat/Tgl Lahir', '${info['TMPT_LHR']} ${info['TGL_LHR']}'),
                      buildInfoRow('Jenis Kelamin', '${info['JENIS_KLMIN']}'),
                      buildInfoRow('Gol. Darah', '${info['GOL_DRH']}'),
                      buildInfoRow('Alamat', '${info['ALAMAT']}'),
                      buildInfoRow('RT/RW', '-'),
                      buildInfoRow('Kel/Desa', '${info['NAMA_KEL']}'),
                      buildInfoRow('Kecamatan', '${info['NAMA_KEC']}'),
                      buildInfoRow('Agama', '${info['AGAMA']}'),
                      buildInfoRow('Status Perkawinan', '${info['STAT_KWN']}'),
                      buildInfoRow('Pekerjaan', '${info['JENIS_PKRJN']}'),
                      buildInfoRow('Kewarganegaraan', 'WNI'),
                      buildInfoRow('Berlaku Hingga', 'SEUMUR HIDUP'),
                    ],
                  ),
                ),
                _buildSelectedImage(File(imageUrl)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
          Expanded(
            child: Text(
              ": $value",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImage(File image) {
    return Container(
      margin: EdgeInsets.all(8.0),
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        image: DecorationImage(
          image: FileImage(image),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

extension on Uint8List {
  String toHexString() {
    return this.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }
}
