import 'package:dio/dio.dart';

class ConfigService {
  static Future<bool> fetchShowSupportButtons() async {
    try {
      final response = await Dio().get('https://api.kronk.uz/show-support-buttons');
      return response.data['show_support_buttons'] == true;
    } catch (e) {
      return false;
    }
  }
}
