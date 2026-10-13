import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../shared/domain/money.dart';
import '../../shared/domain/payroll_access_policy.dart';
import '../../shared/domain/payroll_status.dart';
import '../../shared/presentation/widgets/masked_field.dart';
import '../../shared/presentation/widgets/money_field.dart';
import '../../shared/presentation/widgets/money_text.dart';
import '../../shared/presentation/widgets/payroll_states.dart';
import '../../shared/presentation/widgets/payroll_status_chip.dart';
import '../../shared/presentation/widgets/stepper_header.dart';
import '../../shared/presentation/widgets/summary_strip.dart';

class PayrollWidgetGalleryScreen extends StatefulWidget {
  final CurrentUser user;
  const PayrollWidgetGalleryScreen({super.key, required this.user});

  @override
  State<PayrollWidgetGalleryScreen> createState() =>
      _PayrollWidgetGalleryScreenState();
}

class _PayrollWidgetGalleryScreenState
    extends State<PayrollWidgetGalleryScreen> {
  final _moneyController = TextEditingController(text: '125000.50');

  @override
  void dispose() {
    _moneyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || !PayrollAccessPolicy.canEnter(widget.user)) {
      return const AccessRestrictedScreen();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Payroll widget gallery')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in PayrollStatus.values)
                PayrollStatusChip(status: status),
            ],
          ),
          const SizedBox(height: 24),
          SummaryStrip(
            items: const [
              SummaryItem(
                label: 'Gross',
                value: MoneyText(value: Money(8250000)),
                icon: Icons.trending_up,
              ),
              SummaryItem(
                label: 'Net',
                value: MoneyText(value: Money(6942500)),
                icon: Icons.account_balance_wallet_outlined,
              ),
              SummaryItem(
                label: 'Adjustment',
                value: MoneyText(value: Money(-25000)),
                icon: Icons.tune,
              ),
            ],
          ),
          const SizedBox(height: 24),
          MoneyField(controller: _moneyController, label: 'Amount'),
          const SizedBox(height: 12),
          const MaskedField(
            label: 'Bank account',
            value: '123456789012',
            canReveal: true,
          ),
          const SizedBox(height: 24),
          const StepperHeader(
            steps: [
              'Draft',
              'Calculated',
              'Under Review',
              'Approved',
              'Locked',
              'Paid',
            ],
            currentIndex: 2,
          ),
          const SizedBox(height: 24),
          const LockedBanner(),
          const SizedBox(height: 24),
          const PayrollSkeleton(rows: 3),
        ],
      ),
    );
  }
}
