class Constants {
  final bool devMode = false;
  final String _apiDevEndpoint = 'http://192.168.31.55:8000/api/v1';
  final String _apiProdEndpoint = 'https://api.kronk.uz/api/v1';

  final String _bucketDevEndpoint = 'http://192.168.31.55:9000/kronk-digitalocean-bucket';
  final String _bucketProdEndpoint = 'https://kronk-digitalocean-bucket.fra1.cdn.digitaloceanspaces.com';

  final String _websocketDevEndpoint = 'ws://192.168.31.55:8000/api/v1';
  final String _websocketProdEndpoint = 'wss://api.kronk.uz/api/v1';

  // final String clientId = '1081239849482-hjhtm79s5oq4am92htnud4vs4qanbbro.apps.googleusercontent.com';
  final String clientId = '1081239849482-f0jqc0orfs1h1737oi8fljd7rlbp6sd1.apps.googleusercontent.com';
  final serverClientId = '1081239849482-fgga7ceveli1pk9k8hlt0ru84dnjf9o2.apps.googleusercontent.com';

  String get apiEndpoint => devMode ? _apiDevEndpoint : _apiProdEndpoint;

  String get bucketEndpoint => devMode ? _bucketDevEndpoint : _bucketProdEndpoint;

  String get websocketEndpoint => devMode ? _websocketDevEndpoint : _websocketProdEndpoint;
}

final Constants constants = Constants();
