import 'package:flutter/material.dart';

class CardId extends StatelessWidget {
  const CardId({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xFFADD8E6), // Light blue background color
        body: Center(
          child: Card(
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
                    'PROVINSI ACEH\nKABUPATEN ACEH BESAR',
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
                            Text('NIK: 3305010404990003', style: TextStyle(fontWeight: FontWeight.bold,)),
                            SizedBox(height: 8),
                            buildInfoRow('nama', 'Chairullah'),
                            buildInfoRow('Tempat/tgk Lahir', 'BKJ, 04-04-2000'),
                            buildInfoRow('Jenis Kelamin', 'Laki-Laki'),
                            buildInfoRow('Gol. Darah', 'A'),
                            buildInfoRow('Alamat', 'Blangrueng'),
                            buildInfoRow('RT/RW', '-'),
                            buildInfoRow('Kel/Desa', '-'),
                            buildInfoRow('Kecamatan', 'Baitussalam'),
                            buildInfoRow('Agama', 'Islam'),
                            buildInfoRow('Status Perkawinan', 'Belum Kawin'),
                            buildInfoRow('Pekerjaan', 'Pelajar/Mahasiswa'),
                            buildInfoRow('Kewarganegaraan', 'WNI'),
                            buildInfoRow('Berlaku Hingga', 'Seumur Hidup'),
                          ],
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Container(width: 100, height: 100, color: Colors.white,),
                        // child: Image.asset(
                        //   'assets/your_image.png', // Place your image in the assets folder
                        //   width: 100,
                        //   height: 120,
                        //   fit: BoxFit.cover,
                        // ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
          SizedBox(width:90,child:Text('$label', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
          Expanded(child: Text(": $value", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
        ],
      ),
    );
  }
}