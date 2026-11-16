import 'package:checklist_app/services/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('heart animation defaults off and persists its hidden setting',
      () async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore();

    expect(await store.loadHeartAnimationEnabled(), isFalse);

    await store.saveHeartAnimationEnabled(true);
    expect(await store.loadHeartAnimationEnabled(), isTrue);

    await store.saveHeartAnimationEnabled(false);
    expect(await store.loadHeartAnimationEnabled(), isFalse);
  });
}
