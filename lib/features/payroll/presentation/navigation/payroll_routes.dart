import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../configuration/data/mock_payroll_configuration_repository.dart';
import '../../configuration/presentation/bloc/payroll_configuration_cubit.dart';
import '../../configuration/presentation/screens/payroll_configuration_screen.dart';
import '../../shared/domain/payroll_access_policy.dart';
import '../screens/payroll_home_screen.dart';
import '../screens/payroll_widget_gallery_screen.dart';

abstract final class PayrollRoutes {
  static const home = '/payroll';
  static const gallery = '/payroll/gallery';
  static const configuration = '/payroll/config/components';
  static const structures = '/payroll/config/structures';
  static const statutory = '/payroll/config/statutory';
  static const payGroups = '/payroll/config/pay-groups';

  static Route<dynamic>? onGenerateRoute(
    RouteSettings settings, {
    required CurrentUser? user,
    required AppConfig config,
  }) {
    final routeName = settings.name;
    if (routeName == null || !routeName.startsWith('/payroll')) return null;
    Widget screen;
    if (user == null || !PayrollAccessPolicy.canEnter(user)) {
      screen = const AccessRestrictedScreen();
    } else if (routeName == home &&
        config.isPayrollEnabled(PayrollFeature.foundations)) {
      screen = PayrollHomeScreen(user: user, config: config);
    } else if (routeName == gallery &&
        kDebugMode &&
        config.isPayrollEnabled(PayrollFeature.widgetGallery)) {
      screen = PayrollWidgetGalleryScreen(user: user);
    } else if (_configurationTab(routeName) case final tab?
        when config.isPayrollEnabled(PayrollFeature.configuration)) {
      screen = BlocProvider(
        create: (_) =>
            PayrollConfigurationCubit(MockPayrollConfigurationRepository())
              ..load(),
        child: PayrollConfigurationScreen(user: user, initialTab: tab),
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
}
