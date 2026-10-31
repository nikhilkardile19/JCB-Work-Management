import { useState } from 'react'
import { Link, useParams } from 'react-router'
import { Async, DataTable, DefinitionList, StatusBadge } from '../../components/data'
import { ActionDialog, CodeDialog, ReasonDialog } from '../../components/dialogs'
import { Icon } from '../../components/Icon'
import { Button, Card, EmptyState, PageHeader, TextField } from '../../components/ui'
import { useAdminApi, type IssuedCode, type License } from '../../lib/adminApi'
import { useAdminProfile } from '../../lib/adminProfile'
import { daysUntil, fmtDate, fmtDateTime, fromDateInput, shortId, toDateInput } from '../../lib/format'
import { useAsync } from '../../lib/hooks'
import { useToast } from '../../lib/toast'
import { EventList } from '../audit/EventList'

type Dialog =
  | { kind: 'status'; to: 'active' | 'suspended' | 'revoked' }
  | { kind: 'extend' }
  | { kind: 'devices' }
  | { kind: 'rotate' }

const STATUS_COPY = {
  active: { label: 'Reactivate', message: 'Phones on this license can sync again after their next check.' },
  suspended: { label: 'Suspend', message: 'Phones become read-only at their next check. Nothing is deleted.' },
  revoked: { label: 'Revoke', message: 'Permanent. Phones become read-only and the license cannot be reactivated.' },
} as const

export function LicenseDetailPage() {
  const { companyId = '', licenseId = '' } = useParams()
  const api = useAdminApi()
  const { can } = useAdminProfile()
  const toast = useToast()
  const license = useAsync(() => api.getLicense(companyId, licenseId), [api, companyId, licenseId])
  const devices = useAsync(async () => (await api.listDevices({ companyId, licenseId })).items, [api, companyId, licenseId])
  const events = useAsync(async () => (await api.listEvents({ licenseId })).items, [api, licenseId])
  const [dialog, setDialog] = useState<Dialog | null>(null)
  const [issued, setIssued] = useState<IssuedCode | null>(null)
  const [until, setUntil] = useState('')
  const [maxDevices, setMaxDevices] = useState('')
  const [reason, setReason] = useState('')
  const refresh = () => [license, events, devices].forEach((s) => s.reload())
  const manage = can('licenses.manage')

  return (
    <Async state={license}>
      {(l: License | null) =>
        !l ? (
          <EmptyState icon="key" title="License not found" action={<Link to="/licenses">Back to licenses</Link>} />
        ) : (
          <>
            <Link to="/licenses" className="back-link">
              <Icon name="arrowLeft" size={16} /> Licenses
            </Link>
            <PageHeader
              title={l.companyName ?? `License ${shortId(l.id)}`}
              subtitle={`License ${l.id}`}
              actions={
                <div className="actions-row">
                  <StatusBadge status={l.status} />
                  {manage && l.status !== 'revoked' && (
                    <>
                      {l.status === 'active' && <Button variant="secondary" onClick={() => setDialog({ kind: 'status', to: 'suspended' })}>Suspend</Button>}
                      {l.status === 'suspended' && <Button onClick={() => setDialog({ kind: 'status', to: 'active' })}>Reactivate</Button>}
                      <Button variant="danger" onClick={() => setDialog({ kind: 'status', to: 'revoked' })}>Revoke</Button>
                    </>
                  )}
                </div>
              }
            />
            <div className="detail-grid">
              <Card>
                <div className="card-head">
                  <h2>Terms</h2>
                  {manage && l.status !== 'revoked' && (
                    <div className="actions-row">
                      <Button variant="secondary" onClick={() => (setUntil(toDateInput(Math.max(l.validUntil, Date.now()) + 365 * 86_400_000)), setReason(''), setDialog({ kind: 'extend' }))}>
                        Extend
                      </Button>
                      <Button variant="secondary" onClick={() => (setMaxDevices(String(l.maxDevices)), setReason(''), setDialog({ kind: 'devices' }))}>
                        Change phones
                      </Button>
                    </div>
                  )}
                </div>
                <DefinitionList
                  items={[
                    ['Company', <Link key="company" to={`/companies/${l.companyId}`}>{l.companyName ?? shortId(l.companyId)}</Link>],
                    ['Starts', fmtDate(l.validFrom)],
                    ['Ends', `${fmtDate(l.validUntil)}${l.status === 'active' ? ` (${daysUntil(l.validUntil)} days)` : ''}`],
                    ['Phones allowed', l.maxDevices],
                    ['Last checked by a phone', fmtDateTime(l.lastValidatedAt)],
                  ]}
                />
              </Card>
              <Card>
                <div className="card-head">
                  <h2>Activation code</h2>
                </div>
                {l.activationCodeUsedAt ? (
                  <p>
                    Used {fmtDateTime(l.activationCodeUsedAt)}
                    {l.activationCodeDeviceId && (
                      <>
                        {' '}
                        by <Link to={`/devices/${l.companyId}/${l.activationCodeDeviceId}`}>phone {shortId(l.activationCodeDeviceId)}</Link>
                      </>
                    )}
                    . Codes work once: issue a new code to activate another phone.
                  </p>
                ) : (
                  <p>Not used yet. It works once, on one phone.</p>
                )}
                <p>Only a fingerprint of the code is stored, so it cannot be shown again. Issue a new code if the owner lost it or it was shared.</p>
                {manage && l.status !== 'revoked' && (
                  <Button variant="secondary" onClick={() => setDialog({ kind: 'rotate' })}>
                    Issue new code
                  </Button>
                )}
              </Card>
            </div>
            <Card>
              <h2>Phones on this license</h2>
              <Async state={devices}>
                {(rows) => (
                  <DataTable
                    caption="Phones"
                    rows={rows}
                    rowKey={(d) => d.id}
                    columns={[
                      { header: 'Phone', cell: (d) => <Link to={`/devices/${d.companyId}/${d.id}`}>{d.deviceModel ?? 'Phone'} · {shortId(d.id)}</Link> },
                      { header: 'Status', cell: (d) => <StatusBadge status={d.status} /> },
                      { header: 'Last seen', cell: (d) => fmtDateTime(d.lastSeenAt) },
                    ]}
                    empty={<EmptyState icon="phone" title="No phones activated yet" />}
                  />
                )}
              </Async>
            </Card>
            <Card>
              <h2>History</h2>
              <Async state={events}>{(rows) => <EventList events={rows} />}</Async>
            </Card>

            {dialog?.kind === 'status' && (
              <ReasonDialog
                title={`${STATUS_COPY[dialog.to].label} license?`}
                message={STATUS_COPY[dialog.to].message}
                submitLabel={STATUS_COPY[dialog.to].label}
                danger={dialog.to !== 'active'}
                onClose={() => setDialog(null)}
                onConfirm={async (r) => {
                  await api.setLicenseStatus(l.companyId, l.id, dialog.to, r)
                  toast(`License ${dialog.to === 'active' ? 'reactivated' : dialog.to}`)
                  refresh()
                }}
              />
            )}
            {dialog?.kind === 'rotate' && (
              <ReasonDialog
                title="Issue a new activation code?"
                message="The current code stops working immediately. Phones already activated are not affected."
                submitLabel="Issue new code"
                onClose={() => setDialog(null)}
                onConfirm={async (r) => {
                  setIssued(await api.rotateActivationCode(l.companyId, l.id, r))
                  refresh()
                }}
              />
            )}
            {(dialog?.kind === 'extend' || dialog?.kind === 'devices') && (
              <ActionDialog
                title={dialog.kind === 'extend' ? 'Extend license' : 'Change phones allowed'}
                submitLabel="Save"
                onClose={() => setDialog(null)}
                onSubmit={async () => {
                  if (reason.trim().length < 3) throw new Error('Enter a reason (at least 3 characters).')
                  const changes = dialog.kind === 'extend' ? { validUntil: fromDateInput(until) } : { maxDevices: Number(maxDevices) }
                  await api.updateLicense(l.companyId, l.id, changes, reason.trim())
                  toast('License updated')
                  refresh()
                }}
              >
                {dialog.kind === 'extend' ? (
                  <TextField label="New end date" type="date" value={until} onChange={(e) => setUntil(e.target.value)} />
                ) : (
                  <TextField label="Phones allowed" type="number" min={1} max={100} value={maxDevices} onChange={(e) => setMaxDevices(e.target.value)} />
                )}
                <TextField label="Reason" value={reason} onChange={(e) => setReason(e.target.value)} hint="Kept in the license history." />
              </ActionDialog>
            )}
            {issued && <CodeDialog code={issued.activationCode} emailedTo={issued.emailedTo} onClose={() => setIssued(null)} />}
          </>
        )
      }
    </Async>
  )
}
