import 'package:dio/dio.dart';
import 'package:kronk/utility/constants.dart';

class ConfigService {
  static Future<bool> fetchShowSupportButtons() async {
    try {
      final response = await Dio().get('${constants.apiEndpoint}/show-support-buttons');
      return response.data['show_support_buttons'] as bool;
    } catch (e) {
      return false;
    }
  }
}
