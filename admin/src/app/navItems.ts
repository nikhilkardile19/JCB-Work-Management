import type { IconName } from '../components/Icon'

export const navItems: { to: string; label: string; icon: IconName }[] = [
  { to: '/', label: 'Dashboard', icon: 'dashboard' },
  { to: '/companies', label: 'Companies', icon: 'building' },
  { to: '/licenses', label: 'Licenses', icon: 'key' },
  { to: '/devices', label: 'Devices', icon: 'phone' },
  { to: '/replacement-requests', label: 'Replacement requests', icon: 'swap' },
  { to: '/audit-logs', label: 'Audit logs', icon: 'history' },
]
