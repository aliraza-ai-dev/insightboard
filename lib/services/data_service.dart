import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xl;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/all_models.dart';

class DataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // ==========================================
  // CSV/Excel Parsing
  // ==========================================
  Future<ParsedData> parseCSV(Uint8List bytes, String fileName) async {
    final csvString = utf8.decode(bytes);
    final rows = const CsvToListConverter().convert(csvString);
    if (rows.isEmpty) throw Exception('Empty CSV file');

    final headers = rows[0].map((e) => e.toString().trim()).toList();
    final dataRows = rows.sublist(1);
    final types = _detectColumnTypes(headers, dataRows);

    return ParsedData(
      headers: headers,
      rows: dataRows,
      columnTypes: types,
      fileName: fileName,
    );
  }

  Future<ParsedData> parseExcel(Uint8List bytes, String fileName) async {
    final excel = xl.Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first]!;

    if (sheet.rows.isEmpty) throw Exception('Empty Excel file');

    final headers = sheet.rows[0]
        .map((cell) => cell?.value?.toString().trim() ?? '')
        .toList();
    final dataRows = sheet.rows.sublist(1).map((row) {
      return row.map((cell) => cell?.value ?? '').toList();
    }).toList();
    final types = _detectColumnTypes(headers, dataRows);

    return ParsedData(
      headers: headers,
      rows: dataRows,
      columnTypes: types,
      fileName: fileName,
    );
  }

  List<String> _detectColumnTypes(List<String> headers, List<List<dynamic>> rows) {
    return List.generate(headers.length, (col) {
      int numCount = 0, dateCount = 0, total = 0;
      for (final row in rows) {
        if (col >= row.length) continue;
        final val = row[col].toString().trim();
        if (val.isEmpty) continue;
        total++;
        if (double.tryParse(val.replaceAll(',', '')) != null) numCount++;
        if (_isDate(val)) dateCount++;
      }
      if (total == 0) return 'text';
      if (numCount / total > 0.7) return 'numeric';
      if (dateCount / total > 0.7) return 'date';
      return 'text';
    });
  }

  bool _isDate(String val) {
    final patterns = [
      RegExp(r'^\d{4}[-/]\d{1,2}[-/]\d{1,2}$'),
      RegExp(r'^\d{1,2}[-/]\d{1,2}[-/]\d{2,4}$'),
      RegExp(r'^\d{1,2}\s\w+\s\d{4}$'),
    ];
    return patterns.any((p) => p.hasMatch(val));
  }

  // ==========================================
  // Save dataset to Firestore
  // ==========================================
  Future<DatasetModel> saveDataset({
    required ParsedData data,
    required String workspaceId,
    required String userId,
    required Uint8List fileBytes,
  }) async {
    final id = _uuid.v4();
    // Upload raw file
    final ref = _storage.ref('datasets/$workspaceId/$id/${data.fileName}');
    await ref.putData(fileBytes);
    final fileUrl = await ref.getDownloadURL();

    // Store data rows in sub-collection for querying
    final batch = _db.batch();
    final datasetRef = _db.collection('datasets').doc(id);

    final dataset = DatasetModel(
      id: id,
      name: data.fileName,
      workspaceId: workspaceId,
      uploadedBy: userId,
      uploadedAt: DateTime.now(),
      rowCount: data.rows.length,
      colCount: data.headers.length,
      columns: data.headers,
      columnTypes: data.columnTypes,
      fileUrl: fileUrl,
      sourceType: data.fileName.endsWith('.csv') ? 'csv' : 'excel',
    );
    batch.set(datasetRef, dataset.toMap());

    // Store rows in chunks (max 500 per doc for Firestore limits)
    const chunkSize = 200;
    for (int i = 0; i < data.rows.length; i += chunkSize) {
      final end = (i + chunkSize > data.rows.length) ? data.rows.length : i + chunkSize;
      final chunk = data.rows.sublist(i, end);
      final chunkDoc = datasetRef.collection('data').doc('chunk_${i ~/ chunkSize}');
      batch.set(chunkDoc, {
        'rows': chunk.map((row) {
          final map = <String, dynamic>{};
          for (int j = 0; j < data.headers.length && j < row.length; j++) {
            map[data.headers[j]] = row[j];
          }
          return map;
        }).toList(),
        'startIndex': i,
        'endIndex': end,
      });
    }
    await batch.commit();
    return dataset;
  }

  // ==========================================
  // Get dataset data
  // ==========================================
  Future<List<Map<String, dynamic>>> getDatasetRows(String datasetId) async {
    final chunks = await _db
        .collection('datasets').doc(datasetId)
        .collection('data')
        .get();

    final allRows = <Map<String, dynamic>>[];
    // Sort chunks by startIndex
    final sortedDocs = chunks.docs.toList()
      ..sort((a, b) => (a.data()['startIndex'] as int)
          .compareTo(b.data()['startIndex'] as int));

    for (final doc in sortedDocs) {
      final rows = (doc.data()['rows'] as List<dynamic>)
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
      allRows.addAll(rows);
    }
    return allRows;
  }

  Stream<List<DatasetModel>> getWorkspaceDatasets(String workspaceId) {
    return _db.collection('datasets')
        .where('workspaceId', isEqualTo: workspaceId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => DatasetModel.fromMap(d.data(), d.id))
            .toList()
          ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt)));
  }

  Future<void> deleteDataset(String datasetId) async {
    // Delete data chunks
    final chunks = await _db
        .collection('datasets').doc(datasetId)
        .collection('data').get();
    for (final doc in chunks.docs) {
      await doc.reference.delete();
    }
    await _db.collection('datasets').doc(datasetId).delete();
  }

  // ==========================================
  // Data Aggregation
  // ==========================================
  Map<String, double> aggregateData({
    required List<Map<String, dynamic>> rows,
    required String groupBy,
    required String valueColumn,
    required String aggregation,
  }) {
    final groups = <String, List<double>>{};
    for (final row in rows) {
      final key = row[groupBy]?.toString() ?? 'Unknown';
      final val = double.tryParse(
          row[valueColumn]?.toString().replaceAll(',', '') ?? '') ?? 0;
      groups.putIfAbsent(key, () => []).add(val);
    }

    return groups.map((key, values) {
      double result;
      switch (aggregation) {
        case 'sum':
          result = values.fold(0, (a, b) => a + b);
          break;
        case 'avg':
          result = values.fold(0.0, (a, b) => a + b) / values.length;
          break;
        case 'count':
          result = values.length.toDouble();
          break;
        case 'min':
          result = values.reduce((a, b) => a < b ? a : b);
          break;
        case 'max':
          result = values.reduce((a, b) => a > b ? a : b);
          break;
        default:
          result = values.fold(0, (a, b) => a + b);
      }
      return MapEntry(key, result);
    });
  }

  List<double> getColumnValues(List<Map<String, dynamic>> rows, String column) {
    return rows
        .map((r) => double.tryParse(r[column]?.toString().replaceAll(',', '') ?? '') ?? 0)
        .toList();
  }

  // ==========================================
  // Sample Data Generation
  // ==========================================
  ParsedData generateSampleSalesData() {
    final headers = ['Month', 'Revenue', 'Expenses', 'Profit', 'Customers', 'Region'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final regions = ['North', 'South', 'East', 'West'];
    final rows = <List<dynamic>>[];

    for (final month in months) {
      for (final region in regions) {
        final revenue = 50000 + (months.indexOf(month) * 5000) +
            (regions.indexOf(region) * 3000) +
            (DateTime.now().millisecond % 10000);
        final expenses = revenue * 0.6 + (DateTime.now().microsecond % 5000);
        rows.add([
          month, revenue.round(), expenses.round(),
          (revenue - expenses).round(),
          100 + (months.indexOf(month) * 15) + (DateTime.now().millisecond % 50),
          region,
        ]);
      }
    }
    return ParsedData(
      headers: headers,
      rows: rows,
      columnTypes: ['text', 'numeric', 'numeric', 'numeric', 'numeric', 'text'],
      fileName: 'sample_sales_data.csv',
    );
  }

  ParsedData generateSampleWebAnalytics() {
    final headers = ['Date', 'Page Views', 'Unique Visitors', 'Bounce Rate',
                     'Avg Session', 'Conversions', 'Source'];
    final sources = ['Organic', 'Paid', 'Social', 'Direct', 'Referral'];
    final rows = <List<dynamic>>[];
    final now = DateTime.now();

    for (int d = 30; d >= 0; d--) {
      final date = now.subtract(Duration(days: d));
      for (final source in sources) {
        final pageViews = 1000 + (30 - d) * 50 + (date.day * 37 % 500);
        rows.add([
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          pageViews,
          (pageViews * 0.7).round(),
          (35 + (date.day % 20)).toStringAsFixed(1),
          '${2 + (date.day % 5)}:${(date.day * 7 % 60).toString().padLeft(2, '0')}',
          (pageViews * 0.03).round(),
          source,
        ]);
      }
    }
    return ParsedData(
      headers: headers,
      rows: rows,
      columnTypes: ['date', 'numeric', 'numeric', 'numeric', 'text', 'numeric', 'text'],
      fileName: 'sample_web_analytics.csv',
    );
  }
}

class ParsedData {
  final List<String> headers;
  final List<List<dynamic>> rows;
  final List<String> columnTypes;
  final String fileName;

  ParsedData({
    required this.headers,
    required this.rows,
    required this.columnTypes,
    required this.fileName,
  });

  String toCSV() {
    final buffer = StringBuffer();
    buffer.writeln(headers.join(','));
    for (final row in rows) {
      buffer.writeln(row.map((v) => '"$v"').join(','));
    }
    return buffer.toString();
  }

  Map<String, dynamic> getSummary() {
    final summary = <String, dynamic>{};
    for (int i = 0; i < headers.length; i++) {
      if (columnTypes[i] == 'numeric') {
        final values = rows
            .map((r) => double.tryParse(r[i].toString().replaceAll(',', '')) ?? 0)
            .toList();
        values.sort();
        summary[headers[i]] = {
          'min': values.first,
          'max': values.last,
          'avg': values.fold(0.0, (a, b) => a + b) / values.length,
          'sum': values.fold(0.0, (a, b) => a + b),
          'count': values.length,
        };
      } else {
        final unique = rows.map((r) => r[i].toString()).toSet();
        summary[headers[i]] = {
          'unique_values': unique.length,
          'top_values': unique.take(10).toList(),
        };
      }
    }
    return summary;
  }
}
