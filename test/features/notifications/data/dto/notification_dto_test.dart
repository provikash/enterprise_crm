import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/notifications/data/dto/notification_dto.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/crm_notification.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/notification_category.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/notification_priority.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationDto Unit Tests', () {
    test('fromJson and toJson round-trip preserves all fields', () {
      final json = {
        'id': 'notif-001',
        'recipient_user_id': 'usr-001',
        'title': 'New Approval Required',
        'body': 'Purchase order PO-99 requires your signature.',
        'category': 'approvalRequest',
        'priority': 'urgent',
        'reference_module': 'purchase',
        'reference_entity_type': 'PurchaseOrder',
        'reference_entity_id': 'PO-99',
        'is_read': true,
        'read_at': '2026-10-16T12:00:00.000Z',
        'created_at': '2026-10-16T11:00:00.000Z',
        'payload': {'amount': 5000},
      };

      final dto = NotificationDto.fromJson(json);
      expect(dto.id, 'notif-001');
      expect(dto.recipientUserId, 'usr-001');
      expect(dto.title, 'New Approval Required');
      expect(dto.body, 'Purchase order PO-99 requires your signature.');
      expect(dto.category, 'approvalRequest');
      expect(dto.priority, 'urgent');
      expect(dto.referenceModule, 'purchase');
      expect(dto.referenceEntityId, 'PO-99');
      expect(dto.isRead, isTrue);

      final serialized = dto.toJson();
      expect(serialized['id'], 'notif-001');
      expect(serialized['is_read'], isTrue);
      expect(serialized['reference_entity_id'], 'PO-99');
    });

    test('toDomain converts DTO to CrmNotification entity', () {
      const dto = NotificationDto(
        id: 'notif-002',
        recipientUserId: 'usr-002',
        title: 'Decision Received',
        body: 'Your leave request was approved.',
        category: 'approvalDecision',
        priority: 'critical',
        referenceModule: 'hrPayroll',
        referenceEntityType: 'LeaveRequest',
        referenceEntityId: 'LR-5',
        isRead: false,
        createdAt: '2026-10-16T10:00:00.000Z',
      );

      final domain = dto.toDomain();
      expect(domain.id, 'notif-002');
      expect(domain.category, NotificationCategory.approvalDecision);
      expect(domain.priority, NotificationPriority.critical);
      expect(domain.referenceModule, CrmModule.hrPayroll);
      expect(domain.referenceEntityId, 'LR-5');
      expect(domain.isRead, isFalse);
    });

    test('fromDomain converts CrmNotification entity to DTO', () {
      final domain = CrmNotification(
        id: 'notif-003',
        recipientUserId: 'usr-003',
        title: 'System Alert',
        body: 'Maintenance scheduled tonight.',
        category: NotificationCategory.systemAlert,
        priority: NotificationPriority.info,
        createdAt: DateTime.utc(2026, 10, 16, 20, 0),
        isRead: false,
      );

      final dto = NotificationDto.fromDomain(domain);
      expect(dto.id, 'notif-003');
      expect(dto.category, 'systemAlert');
      expect(dto.priority, 'info');
      expect(dto.isRead, isFalse);
    });
  });
}
