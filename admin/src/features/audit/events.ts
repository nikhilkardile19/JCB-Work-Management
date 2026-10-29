import type { AuditEvent } from '../../lib/adminApi'

const LABELS: Record<string, string> = {
  'company.create': 'Company created',
  'company.update': 'Company edited',
  'company.status': 'Company status changed',
  'license.create': 'License created',
  'license.status': 'License status changed',
  'license.update': 'License changed',
  'license.rotate_code': 'Activation code replaced',
  'device.activate': 'Phone activated',
  'device.revalidate': 'Phone re-activated',
  'device.activate_denied': 'Activation refused',
  'device.revoke': 'Phone revoked',
  'replacement.request': 'Replacement requested',
  'replacement.approve': 'Replacement approved',
  'replacement.reject': 'Replacement rejected',
  'user.invite': 'User added',
  'user.reinvite': 'User re-added',
  'user.role': 'User role changed',
  'user.status': 'User access changed',
}

export const eventTypes = Object.keys(LABELS)

export function eventLabel(e: AuditEvent): string {
  return LABELS[e.type] ?? e.type
}

/** One-line description of what changed. */
export function eventSummary(e: AuditEvent): string {
  const d = e.details as Record<string, unknown>
  const parts: string[] = []
  if (typeof d.from === 'string' && typeof d.to === 'string') parts.push(`${d.from} → ${d.to}`)
  if (typeof d.to === 'string' && d.from === undefined) parts.push(`→ ${d.to}`)
  if (d.changed && typeof d.changed === 'object') parts.push(`Changed: ${Object.keys(d.changed).join(', ')}`)
  if (typeof d.reason === 'string' && e.type === 'device.activate_denied') parts.push(`Reason: ${d.reason.replace('_', ' ')}`)
  if (e.reason) parts.push(`“${e.reason}”`)
  if (typeof d.name === 'string') parts.push(d.name)
  return parts.join(' · ')
}
