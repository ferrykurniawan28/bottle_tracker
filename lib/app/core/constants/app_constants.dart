class AppConstants {
  static const String appName = 'Bottly';
  static const String storageKey = 'bottly_storage';
  static const String usersKey = 'users';
  static const String bottlesKey = 'bottles';
  static const String catalogKey = 'catalog_bottles';
  static const String currentUserKey = 'current_user';
  static const String adminEmail = 'admin@bottly.com';
  static const String adminPassword = 'admin123';
  static const int uniqueCodeLength = 5;
}

class URLs {
  static const String apiBaseUrl =
      'https://bottly-app.mangoground-c5d05e9e.southeastasia.azurecontainerapps.io/'; // Update this to your backend URL
  static const String loginEndpoint = '/login';
  static const String registerEndpoint = '/register';
  static const String usersEndpoint = '/users';
  static const String deleteUserEndpoint = '/users/{id}';
}
