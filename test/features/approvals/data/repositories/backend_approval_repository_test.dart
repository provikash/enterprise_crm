import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:enterprise_crm/core/config/app_config.dart';
import 'package:enterprise_crm/features/approvals/data/repositories/approval_repository_factory.dart';
import 'package:enterprise_crm/features/approvals/data/repositories/backend_approval_repository.dart';
import 'package:enterprise_crm/features/approvals/data/repositories/mock_approval_repository.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_priority.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_status.dart';
import 'package:enterprise_crm/features/approvals/domain/exceptions/approvals_network_exception.dart';
import 'package:enterprise_crm/features/approvals/domain/inputs/create_approval_request_input.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (handler != null) {
      return handler!(options);
    }
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late _MockAdapter adapter;
  late BackendApprovalRepository repository;

  final testActor = const CurrentUser(
    id: 'usr-admin',
    accountType: AccountType.admin,
    displayName: 'Admin User',
  );

  setUp(() {
    adapter = _MockAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://crm.enterprise.internal'));
    dio.httpClientAdapter = adapter;
    repository = BackendApprovalRepository(dio: dio, basePath: '/api/v1');
  });

  ResponseBody jsonResponse(dynamic data, int statusCode) {
    return ResponseBody.fromString(
      jsonEncode(data),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  group('BackendApprovalRepository REST Integration Tests', () {
    test('getApprovals sends GET to /api/v1/approvals and parses list', () async {
      adapter.handler = (options) {
        expect(options.path, '/api/v1/approvals');
        expect(options.queryParameters['status'], 'pending');
        return jsonResponse({
          'items': [
            {
              'id': 'appr-001',
              'request_number': 'REQ-101',
              'module': 'purchase',
              'entity_type': 'PurchaseOrder',
              'entity_id': 'PO-1',
              'entity_title': 'Steel Order',
              'requester_id': 'usr-1',
              'requester_name': 'Alice',
              'status': 'pending',
              'priority': 'urgent',
              'submitted_at': '2026-10-15T10:00:00.000Z',
            },
          ],
        }, 200);
      };

      final items = await repository.getApprovals(status: ApprovalStatus.pending);
      expect(items.length, 1);
      expect(items.first.id, 'appr-001');
      expect(items.first.requestNumber, 'REQ-101');
      expect(items.first.priority, ApprovalPriority.urgent);
    });

    test('getApprovalById returns request on 200 and null on 404', () async {
      // 200 OK
      adapter.handler = (options) {
        expect(options.path, '/api/v1/approvals/appr-001');
        return jsonResponse({
          'id': 'appr-001',
          'request_number': 'REQ-101',
          'module': 'purchase',
          'entity_type': 'PurchaseOrder',
          'entity_id': 'PO-1',
          'entity_title': 'Steel Order',
          'requester_id': 'usr-1',
          'requester_name': 'Alice',
          'status': 'pending',
          'priority': 'normal',
          'submitted_at': '2026-10-15T10:00:00.000Z',
        }, 200);
      };

      final req = await repository.getApprovalById('appr-001');
      expect(req, isNotNull);
      expect(req!.id, 'appr-001');

      // 404 Not Found
      adapter.handler = (options) {
        return jsonResponse({'message': 'Approval not found'}, 404);
      };

      final notFound = await repository.getApprovalById('unknown-id');
      expect(notFound, isNull);
    });

    test('submitRequest sends POST with valid payload and returns created request', () async {
      adapter.handler = (options) {
        expect(options.path, '/api/v1/approvals');
        expect(options.method, 'POST');
        final body = options.data as Map<String, dynamic>;
        expect(body['module'], 'purchase');
        expect(body['entity_title'], 'New PO');

        return jsonResponse({
          'id': 'appr-new',
          'request_number': 'REQ-999',
          'module': 'purchase',
          'entity_type': 'PurchaseOrder',
          'entity_id': 'PO-99',
          'entity_title': 'New PO',
          'requester_id': 'usr-1',
          'requester_name': 'Alice',
          'status': 'pending',
          'priority': 'normal',
          'submitted_at': '2026-10-16T12:00:00.000Z',
        }, 201);
      };

      final created = await repository.submitRequest(
        const CreateApprovalRequestInput(
          module: CrmModule.purchase,
          entityType: 'PurchaseOrder',
          entityId: 'PO-99',
          entityTitle: 'New PO',
          requesterId: 'usr-1',
          requesterName: 'Alice',
        ),
      );

      expect(created.id, 'appr-new');
      expect(created.requestNumber, 'REQ-999');
    });

    test('approveRequest posts comment and returns updated entity', () async {
      adapter.handler = (options) {
        expect(options.path, '/api/v1/approvals/appr-001/approve');
        final data = options.data as Map<String, dynamic>;
        expect(data['comment'], 'Looks good');
        expect(data['actor_id'], 'usr-admin');

        return jsonResponse({
          'id': 'appr-001',
          'request_number': 'REQ-101',
          'module': 'purchase',
          'entity_type': 'PurchaseOrder',
          'entity_id': 'PO-1',
          'entity_title': 'Steel Order',
          'requester_id': 'usr-1',
          'requester_name': 'Alice',
          'status': 'approved',
          'priority': 'normal',
          'submitted_at': '2026-10-15T10:00:00.000Z',
        }, 200);
      };

      final updated = await repository.approveRequest(
        requestId: 'appr-001',
        actor: testActor,
        comment: 'Looks good',
      );

      expect(updated.status, ApprovalStatus.approved);
    });

    test('rejectRequest posts mandatory reason and returns rejected entity', () async {
      adapter.handler = (options) {
        expect(options.path, '/api/v1/approvals/appr-001/reject');
        final data = options.data as Map<String, dynamic>;
        expect(data['rejection_reason'], 'Exceeds budget cap');

        return jsonResponse({
          'id': 'appr-001',
          'request_number': 'REQ-101',
          'module': 'purchase',
          'entity_type': 'PurchaseOrder',
          'entity_id': 'PO-1',
          'entity_title': 'Steel Order',
          'requester_id': 'usr-1',
          'requester_name': 'Alice',
          'status': 'rejected',
          'priority': 'normal',
          'submitted_at': '2026-10-15T10:00:00.000Z',
        }, 200);
      };

      final updated = await repository.rejectRequest(
        requestId: 'appr-001',
        actor: testActor,
        rejectionReason: 'Exceeds budget cap',
      );

      expect(updated.status, ApprovalStatus.rejected);
    });

    test('requestRevision and cancelRequest send appropriate endpoints', () async {
      // Revision
      adapter.handler = (options) {
        expect(options.path, '/api/v1/approvals/appr-001/revision');
        return jsonResponse({
          'id': 'appr-001',
          'request_number': 'REQ-101',
          'module': 'purchase',
          'entity_type': 'PurchaseOrder',
          'entity_id': 'PO-1',
          'entity_title': 'Steel Order',
          'requester_id': 'usr-1',
          'requester_name': 'Alice',
          'status': 'revisionRequested',
          'priority': 'normal',
          'submitted_at': '2026-10-15T10:00:00.000Z',
        }, 200);
      };

      final rev = await repository.requestRevision(
        requestId: 'appr-001',
        actor: testActor,
        revisionNotes: 'Please attach spec',
      );
      expect(rev.status, ApprovalStatus.revisionRequested);

      // Cancel
      adapter.handler = (options) {
        expect(options.path, '/api/v1/approvals/appr-001/cancel');
        return jsonResponse({
          'id': 'appr-001',
          'request_number': 'REQ-101',
          'module': 'purchase',
          'entity_type': 'PurchaseOrder',
          'entity_id': 'PO-1',
          'entity_title': 'Steel Order',
          'requester_id': 'usr-1',
          'requester_name': 'Alice',
          'status': 'cancelled',
          'priority': 'normal',
          'submitted_at': '2026-10-15T10:00:00.000Z',
        }, 200);
      };

      final cancelled = await repository.cancelRequest(
        requestId: 'appr-001',
        actor: testActor,
        reason: 'Duplicate',
      );
      expect(cancelled.status, ApprovalStatus.cancelled);
    });

    test('getAuditTrail returns list of activities', () async {
      adapter.handler = (options) {
        expect(options.path, '/api/v1/approvals/appr-001/audit');
        return jsonResponse({
          'items': [
            {
              'id': 'act-1',
              'approval_request_id': 'appr-001',
              'actor_user_id': 'usr-1',
              'actor_user_name': 'Alice',
              'action': 'submitted',
              'timestamp': '2026-10-15T10:00:00.000Z',
            },
          ],
        }, 200);
      };

      final trail = await repository.getAuditTrail('appr-001');
      expect(trail.length, 1);
      expect(trail.first.id, 'act-1');
    });

    test('Zero Silent Fallback Invariant: 500 server error throws ApprovalsNetworkException without falling back to mock', () async {
      adapter.handler = (options) {
        return jsonResponse({'error': 'Internal server explosion'}, 500);
      };

      expect(
        () => repository.getApprovals(),
        throwsA(isA<ApprovalsNetworkException>().having(
          (e) => e.statusCode,
          'statusCode',
          500,
        )),
      );
    });
  });

  group('ApprovalRepositoryFactory Tests', () {
    test('instantiates MockApprovalRepository when dataSourceMode is mock', () {
      const config = AppConfig(dataSourceMode: DataSourceMode.mock);
      final repo = ApprovalRepositoryFactory.create(appConfig: config);
      expect(repo, isA<MockApprovalRepository>());
    });

    test('instantiates BackendApprovalRepository when dataSourceMode is api', () {
      const config = AppConfig(dataSourceMode: DataSourceMode.api);
      final repo = ApprovalRepositoryFactory.create(
        appConfig: config,
        dio: dio,
      );
      expect(repo, isA<BackendApprovalRepository>());
    });
  });
}
