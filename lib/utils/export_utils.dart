import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:path_provider/path_provider.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
// import 'package:html/html.dart' as html; // Web için gerekli, şimdilik kapalı

import '../models/customer_model.dart';
import '../models/transaction_model.dart';

class ExportUtils {
  // Müşteri listesini CSV olarak dışa aktar
  static String customersToCsv(List<CustomerModel> customers) {
    final rows = <List<String>>[
      ['ID', 'Name', 'Surname', 'Email', 'Phone', 'Label', 'CreatedAt'],
      ...customers.map((c) => [
            c.id,
            c.firstName,
            c.lastName,
            c.email,
            c.phone,
            c.tag ?? '',
            c.createdAt.toIso8601String(),
          ])
    ];
    return const ListToCsvConverter().convert(rows);
  }

  // Gelir/gider listesini CSV olarak dışa aktar
  static String transactionsToCsv(List<TransactionModel> txs) {
    final rows = <List<String>>[
      ['ID', 'UserID', 'Type', 'Category', 'Title', 'Amount', 'CreatedAt'],
      ...txs.map((t) => [
            t.id,
            t.userId,
            t.type.name,
            t.category,
            t.title,
            t.amount.toString(),
            t.createdAt.toIso8601String(),
          ])
    ];
    return const ListToCsvConverter().convert(rows);
  }

  // Müşteri listesini PDF olarak dışa aktar
  static Future<Uint8List> customersToPdf(List<CustomerModel> customers) async {
    if (!kIsWeb) {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (context) => pw.TableHelper.fromTextArray(
            headers: [
              'ID',
              'Name',
              'Surname',
              'Email',
              'Phone',
              'Label',
              'CreatedAt'
            ],
            data: customers
                .map((c) => [
                      c.id,
                      c.firstName,
                      c.lastName,
                      c.email,
                      c.phone,
                      c.tag ?? '',
                      c.createdAt.toIso8601String(),
                    ])
                .toList(),
          ),
        ),
      );
      return pdf.save();
    }
    return Future.value(Uint8List(0));
  }

  // Gelir/gider listesini PDF olarak dışa aktar
  static Future<Uint8List> transactionsToPdf(List<TransactionModel> txs) async {
    if (!kIsWeb) {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (context) => pw.TableHelper.fromTextArray(
            headers: [
              'ID',
              'UserID',
              'Type',
              'Category',
              'Title',
              'Amount',
              'CreatedAt'
            ],
            data: txs
                .map((t) => [
                      t.id,
                      t.userId,
                      t.type.name,
                      t.category,
                      t.title,
                      t.amount.toString(),
                      t.createdAt.toIso8601String(),
                    ])
                .toList(),
          ),
        ),
      );
      return pdf.save();
    }
    return Future.value(Uint8List(0));
  }

  // Tüm veriyi JSON olarak dışa aktar (backup)
  static String allDataToJson(Map<String, dynamic> allData) {
    return jsonEncode(allData);
  }

  // JSON import (backup restore)
  static Map<String, dynamic> importFromJson(String jsonStr) {
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  static Future<String> exportToPdf(
      List<Map<String, dynamic>> data, String title) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(title),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  data.first.keys.toList(),
                  ...data.map(
                      (row) => row.values.map((e) => e.toString()).toList()),
                ],
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/$title.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static Future<String> exportToCsv(
      List<Map<String, dynamic>> data, String title) async {
    final List<List<dynamic>> rows = [
      data.first.keys.toList(),
      ...data.map((row) => row.values.toList()),
    ];

    final csvData = const ListToCsvConverter().convert(rows);
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/$title.csv');
    await file.writeAsString(csvData);
    return file.path;
  }

  static Future<String> exportToExcel(
      List<Map<String, dynamic>> data, String title) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Add headers
    var headers = data.first.keys.toList();
    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(headers[i]);
    }

    // Add data rows
    for (var i = 0; i < data.length; i++) {
      var values = data[i].values.toList();
      for (var j = 0; j < values.length; j++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1))
            .value = TextCellValue(values[j].toString());
      }
    }

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/$title.xlsx');
    await file.writeAsBytes(excel.encode()!);
    return file.path;
  }
}
