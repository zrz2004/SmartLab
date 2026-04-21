import 'package:flutter_test/flutter_test.dart';
import 'package:smart_lab/core/models/ai_inspection_record.dart';

void main() {
  test('fallback AI inspection record is generated', () {
    final record = AiInspectionRecord.fallback(
      labId: 'lab_yuanlou_806',
      sceneType: 'window',
      deviceType: 'window_sensor',
    );

    expect(record.labId, 'lab_yuanlou_806');
    expect(record.sceneType, 'window');
    expect(record.deviceType, 'window_sensor');
    expect(record.reviewStatus, 'pending_review');
  });
}
