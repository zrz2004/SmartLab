import 'package:flutter/material.dart';

import 'app_localizations.dart';

class DynamicTextLocalizer {
  static String alertTitle(BuildContext context, String raw) {
    return _translateByMap(context, raw, _alertTitleKeyMap);
  }

  static String alertMessage(BuildContext context, String raw) {
    final normalized = _normalize(raw);

    final temperatureMatch = RegExp(
      r'^temperature\s+reached\s+([0-9]+(?:\.[0-9]+)?)\s*c(?:\s+in\s+.*)?\.?$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (temperatureMatch != null) {
      return context.l10n.t(
        'dynamic.alert.message.temperatureReached',
        params: {'value': temperatureMatch.group(1)!},
      );
    }

    final leakageMatch = RegExp(
      r'^leakage\s+current\s+reached\s+([0-9]+(?:\.[0-9]+)?)\s*ma(?:\s+in\s+.*)?\.?$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (leakageMatch != null) {
      return context.l10n.t(
        'dynamic.alert.message.leakageReached',
        params: {'value': leakageMatch.group(1)!},
      );
    }

    return _translateByMap(context, raw, _alertMessageKeyMap);
  }

  static String riskLevel(BuildContext context, String raw) {
    return _translateByMap(context, raw, _riskLevelKeyMap);
  }

  static String sceneType(BuildContext context, String raw) {
    return _translateByMap(context, raw, _sceneTypeKeyMap);
  }

  static String deviceType(BuildContext context, String raw) {
    return _translateByMap(context, raw, _deviceTypeKeyMap);
  }

  static String reviewStatus(BuildContext context, String raw) {
    return _translateByMap(context, raw, _reviewStatusKeyMap);
  }

  static String recommendation(BuildContext context, String raw) {
    return _translateByMap(context, raw, _recommendationKeyMap);
  }

  static String reason(BuildContext context, String raw) {
    return _translateByMap(context, raw, _reasonKeyMap);
  }

  static String evidenceItem(BuildContext context, String raw) {
    final entry = _evidenceTextMap[_normalize(raw)];
    if (entry == null) {
      return raw;
    }
    return Localizations.localeOf(context).languageCode == 'zh'
        ? entry.$1
        : entry.$2;
  }

  static String _translateByMap(
    BuildContext context,
    String raw,
    Map<String, String> keyMap,
  ) {
    final key = keyMap[_normalize(raw)];
    if (key == null) {
      return raw;
    }
    return context.l10n.t(key);
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static const Map<String, String> _alertTitleKeyMap = {
    'temperature warning': 'dynamic.alert.title.temperatureWarning',
    '温度预警': 'dynamic.alert.title.temperatureWarning',
    'ai image warning': 'dynamic.alert.title.aiImageWarning',
    'ai 图像预警': 'dynamic.alert.title.aiImageWarning',
    'ai inspection warning': 'dynamic.alert.title.aiImageWarning',
    'leakage current critical': 'dynamic.alert.title.leakageCurrentCritical',
    '漏电流严重警告': 'dynamic.alert.title.leakageCurrentCritical',
  };

  static const Map<String, String> _alertMessageKeyMap = {
    'ai review detected an open window that needs manual confirmation.':
        'dynamic.alert.message.aiWindowNeedsConfirm',
    'ai 复核检测到窗户开启，请人工确认。':
        'dynamic.alert.message.aiWindowNeedsConfirm',
    '电源开关或插座状态需要人工进一步确认。':
        'dynamic.reason.powerNeedsReview',
    'power switch or socket state needs manual confirmation.':
        'dynamic.reason.powerNeedsReview',
  };

  static const Map<String, String> _riskLevelKeyMap = {
    'critical': 'dynamic.risk.critical',
    '严重': 'dynamic.risk.critical',
    'warning': 'dynamic.risk.warning',
    '预警': 'dynamic.risk.warning',
    'info': 'dynamic.risk.info',
    '提示': 'dynamic.risk.info',
  };

  static const Map<String, String> _sceneTypeKeyMap = {
    'environment': 'dynamic.scene.environment',
    'power': 'dynamic.scene.power',
    'water': 'dynamic.scene.water',
    'security': 'dynamic.scene.security',
    'chemical': 'dynamic.scene.chemical',
    'alert': 'dynamic.scene.alert',
    'device': 'dynamic.scene.device',
    'general': 'dynamic.scene.general',
  };

  static const Map<String, String> _deviceTypeKeyMap = {
    'environment_sensor': 'dynamic.deviceType.environmentSensor',
    'main_power': 'dynamic.deviceType.mainPower',
    'main_valve': 'dynamic.deviceType.mainValve',
    'door_window': 'dynamic.deviceType.doorWindow',
    'chemical_storage': 'dynamic.deviceType.chemicalStorage',
    'alert_center': 'dynamic.deviceType.alertCenter',
    'power_monitor': 'dynamic.deviceType.powerMonitor',
    'generic_device': 'dynamic.deviceType.genericDevice',
    'unknown': 'dynamic.deviceType.unknown',
  };

  static const Map<String, String> _reviewStatusKeyMap = {
    'pending_review': 'dynamic.reviewStatus.pendingReview',
    'pending': 'dynamic.reviewStatus.pendingReview',
    '待复核': 'dynamic.reviewStatus.pendingReview',
    'approved': 'dynamic.reviewStatus.approved',
    '已通过': 'dynamic.reviewStatus.approved',
    'rejected': 'dynamic.reviewStatus.rejected',
    '已驳回': 'dynamic.reviewStatus.rejected',
  };

  static const Map<String, String> _recommendationKeyMap = {
    'request manual review.': 'dynamic.recommendation.requestManualReview',
    '请求人工复核。': 'dynamic.recommendation.requestManualReview',
    'ask staff to verify scene safety manually.':
        'dynamic.recommendation.verifySceneSafety',
    'ask the duty staff to verify the scene manually and record the review result.':
        'dynamic.recommendation.verifySceneSafety',
    'ask the duty staff to verify the scene and record the review result before closing the incident.':
        'dynamic.recommendation.verifySceneSafety',
    '请安排人员人工确认现场安全。':
        'dynamic.recommendation.verifySceneSafety',
    '请安排值班人员现场复核并记录结果。':
        'dynamic.recommendation.verifySceneSafety',
  };

  static const Map<String, String> _reasonKeyMap = {
    'waiting for backend structured analysis.':
        'dynamic.reason.waitingStructuredAnalysis',
    '等待后端结构化分析结果。': 'dynamic.reason.waitingStructuredAnalysis',
    'image archived locally. waiting for backend ai service retry.':
        'dynamic.reason.waitingAiRetry',
    'image uploaded successfully, but the ai service has not returned a clear decision yet.':
        'dynamic.reason.waitingAiRetry',
    '图像已本地归档，等待后端 ai 服务重试。':
        'dynamic.reason.waitingAiRetry',
    '图像已上传成功，但 ai 服务尚未返回明确判断。':
        'dynamic.reason.waitingAiRetry',
    'door may be unlocked or not fully closed.':
        'dynamic.reason.doorNeedsReview',
    '门体可能未上锁或未完全关闭。': 'dynamic.reason.doorNeedsReview',
    'window may be open and needs manual confirmation.':
        'dynamic.reason.windowNeedsReview',
    '窗户可能开启，需要人工确认。': 'dynamic.reason.windowNeedsReview',
    'water source may still be active or there are signs of leakage.':
        'dynamic.reason.waterNeedsReview',
    '水源可能未关闭或存在漏水迹象。': 'dynamic.reason.waterNeedsReview',
    'power switch or socket state needs manual confirmation.':
        'dynamic.reason.powerNeedsReview',
    '电源开关或插座状态需要人工进一步确认。':
        'dynamic.reason.powerNeedsReview',
    'oven power state or surrounding area may be unsafe.':
        'dynamic.reason.ovenNeedsReview',
    '烘箱电源状态或周边环境可能存在安全隐患。':
        'dynamic.reason.ovenNeedsReview',
    'chemical cabinet scene needs manual validation.':
        'dynamic.reason.chemicalNeedsReview',
    '危化品柜现场需要人工进一步核验。':
        'dynamic.reason.chemicalNeedsReview',
    'alert evidence uploaded and queued for manual review.':
        'dynamic.reason.alertNeedsReview',
    '报警补充取证已上传，等待人工复核。':
        'dynamic.reason.alertNeedsReview',
    'device scene archived for manual review.':
        'dynamic.reason.waitingStructuredAnalysis',
    '设备现场已归档，等待人工复核。':
        'dynamic.reason.waitingStructuredAnalysis',
    'scene archived and waiting for manual review.':
        'dynamic.reason.waitingStructuredAnalysis',
    '场景已归档，等待人工复核。':
        'dynamic.reason.waitingStructuredAnalysis',
  };

  static const Map<String, (String, String)> _evidenceTextMap = {
    'uploaded-image-archived': ('图片已成功归档', 'Image archived successfully'),
    'pending-ai-review': ('AI 正在排队分析', 'AI analysis is queued'),
    'no visible chemical spills or contamination.':
        ('未发现化学品泄漏或污染痕迹', 'No visible chemical spills or contamination'),
    'no equipment malfunctions or obstructions in sight.':
        ('未发现设备故障或通道遮挡', 'No equipment malfunctions or obstructions in sight'),
    'clean, uncluttered workspace environment.':
        ('现场整洁，无明显杂乱堆放', 'Clean, uncluttered workspace environment'),
    'no signs of smoke, fumes, or structural damage.':
        ('未见烟雾、异常气体或结构损坏', 'No signs of smoke, fumes, or structural damage'),
    'window appears open and needs manual confirmation.':
        ('窗户疑似处于开启状态，需要人工确认', 'Window appears open and needs manual confirmation'),
    'door lock state is unclear from the image.':
        ('门锁状态无法从图像中完全确认', 'Door lock state is unclear from the image'),
    'water valve state needs manual confirmation.':
        ('水阀状态需要人工进一步确认', 'Water valve state needs manual confirmation'),
    'power switch or socket state needs manual confirmation.':
        ('电源开关或插座状态需要人工进一步确认', 'Power switch or socket state needs manual confirmation'),
    'ai 服务未返回结构化结论，已启用兜底规则。':
        ('AI 服务未返回结构化结论，已启用兜底规则', 'Fallback rule used because AI did not return structured output'),
  };
}
