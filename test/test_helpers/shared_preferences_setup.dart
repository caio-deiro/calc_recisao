import 'package:shared_preferences/shared_preferences.dart';
import '../mocks/shared_preferences_mock.dart';

class SharedPreferencesTestSetup {
  static MockSharedPreferences? _mockInstance;

  static void setupMock() {
    _mockInstance = MockSharedPreferences();
    SharedPreferences.setMockInitialValues({});
  }

  static void tearDown() {
    _mockInstance?.clearStorage();
    _mockInstance = null;
  }

  static MockSharedPreferences get mockInstance {
    if (_mockInstance == null) {
      setupMock();
    }
    return _mockInstance!;
  }
}
