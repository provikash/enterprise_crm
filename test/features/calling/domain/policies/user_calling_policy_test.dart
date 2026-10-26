import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/calling/domain/entities/follow_up_status.dart';
import 'package:enterprise_crm/features/calling/domain/entities/lead_follow_up.dart';
import 'package:enterprise_crm/features/calling/domain/policies/user_calling_policy.dart';
import 'package:enterprise_crm/features/calling/domain/policies/user_follow_up_policy.dart';
import 'package:enterprise_crm/features/leads/domain/entities/lead.dart';
import 'package:enterprise_crm/features/leads/domain/entities/lead_source.dart';
import 'package:enterprise_crm/features/leads/domain/entities/lead_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const authorizedUser = CurrentUser(
    id: 'usr-1',
    displayName: 'Caller One',
    accountType: AccountType.user,
    modules: {CrmModule.calling, CrmModule.leadManagement},
    permissions: {CrmPermissions.callingUse, CrmPermissions.leadViewAssigned},
  );

  const userWithUpdateAlso = CurrentUser(
    id: 'usr-1',
    displayName: 'Caller One',
    accountType: AccountType.user,
    modules: {CrmModule.calling, CrmModule.leadManagement},
    permissions: {
      CrmPermissions.callingUse,
      CrmPermissions.leadViewAssigned,
      CrmPermissions.leadUpdate,
    },
  );

  const adminUser = CurrentUser(
    id: 'admin-1',
    displayName: 'Admin User',
    accountType: AccountType.admin,
    modules: {CrmModule.calling, CrmModule.leadManagement},
    permissions: {CrmPermissions.callingUse, CrmPermissions.leadViewAssigned},
  );

  final ownLead = Lead(
    id: 'lead-1',
    name: 'Aarav Sharma',
    phone: '+91 9876543210',
    email: 'aarav@example.com',
    status: const LeadStatus('Contacted'),
    source: LeadSource.manual,
    assignedUserId: 'agent-1',
    assignedUserName: 'Sarah Jenkins',
    createdAt: DateTime(2025, 1, 1),
  );

  final crossAssigneeLead = Lead(
    id: 'lead-2',
    name: 'Bob Smith',
    status: const LeadStatus('New'),
    source: LeadSource.excel,
    assignedUserId: 'agent-2',
    createdAt: DateTime(2025, 1, 1),
  );

  final unassignedLead = Lead(
    id: 'lead-3',
    name: 'Charlie Brown',
    status: const LeadStatus('New'),
    source: LeadSource.csv,
    createdAt: DateTime(2025, 1, 1),
  );

  group('UserCallingPolicy - canUseCalling', () {
    test('true when user has calling module and calling.use permission', () {
      expect(UserCallingPolicy.canUseCalling(authorizedUser), isTrue);
    });

    test('false when user lacks calling.use permission', () {
      const user = CurrentUser(
        id: 'usr-1',
        displayName: 'Caller',
        accountType: AccountType.user,
        modules: {CrmModule.calling},
        permissions: {},
      );
      expect(UserCallingPolicy.canUseCalling(user), isFalse);
    });

    test('false when user lacks calling module', () {
      const user = CurrentUser(
        id: 'usr-1',
        displayName: 'Caller',
        accountType: AccountType.user,
        modules: {CrmModule.leadManagement},
        permissions: {CrmPermissions.callingUse},
      );
      expect(UserCallingPolicy.canUseCalling(user), isFalse);
    });

    test('true for admin user (admin has access across all modules)', () {
      expect(UserCallingPolicy.canUseCalling(adminUser), isTrue);
    });
  });

  group(
    'UserCallingPolicy - canRecordActivityForLead & Independence from lead.update',
    () {
      test(
        'true on own lead when user has calling.use and lead.view_assigned (without lead.update)',
        () {
          expect(
            UserCallingPolicy.canRecordActivityForLead(
              user: authorizedUser,
              lead: ownLead,
              linkedAssigneeId: 'agent-1',
            ),
            isTrue,
          );
        },
      );

      test('true on own lead when user also has lead.update', () {
        expect(
          UserCallingPolicy.canRecordActivityForLead(
            user: userWithUpdateAlso,
            lead: ownLead,
            linkedAssigneeId: 'agent-1',
          ),
          isTrue,
        );
      });

      test('false when user lacks Calling module', () {
        const user = CurrentUser(
          id: 'usr-1',
          displayName: 'Caller',
          accountType: AccountType.user,
          modules: {CrmModule.leadManagement},
          permissions: {
            CrmPermissions.callingUse,
            CrmPermissions.leadViewAssigned,
          },
        );
        expect(
          UserCallingPolicy.canRecordActivityForLead(
            user: user,
            lead: ownLead,
            linkedAssigneeId: 'agent-1',
          ),
          isFalse,
        );
      });

      test('false when user lacks calling.use permission', () {
        const user = CurrentUser(
          id: 'usr-1',
          displayName: 'Caller',
          accountType: AccountType.user,
          modules: {CrmModule.calling, CrmModule.leadManagement},
          permissions: {CrmPermissions.leadViewAssigned},
        );
        expect(
          UserCallingPolicy.canRecordActivityForLead(
            user: user,
            lead: ownLead,
            linkedAssigneeId: 'agent-1',
          ),
          isFalse,
        );
      });

      test('false when user lacks Lead Management module', () {
        const user = CurrentUser(
          id: 'usr-1',
          displayName: 'Caller',
          accountType: AccountType.user,
          modules: {CrmModule.calling},
          permissions: {
            CrmPermissions.callingUse,
            CrmPermissions.leadViewAssigned,
          },
        );
        expect(
          UserCallingPolicy.canRecordActivityForLead(
            user: user,
            lead: ownLead,
            linkedAssigneeId: 'agent-1',
          ),
          isFalse,
        );
      });

      test('false when user lacks lead.view_assigned permission', () {
        const user = CurrentUser(
          id: 'usr-1',
          displayName: 'Caller',
          accountType: AccountType.user,
          modules: {CrmModule.calling, CrmModule.leadManagement},
          permissions: {CrmPermissions.callingUse, CrmPermissions.leadUpdate},
        );
        expect(
          UserCallingPolicy.canRecordActivityForLead(
            user: user,
            lead: ownLead,
            linkedAssigneeId: 'agent-1',
          ),
          isFalse,
        );
      });

      test('false on cross-assignee lead', () {
        expect(
          UserCallingPolicy.canRecordActivityForLead(
            user: authorizedUser,
            lead: crossAssigneeLead,
            linkedAssigneeId: 'agent-1',
          ),
          isFalse,
        );
      });

      test('false on unassigned lead', () {
        expect(
          UserCallingPolicy.canRecordActivityForLead(
            user: authorizedUser,
            lead: unassignedLead,
            linkedAssigneeId: 'agent-1',
          ),
          isFalse,
        );
      });

      test('false when linkedAssigneeId is null or empty', () {
        expect(
          UserCallingPolicy.canRecordActivityForLead(
            user: authorizedUser,
            lead: ownLead,
            linkedAssigneeId: null,
          ),
          isFalse,
        );
        expect(
          UserCallingPolicy.canRecordActivityForLead(
            user: authorizedUser,
            lead: ownLead,
            linkedAssigneeId: '   ',
          ),
          isFalse,
        );
      });

      test('true for admin user (admin has all power)', () {
        expect(
          UserCallingPolicy.canRecordActivityForLead(
            user: adminUser,
            lead: ownLead,
            linkedAssigneeId: 'agent-1',
          ),
          isTrue,
        );
      });
    },
  );

  group('UserCallingPolicy - canViewLeadHistory', () {
    test('mirrors canRecordActivityForLead security gates', () {
      expect(
        UserCallingPolicy.canViewLeadHistory(
          user: authorizedUser,
          lead: ownLead,
          linkedAssigneeId: 'agent-1',
        ),
        isTrue,
      );
      expect(
        UserCallingPolicy.canViewLeadHistory(
          user: authorizedUser,
          lead: crossAssigneeLead,
          linkedAssigneeId: 'agent-1',
        ),
        isFalse,
      );
    });

    test('authorizes user with callingHistoryView permission', () {
      const user = CurrentUser(
        id: 'usr-hist',
        displayName: 'Auditor',
        accountType: AccountType.user,
        modules: {CrmModule.calling, CrmModule.leadManagement},
        permissions: {
          CrmPermissions.callingHistoryView,
          CrmPermissions.leadViewAssigned,
        },
      );
      expect(
        UserCallingPolicy.canViewLeadHistory(
          user: user,
          lead: ownLead,
          linkedAssigneeId: 'agent-1',
        ),
        isTrue,
      );
    });
  });

  group('UserCallingPolicy - Granular calling permissions', () {
    test('canUseCalling returns true with callingView', () {
      const user = CurrentUser(
        id: 'usr-v',
        displayName: 'Viewer',
        accountType: AccountType.user,
        modules: {CrmModule.calling},
        permissions: {CrmPermissions.callingView},
      );
      expect(UserCallingPolicy.canUseCalling(user), isTrue);
    });

    test('canRecordActivityForLead returns true with callingRecordOutcome', () {
      const user = CurrentUser(
        id: 'usr-rec',
        displayName: 'Recorder',
        accountType: AccountType.user,
        modules: {CrmModule.calling, CrmModule.leadManagement},
        permissions: {
          CrmPermissions.callingRecordOutcome,
          CrmPermissions.leadViewAssigned,
        },
      );
      expect(
        UserCallingPolicy.canRecordActivityForLead(
          user: user,
          lead: ownLead,
          linkedAssigneeId: 'agent-1',
        ),
        isTrue,
      );
    });
  });

  group('UserFollowUpPolicy', () {
    final pendingFollowUp = LeadFollowUp(
      id: 'fu-1',
      leadId: ownLead.id,
      sourceCallActivityId: 'act-1',
      scheduledAt: DateTime(2026, 10, 1),
      status: FollowUpStatus.pending,
      createdAt: DateTime(2026, 9, 20),
      updatedAt: DateTime(2026, 9, 20),
    );

    test('authorizes with callingFollowUpManage permission', () {
      const user = CurrentUser(
        id: 'usr-fu',
        displayName: 'Followup Agent',
        accountType: AccountType.user,
        modules: {CrmModule.calling, CrmModule.leadManagement},
        permissions: {
          CrmPermissions.callingFollowUpManage,
          CrmPermissions.leadViewAssigned,
        },
      );
      expect(UserFollowUpPolicy.canManageFollowUps(user), isTrue);
      expect(
        UserFollowUpPolicy.canActOnFollowUp(
          user: user,
          lead: ownLead,
          linkedAssigneeId: 'agent-1',
          followUp: pendingFollowUp,
        ),
        isTrue,
      );
    });

    test('denies follow up management when missing permission', () {
      const user = CurrentUser(
        id: 'usr-no-fu',
        displayName: 'Viewer',
        accountType: AccountType.user,
        modules: {CrmModule.calling, CrmModule.leadManagement},
        permissions: {
          CrmPermissions.callingView,
          CrmPermissions.leadViewAssigned,
        },
      );
      expect(UserFollowUpPolicy.canManageFollowUps(user), isFalse);
    });
  });
}
