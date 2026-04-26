// ============================================
// models/user_model.dart
// ============================================
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? photoUrl;
  final String role; // owner, admin, editor, viewer
  final List<String> workspaceIds;
  final DateTime createdAt;
  final Map<String, dynamic> preferences;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
    this.role = 'owner',
    this.workspaceIds = const [],
    required this.createdAt,
    this.preferences = const {},
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      role: map['role'] ?? 'owner',
      workspaceIds: List<String>.from(map['workspaceIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'name': name,
    'photoUrl': photoUrl,
    'role': role,
    'workspaceIds': workspaceIds,
    'createdAt': Timestamp.fromDate(createdAt),
    'preferences': preferences,
  };
}

// ============================================
// models/workspace_model.dart
// ============================================
class Workspace {
  final String id;
  final String name;
  final String ownerId;
  final List<String> memberIds;
  final Map<String, String> memberRoles; // uid -> role
  final DateTime createdAt;
  final String? description;
  final String? iconEmoji;

  Workspace({
    required this.id,
    required this.name,
    required this.ownerId,
    this.memberIds = const [],
    this.memberRoles = const {},
    required this.createdAt,
    this.description,
    this.iconEmoji,
  });

  factory Workspace.fromMap(Map<String, dynamic> map, String id) {
    return Workspace(
      id: id,
      name: map['name'] ?? '',
      ownerId: map['ownerId'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      memberRoles: Map<String, String>.from(map['memberRoles'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: map['description'],
      iconEmoji: map['iconEmoji'],
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'ownerId': ownerId,
    'memberIds': memberIds,
    'memberRoles': memberRoles,
    'createdAt': Timestamp.fromDate(createdAt),
    'description': description,
    'iconEmoji': iconEmoji,
  };
}

// ============================================
// models/dataset_model.dart
// ============================================
class DatasetModel {
  final String id;
  final String name;
  final String workspaceId;
  final String uploadedBy;
  final DateTime uploadedAt;
  final int rowCount;
  final int colCount;
  final List<String> columns;
  final List<String> columnTypes; // numeric, text, date, boolean
  final String? fileUrl;
  final String sourceType; // csv, excel, google_sheets, api
  final Map<String, dynamic>? sourceConfig;

  DatasetModel({
    required this.id,
    required this.name,
    required this.workspaceId,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.rowCount,
    required this.colCount,
    required this.columns,
    required this.columnTypes,
    this.fileUrl,
    this.sourceType = 'csv',
    this.sourceConfig,
  });

  factory DatasetModel.fromMap(Map<String, dynamic> map, String id) {
    return DatasetModel(
      id: id,
      name: map['name'] ?? '',
      workspaceId: map['workspaceId'] ?? '',
      uploadedBy: map['uploadedBy'] ?? '',
      uploadedAt: (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rowCount: map['rowCount'] ?? 0,
      colCount: map['colCount'] ?? 0,
      columns: List<String>.from(map['columns'] ?? []),
      columnTypes: List<String>.from(map['columnTypes'] ?? []),
      fileUrl: map['fileUrl'],
      sourceType: map['sourceType'] ?? 'csv',
      sourceConfig: map['sourceConfig'],
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'workspaceId': workspaceId,
    'uploadedBy': uploadedBy,
    'uploadedAt': Timestamp.fromDate(uploadedAt),
    'rowCount': rowCount,
    'colCount': colCount,
    'columns': columns,
    'columnTypes': columnTypes,
    'fileUrl': fileUrl,
    'sourceType': sourceType,
    'sourceConfig': sourceConfig,
  };
}

// ============================================
// models/chart_model.dart
// ============================================
class ChartConfig {
  final String id;
  final String type; // bar, line, pie, heatmap, scatter, area
  final String title;
  final String datasetId;
  final String? xColumn;
  final String? yColumn;
  final List<String>? yColumns; // for multi-series
  final String? groupByColumn;
  final String aggregation; // sum, avg, count, min, max
  final Map<String, dynamic> styling;
  final int order;

  ChartConfig({
    required this.id,
    required this.type,
    required this.title,
    required this.datasetId,
    this.xColumn,
    this.yColumn,
    this.yColumns,
    this.groupByColumn,
    this.aggregation = 'sum',
    this.styling = const {},
    this.order = 0,
  });

  factory ChartConfig.fromMap(Map<String, dynamic> map, String id) {
    return ChartConfig(
      id: id,
      type: map['type'] ?? 'bar',
      title: map['title'] ?? '',
      datasetId: map['datasetId'] ?? '',
      xColumn: map['xColumn'],
      yColumn: map['yColumn'],
      yColumns: map['yColumns'] != null ? List<String>.from(map['yColumns']) : null,
      groupByColumn: map['groupByColumn'],
      aggregation: map['aggregation'] ?? 'sum',
      styling: Map<String, dynamic>.from(map['styling'] ?? {}),
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type,
    'title': title,
    'datasetId': datasetId,
    'xColumn': xColumn,
    'yColumn': yColumn,
    'yColumns': yColumns,
    'groupByColumn': groupByColumn,
    'aggregation': aggregation,
    'styling': styling,
    'order': order,
  };

  ChartConfig copyWith({
    String? id, String? type, String? title, String? datasetId,
    String? xColumn, String? yColumn, List<String>? yColumns,
    String? groupByColumn, String? aggregation,
    Map<String, dynamic>? styling, int? order,
  }) {
    return ChartConfig(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      datasetId: datasetId ?? this.datasetId,
      xColumn: xColumn ?? this.xColumn,
      yColumn: yColumn ?? this.yColumn,
      yColumns: yColumns ?? this.yColumns,
      groupByColumn: groupByColumn ?? this.groupByColumn,
      aggregation: aggregation ?? this.aggregation,
      styling: styling ?? this.styling,
      order: order ?? this.order,
    );
  }
}

// ============================================
// models/kpi_model.dart
// ============================================
class KpiCard {
  final String id;
  final String title;
  final String datasetId;
  final String column;
  final String aggregation; // sum, avg, count, min, max, latest
  final String? comparisonType; // previous_period, target
  final double? targetValue;
  final String? icon;
  final String? color;
  final int order;
  final String? prefix; // $, Rs.
  final String? suffix; // %, units

  KpiCard({
    required this.id,
    required this.title,
    required this.datasetId,
    required this.column,
    this.aggregation = 'sum',
    this.comparisonType,
    this.targetValue,
    this.icon,
    this.color,
    this.order = 0,
    this.prefix,
    this.suffix,
  });

  factory KpiCard.fromMap(Map<String, dynamic> map, String id) {
    return KpiCard(
      id: id,
      title: map['title'] ?? '',
      datasetId: map['datasetId'] ?? '',
      column: map['column'] ?? '',
      aggregation: map['aggregation'] ?? 'sum',
      comparisonType: map['comparisonType'],
      targetValue: (map['targetValue'] as num?)?.toDouble(),
      icon: map['icon'],
      color: map['color'],
      order: map['order'] ?? 0,
      prefix: map['prefix'],
      suffix: map['suffix'],
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'datasetId': datasetId,
    'column': column,
    'aggregation': aggregation,
    'comparisonType': comparisonType,
    'targetValue': targetValue,
    'icon': icon,
    'color': color,
    'order': order,
    'prefix': prefix,
    'suffix': suffix,
  };
}

// ============================================
// models/dashboard_model.dart
// ============================================
class DashboardLayout {
  final String id;
  final String name;
  final String workspaceId;
  final String createdBy;
  final DateTime createdAt;
  final List<DashboardWidget> widgets;
  final bool isDefault;

  DashboardLayout({
    required this.id,
    required this.name,
    required this.workspaceId,
    required this.createdBy,
    required this.createdAt,
    this.widgets = const [],
    this.isDefault = false,
  });

  factory DashboardLayout.fromMap(Map<String, dynamic> map, String id) {
    return DashboardLayout(
      id: id,
      name: map['name'] ?? '',
      workspaceId: map['workspaceId'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      widgets: (map['widgets'] as List<dynamic>?)
          ?.map((w) => DashboardWidget.fromMap(Map<String, dynamic>.from(w)))
          .toList() ?? [],
      isDefault: map['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'workspaceId': workspaceId,
    'createdBy': createdBy,
    'createdAt': Timestamp.fromDate(createdAt),
    'widgets': widgets.map((w) => w.toMap()).toList(),
    'isDefault': isDefault,
  };
}

class DashboardWidget {
  final String id;
  final String type; // chart, kpi, text, ai_insight
  final String? chartId;
  final String? kpiId;
  final int gridX;
  final int gridY;
  final int gridW;
  final int gridH;
  final Map<String, dynamic> config;

  DashboardWidget({
    required this.id,
    required this.type,
    this.chartId,
    this.kpiId,
    this.gridX = 0,
    this.gridY = 0,
    this.gridW = 2,
    this.gridH = 2,
    this.config = const {},
  });

  factory DashboardWidget.fromMap(Map<String, dynamic> map) {
    return DashboardWidget(
      id: map['id'] ?? '',
      type: map['type'] ?? 'chart',
      chartId: map['chartId'],
      kpiId: map['kpiId'],
      gridX: map['gridX'] ?? 0,
      gridY: map['gridY'] ?? 0,
      gridW: map['gridW'] ?? 2,
      gridH: map['gridH'] ?? 2,
      config: Map<String, dynamic>.from(map['config'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'chartId': chartId,
    'kpiId': kpiId,
    'gridX': gridX,
    'gridY': gridY,
    'gridW': gridW,
    'gridH': gridH,
    'config': config,
  };
}

// ============================================
// models/report_model.dart
// ============================================
class ReportModel {
  final String id;
  final String title;
  final String workspaceId;
  final String createdBy;
  final DateTime createdAt;
  final String? pdfUrl;
  final String status; // generating, ready, failed
  final List<String> chartIds;
  final List<String> kpiIds;
  final String? aiSummary;
  final String? scheduleType; // null, daily, weekly, monthly
  final String? scheduleEmail;

  ReportModel({
    required this.id,
    required this.title,
    required this.workspaceId,
    required this.createdBy,
    required this.createdAt,
    this.pdfUrl,
    this.status = 'generating',
    this.chartIds = const [],
    this.kpiIds = const [],
    this.aiSummary,
    this.scheduleType,
    this.scheduleEmail,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map, String id) {
    return ReportModel(
      id: id,
      title: map['title'] ?? '',
      workspaceId: map['workspaceId'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pdfUrl: map['pdfUrl'],
      status: map['status'] ?? 'generating',
      chartIds: List<String>.from(map['chartIds'] ?? []),
      kpiIds: List<String>.from(map['kpiIds'] ?? []),
      aiSummary: map['aiSummary'],
      scheduleType: map['scheduleType'],
      scheduleEmail: map['scheduleEmail'],
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'workspaceId': workspaceId,
    'createdBy': createdBy,
    'createdAt': Timestamp.fromDate(createdAt),
    'pdfUrl': pdfUrl,
    'status': status,
    'chartIds': chartIds,
    'kpiIds': kpiIds,
    'aiSummary': aiSummary,
    'scheduleType': scheduleType,
    'scheduleEmail': scheduleEmail,
  };
}

// ============================================
// models/anomaly_model.dart
// ============================================
class AnomalyAlert {
  final String id;
  final String datasetId;
  final String column;
  final String description;
  final double value;
  final double expectedRange;
  final String severity; // low, medium, high, critical
  final DateTime detectedAt;
  final bool isRead;
  final String workspaceId;

  AnomalyAlert({
    required this.id,
    required this.datasetId,
    required this.column,
    required this.description,
    required this.value,
    required this.expectedRange,
    this.severity = 'medium',
    required this.detectedAt,
    this.isRead = false,
    required this.workspaceId,
  });

  factory AnomalyAlert.fromMap(Map<String, dynamic> map, String id) {
    return AnomalyAlert(
      id: id,
      datasetId: map['datasetId'] ?? '',
      column: map['column'] ?? '',
      description: map['description'] ?? '',
      value: (map['value'] as num?)?.toDouble() ?? 0,
      expectedRange: (map['expectedRange'] as num?)?.toDouble() ?? 0,
      severity: map['severity'] ?? 'medium',
      detectedAt: (map['detectedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      workspaceId: map['workspaceId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'datasetId': datasetId,
    'column': column,
    'description': description,
    'value': value,
    'expectedRange': expectedRange,
    'severity': severity,
    'detectedAt': Timestamp.fromDate(detectedAt),
    'isRead': isRead,
    'workspaceId': workspaceId,
  };
}

// ============================================
// models/invitation_model.dart
// ============================================
class Invitation {
  final String id;
  final String workspaceId;
  final String workspaceName;
  final String invitedEmail;
  final String invitedBy;
  final String role;
  final String status; // pending, accepted, declined
  final DateTime createdAt;

  Invitation({
    required this.id,
    required this.workspaceId,
    required this.workspaceName,
    required this.invitedEmail,
    required this.invitedBy,
    this.role = 'viewer',
    this.status = 'pending',
    required this.createdAt,
  });

  factory Invitation.fromMap(Map<String, dynamic> map, String id) {
    return Invitation(
      id: id,
      workspaceId: map['workspaceId'] ?? '',
      workspaceName: map['workspaceName'] ?? '',
      invitedEmail: map['invitedEmail'] ?? '',
      invitedBy: map['invitedBy'] ?? '',
      role: map['role'] ?? 'viewer',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'workspaceId': workspaceId,
    'workspaceName': workspaceName,
    'invitedEmail': invitedEmail,
    'invitedBy': invitedBy,
    'role': role,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
