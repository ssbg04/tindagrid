import 'package:flutter_test/flutter_test.dart';
import 'package:tindagrid/core/utils/feedback_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FeedbackHelper Audio & Haptic Feedback Tests', () {
    test('Triggering success feedback runs without throwing exceptions', () async {
      // In headless unit test environments, vibration and audioplayers must fail-soft
      // without crashing the application.
      await expectLater(FeedbackHelper.triggerSuccessFeedback(), completes);
    });

    test('Triggering failure feedback runs without throwing exceptions', () async {
      await expectLater(FeedbackHelper.triggerFailureFeedback(), completes);
    });
  });
}
