import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../configuration/domain/payroll_configuration_repository.dart';
import '../../configuration/presentation/bloc/payroll_configuration_cubit.dart';
import '../../configuration/presentation/screens/payroll_configuration_screen.dart';
import '../../operations/domain/payroll_operations_repository.dart';
import '../../operations/presentation/bloc/payroll_operations_cubit.dart';
import '../../operations/presentation/screens/payroll_operations_screen.dart';
import '../../shared/domain/payroll_access_policy.dart';
import '../screens/payroll_home_screen.dart';

abstract final class PayrollRoutes {
  static const home = '/payroll';
  static const configuration = '/payroll/config/components';
  static const structures = '/payroll/config/structures';
  static const statutory = '/payroll/config/statutory';
  static const payGroups = '/payroll/config/pay-groups';
  static const compensation = '/payroll/compensation';
  static const inputs = '/payroll/inputs';
  static const runs = '/payroll/runs';
  static const payslips = '/payroll/payslips';
  static const payments = '/payroll/payments';
  static const reports = '/payroll/reports';

  static Route<dynamic>? onGenerateRoute(
    RouteSettings settings, {
    required CurrentUser? user,
    required AppConfig config,
    required PayrollConfigurationRepository configurationRepository,
    required PayrollOperationsRepository operationsRepository,
  }) {
    final routeName = settings.name;
    if (routeName == null || !routeName.startsWith('/payroll')) return null;
    Widget screen;
    if (user == null || !PayrollAccessPolicy.canEnter(user)) {
      screen = const AccessRestrictedScreen();
    } else if (routeName == home &&
        config.isPayrollEnabled(PayrollFeature.foundations)) {
      screen = PayrollHomeScreen(user: user, config: config);
    } else if (_configurationTab(routeName) case final tab?
        when config.isPayrollEnabled(PayrollFeature.configuration)) {
      screen = BlocProvider(
        create: (_) =>
            PayrollConfigurationCubit(configurationRepository)..load(),
        child: PayrollConfigurationScreen(
          user: user,
          initialTab: tab,
          config: config,
        ),
      );
    } else if (_workspace(routeName) case final workspace?
        when _workspaceEnabled(config, workspace)) {
      screen = BlocProvider(
        create: (_) => PayrollOperationsCubit(operationsRepository)..load(),
        child: PayrollOperationsScreen(
          user: user,
          workspace: workspace,
          config: config,
        ),
      );
    } else {
      screen = const AccessRestrictedScreen();
    }
    return MaterialPageRoute<void>(settings: settings, builder: (_) => screen);
  }

  static int? _configurationTab(String routeName) => switch (routeName) {
    configuration => 0,
    structures => 1,
    statutory => 2,
    payGroups => 3,
    _ => null,
  };

  static PayrollWorkspace? _workspace(String routeName) => switch (routeName) {
    compensation => PayrollWorkspace.compensation,
    inputs => PayrollWorkspace.inputs,
    runs => PayrollWorkspace.runs,
    payslips => PayrollWorkspace.payslips,
    payments => PayrollWorkspace.payments,
    reports => PayrollWorkspace.reports,
    _ => null,
  };

  static bool _workspaceEnabled(
    AppConfig config,
    PayrollWorkspace workspace,
  ) => switch (workspace) {
    PayrollWorkspace.compensation => config.isPayrollEnabled(
      PayrollFeature.employeeCompensation,
    ),
    PayrollWorkspace.inputs => config.isPayrollEnabled(PayrollFeature.inputs),
    PayrollWorkspace.runs => config.isPayrollEnabled(PayrollFeature.payRuns),
    PayrollWorkspace.payslips => config.isPayrollEnabled(
      PayrollFeature.payslips,
    ),
    PayrollWorkspace.payments => config.isPayrollEnabled(
      PayrollFeature.payments,
    ),
    PayrollWorkspace.reports => config.isPayrollEnabled(PayrollFeature.reports),
  };
}
