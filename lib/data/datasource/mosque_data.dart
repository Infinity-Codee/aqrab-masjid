import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/mosque_model.dart';

class MosqueDataSource {
  Future<List<MosqueModel>> loadMosques() async {
    final raw = await rootBundle.loadString('assets/data/mosques.json');
    final decoded = json.decode(raw);
    if (decoded is! List) {
      throw Exception('بيانات الجوامع غير صالحة.');
    }

    return decoded
        .map((item) => MosqueModel.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}
