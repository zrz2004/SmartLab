class AiInspectionRecord {
  final String id;
  final String sceneType;
  final String deviceType;
  final String riskLevel;
  final double confidence;
  final String reason;
  final String recommendedAction;
  final List<String> evidence;
  final String labId;
  final DateTime capturedAt;
  final String reviewStatus;
  final String model;
  final String? mediaUrl;

  const AiInspectionRecord({
    required this.id,
    required this.sceneType,
    required this.deviceType,
    required this.riskLevel,
    required this.confidence,
    required this.reason,
    required this.recommendedAction,
    required this.evidence,
    required this.labId,
    required this.capturedAt,
    required this.reviewStatus,
    required this.model,
    this.mediaUrl,
  });

  factory AiInspectionRecord.fromJson(Map<String, dynamic> json) {
    return AiInspectionRecord(
      id: json['id'] as String? ?? 'local-${DateTime.now().millisecondsSinceEpoch}',
      sceneType: json['sceneType'] as String? ?? 'general',
      deviceType: json['deviceType'] as String? ?? 'unknown',
      riskLevel: json['riskLevel'] as String? ?? 'warning',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.65,
      reason: json['reason'] as String? ?? 'Waiting for backend structured analysis.',
      recommendedAction: json['recommendedAction'] as String? ?? 'Request manual review.',
      evidence: List<String>.from(json['evidence'] ?? const <String>[]),
      labId: json['labId'] as String? ?? '',
      capturedAt: json['capturedAt'] != null ? DateTime.parse(json['capturedAt'] as String) : DateTime.now(),
      reviewStatus: json['reviewStatus'] as String? ?? 'pending_review',
      model: json['model'] as String? ?? 'Qwen/Qwen3-VL-32B-Instruct',
      mediaUrl: json['mediaUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sceneType': sceneType,
      'deviceType': deviceType,
      'riskLevel': riskLevel,
      'confidence': confidence,
      'reason': reason,
      'recommendedAction': recommendedAction,
      'evidence': evidence,
      'labId': labId,
      'capturedAt': capturedAt.toIso8601String(),
      'reviewStatus': reviewStatus,
      'model': model,
      'mediaUrl': mediaUrl,
    };
  }

  factory AiInspectionRecord.fallback({
    required String labId,
    required String sceneType,
    required String deviceType,
    String? mediaUrl,
  }) {
    return AiInspectionRecord(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      sceneType: sceneType,
      deviceType: deviceType,
      riskLevel: 'warning',
      confidence: 0.60,
      reason: 'Image archived locally. Waiting for backend AI service retry.',
      recommendedAction: 'Ask staff to verify scene safety manually.',
      evidence: const ['fallback-local-cache'],
      labId: labId,
      capturedAt: DateTime.now(),
      reviewStatus: 'pending_review',
      model: 'Qwen/Qwen3-VL-32B-Instruct',
      mediaUrl: mediaUrl,
    );
  }
}
