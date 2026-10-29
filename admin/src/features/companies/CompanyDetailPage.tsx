import { useState } from 'react'
import { Link, useParams } from 'react-router'
import { Async, DataTable, DefinitionList, StatusBadge } from '../../components/data'
import { CodeDialog, ReasonDialog } from '../../components/dialogs'
import { Icon } from '../../components/Icon'
import { Button, Card, EmptyState, PageHeader } from '../../components/ui'
import { useAdminApi, type Company, type CompanyStatus } from '../../lib/adminApi'
import { useAdminProfile } from '../../lib/adminProfile'
import { daysUntil, fmtDate, fmtDateTime, shortId } from '../../lib/format'
import { useAsync } from '../../lib/hooks'
import { useToast } from '../../lib/toast'
import { EventList } from '../audit/EventList'
import { NewLicenseDialog } from '../licenses/NewLicenseDialog'
import { CompanyForm } from './CompanyForm'

const STATUS_ACTIONS: Record<CompanyStatus, { to: CompanyStatus; label: string; danger?: boolean; message: string }[]> = {
  pending: [{ to: 'active', label: 'Approve', message: 'The company can use the app once a license is issued.' }],
  active: [{ to: 'suspended', label: 'Suspend', danger: true, message: 'Members keep their data but cannot sync or activate phones until reactivated.' }],
  suspended: [{ to: 'active', label: 'Reactivate', message: 'Members can sync and activate phones again.' }],
}

export function CompanyDetailPage() {
  const { companyId = '' } = useParams()
  const api = useAdminApi()
  const { can } = useAdminProfile()
  const toast = useToast()
  const company = useAsync(() => api.getCompany(companyId), [api, companyId])
  const members = useAsync(() => api.companyMembers(companyId), [api, companyId])
  const licenses = useAsync(async () => (await api.listLicenses({ companyId })).items, [api, companyId])
  const devices = useAsync(async () => (await api.listDevices({ companyId })).items, [api, companyId])
  const events = useAsync(async () => (await api.listEvents({ companyId })).items, [api, companyId])
  const [statusChange, setStatusChange] = useState<(typeof STATUS_ACTIONS)['active'][number] | null>(null)
  const [editing, setEditing] = useState(false)
  const [newLicense, setNewLicense] = useState(false)
  const [code, setCode] = useState<string | null>(null)
  const refresh = () => [company, licenses, events].forEach((s) => s.reload())

  return (
    <Async state={company}>
      {(c: Company | null) =>
        !c ? (
          <EmptyState icon="building" title="Company not found" action={<Link to="/companies">Back to companies</Link>} />
        ) : (
          <>
            <Link to="/companies" className="back-link">
              <Icon name="arrowLeft" size={16} /> Companies
            </Link>
            <PageHeader
              title={c.name}
              subtitle={`Company ID ${c.id}`}
              actions={
                <div className="actions-row">
                  <StatusBadge status={c.status} />
                  {can('companies.manage') &&
                    STATUS_ACTIONS[c.status].map((a) => (
                      <Button key={a.to} variant={a.danger ? 'danger' : 'primary'} onClick={() => setStatusChange(a)}>
                        {a.label}
                      </Button>
                    ))}
                </div>
              }
            />
            <div className="detail-grid">
              <Card>
                <div className="card-head">
                  <h2>Profile</h2>
                  {can('companies.manage') && (
                    <Button variant="secondary" onClick={() => setEditing(true)}>
                      Edit
                    </Button>
                  )}
                </div>
                <DefinitionList
                  items={[
                    ['Contact person', c.contactPerson],
                    ['Phone', c.phone],
                    ['Email', c.email],
                    ['Address', c.address],
                    ['GSTIN', c.gstin],
                    ['Invoice prefix', c.invoicePrefix],
                    ['Registered', fmtDate(c.createdAt)],
                  ]}
                />
              </Card>
              <Card>
                <h2>Members</h2>
                <Async state={members}>
                  {(rows) => (
                    <DataTable
                      caption="Members"
                      rows={rows}
                      rowKey={(m) => m.uid}
                      columns={[
                        { header: 'Email', cell: (m) => m.email ?? shortId(m.uid) },
                        { header: 'Role', cell: (m) => m.role },
                        { header: 'Status', cell: (m) => <StatusBadge status={m.status} /> },
                      ]}
                      empty={<EmptyState icon="building" title="No members" />}
                    />
                  )}
                </Async>
              </Card>
            </div>
            <Card>
              <div className="card-head">
                <h2>Licenses</h2>
                {can('licenses.manage') && c.status === 'active' && (
                  <Button icon="plus" onClick={() => setNewLicense(true)}>
                    New license
                  </Button>
                )}
              </div>
              <Async state={licenses}>
                {(rows) => (
                  <DataTable
                    caption="Licenses"
                    rows={rows}
                    rowKey={(l) => l.id}
                    columns={[
                      { header: 'License', cell: (l) => <Link to={`/licenses/${c.id}/${l.id}`}>{shortId(l.id)}</Link> },
                      { header: 'Status', cell: (l) => <StatusBadge status={l.status} /> },
                      { header: 'Valid until', cell: (l) => `${fmtDate(l.validUntil)}${l.status === 'active' ? ` (${daysUntil(l.validUntil)} days)` : ''}` },
                      { header: 'Phones', cell: (l) => l.maxDevices, secondary: true },
                    ]}
                    empty={
                      <EmptyState
                        icon="key"
                        title="No license yet"
                        message={c.status === 'active' ? 'Create a license and give the activation code to the owner.' : 'Approve the company before issuing a license.'}
                      />
                    }
                  />
                )}
              </Async>
            </Card>
            <Card>
              <h2>Phones</h2>
              <Async state={devices}>
                {(rows) => (
                  <DataTable
                    caption="Phones"
                    rows={rows}
                    rowKey={(d) => d.id}
                    columns={[
                      { header: 'Phone', cell: (d) => <Link to={`/devices/${c.id}/${d.id}`}>{d.deviceModel ?? 'Phone'} · {shortId(d.id)}</Link> },
                      { header: 'Status', cell: (d) => <StatusBadge status={d.status} /> },
                      { header: 'Last seen', cell: (d) => fmtDateTime(d.lastSeenAt) },
                    ]}
                    empty={<EmptyState icon="phone" title="No phones activated" />}
                  />
                )}
              </Async>
            </Card>
            <Card>
              <h2>Activity</h2>
              <Async state={events}>{(rows) => <EventList events={rows} />}</Async>
            </Card>

            {statusChange && (
              <ReasonDialog
                title={`${statusChange.label} ${c.name}?`}
                message={statusChange.message}
                submitLabel={statusChange.label}
                danger={statusChange.danger}
                onClose={() => setStatusChange(null)}
                onConfirm={async (reason) => {
                  await api.setCompanyStatus(c.id, statusChange.to, reason)
                  toast(`${c.name} is now ${statusChange.to}`)
                  refresh()
                }}
              />
            )}
            {editing && (
              <CompanyForm
                initial={c}
                withOwner={false}
                title="Edit company"
                submitLabel="Save changes"
                onClose={() => setEditing(false)}
                onSubmit={async (p) => {
                  const { ownerEmail: _, ...profile } = p
                  await api.updateCompany(c.id, profile)
                  toast('Company saved')
                  refresh()
                }}
              />
            )}
            {newLicense && (
              <NewLicenseDialog
                companyId={c.id}
                onClose={() => setNewLicense(false)}
                onCreated={(activationCode) => {
                  setCode(activationCode)
                  refresh()
                }}
              />
            )}
            {code && <CodeDialog code={code} onClose={() => setCode(null)} />}
          </>
        )
      }
    </Async>
  )
}
