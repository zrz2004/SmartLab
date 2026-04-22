import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/ai_model_config.dart';
import '../models/ai_inspection_record.dart';
import 'api_service.dart';
import 'local_storage_service.dart';
import 'upload_reminder_service.dart';

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
  final UploadReminderService uploadReminderService;
  final ImagePicker _picker = ImagePicker();

  EvidenceService({
    required this.apiService,
    required this.localStorageService,
    required this.uploadReminderService,
  });

  Future<EvidenceSubmissionResult?> captureAndInspect({
    required String labId,
    required String sceneType,
    required String deviceType,
    String? targetId,
  }) async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
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
      imageQuality: 80,
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
    final cacheKey = _buildCacheKey(
      labId: labId,
      sceneType: sceneType,
      deviceType: deviceType,
      targetId: targetId,
    );

    try {
      final latest = await apiService.getLatestAiInspection(
        labId: labId,
        sceneType: sceneType,
        deviceType: deviceType,
        targetId: targetId,
      );
      await localStorageService.cacheLatestInspection(cacheKey, latest);
      return AiInspectionRecord.fromJson(latest);
    } on DioException {
      final cached = localStorageService.getLatestInspection(cacheKey);
      if (cached == null) return null;
      return AiInspectionRecord.fromJson(cached);
    }
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
    Map<String, dynamic>? media;

    try {
      media = await apiService.uploadMedia(
        fileBytes: await file.readAsBytes(),
        fileName: file.name,
        labId: labId,
        sceneType: sceneType,
        deviceType: deviceType,
        targetId: targetId,
      );
      await uploadReminderService.recordSuccessfulUpload(labId);
    } on DioException catch (error) {
      return _handleUploadFailure(
        file: file,
        labId: labId,
        sceneType: sceneType,
        deviceType: deviceType,
        targetId: targetId,
        allowQueue: allowQueue,
        serverMessage: _extractServerMessage(error),
      );
    } catch (_) {
      return _handleUploadFailure(
        file: file,
        labId: labId,
        sceneType: sceneType,
        deviceType: deviceType,
        targetId: targetId,
        allowQueue: allowQueue,
      );
    }

    try {
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

      await _cacheInspection(
        inspection: inspection,
        labId: labId,
        sceneType: sceneType,
        deviceType: deviceType,
        targetId: targetId,
      );

      final hasRisk = inspection.riskLevel.toLowerCase() == 'warning' ||
          inspection.riskLevel.toLowerCase() == 'critical';
      return EvidenceSubmissionResult(
        inspection: inspection,
        queued: false,
        message: hasRisk ? 'AI 已识别到风险，请立即处理并完成人工复核。' : '图片已上传，AI 检测完成。',
      );
    } catch (_) {
      final fallback = AiInspectionRecord.fallback(
        labId: labId,
        sceneType: sceneType,
        deviceType: deviceType,
        mediaUrl: media['url'] as String?,
      );

      await _cacheInspection(
        inspection: fallback,
        labId: labId,
        sceneType: sceneType,
        deviceType: deviceType,
        targetId: targetId,
      );

      return EvidenceSubmissionResult(
        inspection: fallback,
        queued: false,
        message: '图片已上传并入库，AI 正在排队分析，请稍后查看结果。',
      );
    }
  }

  Future<EvidenceSubmissionResult> _handleUploadFailure({
    required XFile file,
    required String labId,
    required String sceneType,
    required String deviceType,
    required bool allowQueue,
    String? targetId,
    String? serverMessage,
  }) async {
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

    await _cacheInspection(
      inspection: fallback,
      labId: labId,
      sceneType: sceneType,
      deviceType: deviceType,
      targetId: targetId,
    );

    return EvidenceSubmissionResult(
      inspection: fallback,
      queued: allowQueue,
      message: serverMessage ?? (allowQueue ? '网络异常，图片已进入离线重试队列。' : '图片已缓存，等待后续重试。'),
    );
  }

  Future<void> _cacheInspection({
    required AiInspectionRecord inspection,
    required String labId,
    required String sceneType,
    required String deviceType,
    String? targetId,
  }) async {
    await localStorageService.cacheLatestInspection(
      _buildCacheKey(
        labId: labId,
        sceneType: sceneType,
        deviceType: deviceType,
        targetId: targetId,
      ),
      inspection.toJson(),
    );
  }

  String? _extractServerMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      return data['message'] as String?;
    }
    return null;
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
