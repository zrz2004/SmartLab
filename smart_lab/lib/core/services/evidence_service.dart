import 'package:image_picker/image_picker.dart';

import '../constants/ai_model_config.dart';
import '../models/ai_inspection_record.dart';
import 'api_service.dart';
import 'local_storage_service.dart';

class EvidenceSubmissionResult {
  final AiInspectionRecord? inspection;
  final bool queued;
  final String message;

  const EvidenceSubmissionResult({
    required this.inspection,
    required this.queued,
    required this.message,
  });
}

class EvidenceService {
  final ApiService apiService;
  final LocalStorageService localStorageService;
  final ImagePicker _picker = ImagePicker();

  EvidenceService({
    required this.apiService,
    required this.localStorageService,
  });

  Future<EvidenceSubmissionResult?> captureAndInspect({
    required String labId,
    required String sceneType,
    required String deviceType,
    String? targetId,
  }) async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
      maxWidth: 1920,
    );
    if (file == null) return null;
    return _submitFile(
      file: file,
      labId: labId,
      sceneType: sceneType,
      deviceType: deviceType,
      targetId: targetId,
    );
  }

  Future<EvidenceSubmissionResult?> uploadAndInspect({
    required String labId,
    required String sceneType,
    required String deviceType,
    String? targetId,
  }) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1920,
    );
    if (file == null) return null;
    return _submitFile(
      file: file,
      labId: labId,
      sceneType: sceneType,
      deviceType: deviceType,
      targetId: targetId,
    );
  }

  Future<AiInspectionRecord?> getLatestInspection({
    required String labId,
    required String sceneType,
    required String deviceType,
    String? targetId,
  }) async {
    final cached = localStorageService.getLatestInspection(
      _buildCacheKey(
        labId: labId,
        sceneType: sceneType,
        deviceType: deviceType,
        targetId: targetId,
      ),
    );
    if (cached == null) return null;
    return AiInspectionRecord.fromJson(cached);
  }

  Future<int> retryPendingUploads() async {
    final pending = localStorageService.getPendingUploads();
    if (pending.isEmpty) return 0;

    final remaining = <Map<String, dynamic>>[];
    var successCount = 0;

    for (final item in pending) {
      try {
        final file = XFile(item['file_path'] as String);
        final result = await _submitFile(
          file: file,
          labId: item['lab_id'] as String,
          sceneType: item['scene_type'] as String,
          deviceType: item['device_type'] as String,
          targetId: item['target_id'] as String?,
          allowQueue: false,
        );
        if (result.inspection != null) {
          successCount += 1;
        }
      } catch (_) {
        remaining.add(item);
      }
    }

    await localStorageService.replacePendingUploads(remaining);
    return successCount;
  }

  Future<EvidenceSubmissionResult> _submitFile({
    required XFile file,
    required String labId,
    required String sceneType,
    required String deviceType,
    String? targetId,
    bool allowQueue = true,
  }) async {
    try {
      final media = await apiService.uploadMedia(
        fileBytes: await file.readAsBytes(),
        fileName: file.name,
        labId: labId,
        sceneType: sceneType,
        deviceType: deviceType,
        targetId: targetId,
      );

      final inspectionResponse = await apiService.createAiInspection(
        payload: {
          'labId': labId,
          'sceneType': sceneType,
          'deviceType': deviceType,
          'targetId': targetId,
          'mediaRecordId': media['recordId'],
          'mediaUrl': media['url'],
          'reviewStatus': 'pending_review',
          'models': AiModelConfig.inspectionModels.map((item) => item.id).toList(),
          'preferredModel': AiModelConfig.primaryVisionModel.id,
        },
      );

      final inspection = AiInspectionRecord.fromJson({
        'mediaUrl': media['url'],
        ...inspectionResponse,
      });

      await localStorageService.cacheLatestInspection(
        _buildCacheKey(
          labId: labId,
          sceneType: sceneType,
          deviceType: deviceType,
          targetId: targetId,
        ),
        inspection.toJson(),
      );

      return EvidenceSubmissionResult(
        inspection: inspection,
        queued: false,
        message: '图片已上传并生成 AI 安全研判',
      );
    } catch (_) {
      if (allowQueue) {
        await localStorageService.enqueuePendingUpload({
          'file_path': file.path,
          'lab_id': labId,
          'scene_type': sceneType,
          'device_type': deviceType,
          'target_id': targetId,
          'queued_at': DateTime.now().toIso8601String(),
        });
      }

      final fallback = AiInspectionRecord.fallback(
        labId: labId,
        sceneType: sceneType,
        deviceType: deviceType,
      );

      await localStorageService.cacheLatestInspection(
        _buildCacheKey(
          labId: labId,
          sceneType: sceneType,
          deviceType: deviceType,
          targetId: targetId,
        ),
        fallback.toJson(),
      );

      return EvidenceSubmissionResult(
        inspection: fallback,
        queued: allowQueue,
        message: allowQueue ? '网络异常，图片已进入离线重试队列' : '图片已缓存，等待后续重试',
      );
    }
  }

  String _buildCacheKey({
    required String labId,
    required String sceneType,
    required String deviceType,
    String? targetId,
  }) {
    return '$labId::$sceneType::$deviceType::${targetId ?? 'global'}';
  }
}
