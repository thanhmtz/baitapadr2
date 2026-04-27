import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _apiKey = 'demo';
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  String _temperature = '--';
  String _weatherIcon = 'sun';

  String get temperature => _temperature;
  String get weatherIcon => _weatherIcon;

  Future<void> fetchWeather(double lat, double lon) async {
    try {
      var url = Uri.parse('$_baseUrl?latitude=$lat&longitude=$lon&current_weather=true');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var current = data['current_weather'];
        var temp = current['temperature'].toStringAsFixed(0);
        
        setState(() {
          _temperature = '$temp°C';
          _weatherIcon = _getWeatherIcon(current['weathercode'] ?? 0);
        });
      }
    } catch (e) {
      setState(() {
        _temperature = '--°C';
        _weatherIcon = 'sun';
      });
    }
  }

  void setState(VoidCallback callback) {
    callback();
  }

  String _getWeatherIcon(int code) {
    if (code == 0) return 'sun_max';
    if (code <= 3) return 'cloud';
    if (code <= 48) return 'cloud_rain';
    if (code <= 67) return 'cloud_heavyrain';
    if (code <= 77) return 'cloud_snow';
    if (code <= 82) return 'cloud_rain';
    if (code <= 86) return 'cloud_snow';
    return 'cloud';
  }
}

typedef VoidCallback = void Function();