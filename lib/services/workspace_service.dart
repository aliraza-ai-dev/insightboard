import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/all_models.dart';

class WorkspaceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================================
  // Workspace CRUD
  // ==========================================
  Future<Workspace> createWorkspace(String name, String ownerId, {String? description, String? emoji}) async {
    final ref = _db.collection('workspaces').doc();
    final ws = Workspace(
      id: ref.id,
      name: name,
      ownerId: ownerId,
      memberIds: [ownerId],
      memberRoles: {ownerId: 'owner'},
      createdAt: DateTime.now(),
      description: description,
      iconEmoji: emoji ?? '📊',
    );
    await ref.set(ws.toMap());
    await _db.collection('users').doc(ownerId).update({
      'workspaceIds': FieldValue.arrayUnion([ref.id]),
    });
    return ws;
  }

  Stream<List<Workspace>> getUserWorkspaces(String userId) {
    return _db.collection('workspaces')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Workspace.fromMap(d.data(), d.id))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Future<Workspace?> getWorkspace(String id) async {
    final doc = await _db.collection('workspaces').doc(id).get();
    if (doc.exists) return Workspace.fromMap(doc.data()!, doc.id);
    return null;
  }

  Future<void> updateWorkspace(String id, Map<String, dynamic> data) async {
    await _db.collection('workspaces').doc(id).update(data);
  }

  Future<void> deleteWorkspace(String id) async {
    await _db.collection('workspaces').doc(id).delete();
  }

  // ==========================================
  // Team Collaboration
  // ==========================================
  Future<void> inviteMember(String workspaceId, String workspaceName,
      String email, String invitedBy, String role) async {
    final ref = _db.collection('invitations').doc();
    final inv = Invitation(
      id: ref.id,
      workspaceId: workspaceId,
      workspaceName: workspaceName,
      invitedEmail: email,
      invitedBy: invitedBy,
      role: role,
      createdAt: DateTime.now(),
    );
    await ref.set(inv.toMap());
  }

  Stream<List<Invitation>> getPendingInvitations(String email) {
    return _db.collection('invitations')
        .where('invitedEmail', isEqualTo: email)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Invitation.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> acceptInvitation(String invitationId, String userId) async {
    final invDoc = await _db.collection('invitations').doc(invitationId).get();
    if (!invDoc.exists) return;
    final inv = Invitation.fromMap(invDoc.data()!, invDoc.id);

    await _db.collection('workspaces').doc(inv.workspaceId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
      'memberRoles.$userId': inv.role,
    });
    await _db.collection('users').doc(userId).update({
      'workspaceIds': FieldValue.arrayUnion([inv.workspaceId]),
    });
    await _db.collection('invitations').doc(invitationId).update({
      'status': 'accepted',
    });
  }

  Future<void> declineInvitation(String invitationId) async {
    await _db.collection('invitations').doc(invitationId).update({
      'status': 'declined',
    });
  }

  Future<void> removeMember(String workspaceId, String userId) async {
    await _db.collection('workspaces').doc(workspaceId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'memberRoles.$userId': FieldValue.delete(),
    });
    await _db.collection('users').doc(userId).update({
      'workspaceIds': FieldValue.arrayRemove([workspaceId]),
    });
  }

  Future<void> updateMemberRole(String workspaceId, String userId, String role) async {
    await _db.collection('workspaces').doc(workspaceId).update({
      'memberRoles.$userId': role,
    });
  }

  Future<List<UserModel>> getWorkspaceMembers(String workspaceId) async {
    final ws = await getWorkspace(workspaceId);
    if (ws == null) return [];

    final members = <UserModel>[];
    for (final uid in ws.memberIds) {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        members.add(UserModel.fromMap(doc.data()!, doc.id));
      }
    }
    return members;
  }

  // ==========================================
  // Dashboard Layouts
  // ==========================================
  Future<void> saveDashboardLayout(DashboardLayout layout) async {
    await _db.collection('dashboards').doc(layout.id).set(layout.toMap());
  }

  Stream<List<DashboardLayout>> getWorkspaceDashboards(String workspaceId) {
    return _db.collection('dashboards')
        .where('workspaceId', isEqualTo: workspaceId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => DashboardLayout.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> deleteDashboard(String id) async {
    await _db.collection('dashboards').doc(id).delete();
  }

  // ==========================================
  // Charts Config
  // ==========================================
  Future<void> saveChartConfig(String workspaceId, ChartConfig chart) async {
    await _db.collection('workspaces').doc(workspaceId)
        .collection('charts').doc(chart.id).set(chart.toMap());
  }

  Stream<List<ChartConfig>> getWorkspaceCharts(String workspaceId) {
    return _db.collection('workspaces').doc(workspaceId)
        .collection('charts')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChartConfig.fromMap(d.data(), d.id))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order)));
  }

  // ==========================================
  // KPIs
  // ==========================================
  Future<void> saveKpi(String workspaceId, KpiCard kpi) async {
    await _db.collection('workspaces').doc(workspaceId)
        .collection('kpis').doc(kpi.id).set(kpi.toMap());
  }

  Stream<List<KpiCard>> getWorkspaceKpis(String workspaceId) {
    return _db.collection('workspaces').doc(workspaceId)
        .collection('kpis')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => KpiCard.fromMap(d.data(), d.id))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order)));
  }

  // ==========================================
  // Reports
  // ==========================================
  Future<void> saveReport(ReportModel report) async {
    await _db.collection('reports').doc(report.id).set(report.toMap());
  }

  Stream<List<ReportModel>> getWorkspaceReports(String workspaceId) {
    return _db.collection('reports')
        .where('workspaceId', isEqualTo: workspaceId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ReportModel.fromMap(d.data(), d.id))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  // ==========================================
  // Anomaly Alerts
  // ==========================================
  Future<void> saveAnomaly(AnomalyAlert alert) async {
    await _db.collection('anomalies').doc(alert.id).set(alert.toMap());
  }

  Stream<List<AnomalyAlert>> getWorkspaceAnomalies(String workspaceId) {
    return _db.collection('anomalies')
        .where('workspaceId', isEqualTo: workspaceId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AnomalyAlert.fromMap(d.data(), d.id))
            .toList()
          ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt)));
  }

  Future<void> markAnomalyRead(String id) async {
    await _db.collection('anomalies').doc(id).update({'isRead': true});
  }
}
