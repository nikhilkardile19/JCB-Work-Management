import '../features/masters/domain/master_kind.dart';
import '../features/reports/domain/reports.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const forgotPassword = '/login/forgot';
  static const signUp = '/login/signup';
  static const companySetup = '/setup/company';
  static const selectCompany = '/setup/select-company';
  static const companyStatus = '/setup/status';
  static const activate = '/setup/activate';
  static const replacement = '/setup/replacement';
  static const dashboard = '/dashboard';
  static const work = '/work';
  static const fuel = '/fuel';
  static const billing = '/billing';
  static const more = '/more';
  static const companyProfile = '/more/company';
  static const components = '/more/components';
  static const sync = '/more/sync';
  static const license = '/more/license';
  static const users = '/more/users';
  static const privacy = '/more/privacy';
  static const reports = '/more/reports';
  static String report(ReportKind k) => '$reports/${k.name}';
  static String reportPdf(ReportKind k) => '${report(k)}/pdf';

  static const workNew = '/work/new';
  static String workDetail(String id) => '/work/$id';
  static String workEdit(String id) => '/work/$id/edit';
  static String workCorrect(String id) => '/work/$id/correct';

  static const fuelNew = '/fuel/new';
  static String fuelDetail(String id) => '/fuel/$id';
  static String fuelEdit(String id) => '/fuel/$id/edit';

  static const invoiceNew = '/billing/new';
  static String invoiceDetail(String id) => '/billing/$id';
  static String invoiceEdit(String id) => '/billing/$id/edit';
  static String invoicePdf(String id) => '/billing/$id/pdf';

  static String masterList(MasterKind k) => '/more/masters/${k.slug}';
  static String masterNew(MasterKind k, {String? clientId}) =>
      '${masterList(k)}/new${clientId == null ? '' : '?clientId=$clientId'}';
  static String masterDetail(MasterKind k, String id) => '${masterList(k)}/$id';
  static String masterEdit(MasterKind k, String id) =>
      '${masterDetail(k, id)}/edit';

  /// Routes only meaningful before the user reaches the app shell.
  static const gate = {
    splash,
    login,
    forgotPassword,
    signUp,
    companySetup,
    selectCompany,
    companyStatus,
    activate,
    replacement,
  };

  /// Screens that create or change records (blocked when read-only).
  static bool isWriteRoute(String location) =>
      RegExp(r'/(new|edit|correct)$').hasMatch(location);
}
