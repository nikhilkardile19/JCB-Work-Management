/// Company roles (sprint doc §3.2). Mirrors a member's `role` on the server,
/// which enforces the same model.
enum CompanyRole {
  owner('Owner'),
  admin('Admin'),
  manager('Manager'),
  operator('Operator'),
  accounts('Accounts');

  const CompanyRole(this.label);

  final String label;

  static CompanyRole? parse(String? v) =>
      CompanyRole.values.where((r) => r.name == v).firstOrNull;

  bool can(Permission p) => _grants[this]!.contains(p);
}

enum Permission {
  manageCompany,
  manageUsers,
  manageMasters,
  createWorkLogs,
  approveWorkLogs,
  recordFuel,
  manageInvoices,
  recordPayments,
  viewReports,
  requestDeviceReplacement,
}

const _all = {...Permission.values};

const Map<CompanyRole, Set<Permission>> _grants = {
  CompanyRole.owner: _all,
  CompanyRole.admin: _all,
  CompanyRole.manager: {
    Permission.createWorkLogs,
    Permission.approveWorkLogs,
    Permission.recordFuel,
    Permission.viewReports,
  },
  CompanyRole.operator: {Permission.createWorkLogs, Permission.recordFuel},
  CompanyRole.accounts: {
    Permission.manageInvoices,
    Permission.recordPayments,
    Permission.viewReports,
  },
};
