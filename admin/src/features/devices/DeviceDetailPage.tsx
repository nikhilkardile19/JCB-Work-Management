import { useState } from 'react'
import { Link, useParams } from 'react-router'
import { Async, DefinitionList, StatusBadge } from '../../components/data'
import { ReasonDialog } from '../../components/dialogs'
import { Icon } from '../../components/Icon'
import { Button, Card, EmptyState, PageHeader } from '../../components/ui'
import { useAdminApi, type Device } from '../../lib/adminApi'
import { useAdminProfile } from '../../lib/adminProfile'
import { fmtDateTime, shortId } from '../../lib/format'
import { useAsync } from '../../lib/hooks'
import { useToast } from '../../lib/toast'
import { EventList } from '../audit/EventList'

export function DeviceDetailPage() {
  const { companyId = '', deviceId = '' } = useParams()
  const api = useAdminApi()
  const { can } = useAdminProfile()
  const toast = useToast()
  const device = useAsync(() => api.getDevice(companyId, deviceId), [api, companyId, deviceId])
  const events = useAsync(async () => (await api.listEvents({ deviceId })).items, [api, deviceId])
  const [revoking, setRevoking] = useState(false)

  return (
    <Async state={device}>
      {(d: Device | null) =>
        !d ? (
          <EmptyState icon="phone" title="Device not found" action={<Link to="/devices">Back to devices</Link>} />
        ) : (
          <>
            <Link to="/devices" className="back-link">
              <Icon name="arrowLeft" size={16} /> Devices
            </Link>
            <PageHeader
              title={d.deviceModel ?? 'Phone'}
              subtitle={`Device ${d.id}`}
              actions={
                <div className="actions-row">
                  <StatusBadge status={d.status} />
                  {can('devices.revoke') && d.status === 'active' && (
                    <Button variant="danger" onClick={() => setRevoking(true)}>
                      Revoke
                    </Button>
                  )}
                </div>
              }
            />
            <Card>
              <DefinitionList
                items={[
                  ['Company', <Link key="company" to={`/companies/${d.companyId}`}>{shortId(d.companyId)}</Link>],
                  ['License', <Link key="license" to={`/licenses/${d.companyId}/${d.licenseId}`}>{shortId(d.licenseId)}</Link>],
                  ['User', shortId(d.userId)],
                  ['Activated', fmtDateTime(d.activatedAt)],
                  ['Last seen', fmtDateTime(d.lastSeenAt)],
                  ...(d.replacementForDeviceId
                    ? ([['Replaced phone', <Link key="old" to={`/devices/${d.companyId}/${d.replacementForDeviceId}`}>{shortId(d.replacementForDeviceId)}</Link>]] as [string, React.ReactNode][])
                    : []),
                  ...(d.replacedBy
                    ? ([['Replaced by', <Link key="new" to={`/devices/${d.companyId}/${d.replacedBy}`}>{shortId(d.replacedBy)}</Link>]] as [string, React.ReactNode][])
                    : []),
                  ...(d.revokeReason ? ([['Revoked because', d.revokeReason]] as [string, string][]) : []),
                ]}
              />
            </Card>
            <Card>
              <h2>History</h2>
              <Async state={events}>{(rows) => <EventList events={rows} />}</Async>
            </Card>
            {revoking && (
              <ReasonDialog
                title="Revoke this phone?"
                message="It frees a place on the license. The phone keeps its local data but cannot sync changes once it reconnects."
                submitLabel="Revoke phone"
                danger
                onClose={() => setRevoking(false)}
                onConfirm={async (reason) => {
                  await api.revokeDevice(d.companyId, d.id, reason)
                  toast('Phone revoked')
                  device.reload()
                  events.reload()
                }}
              />
            )}
          </>
        )
      }
    </Async>
  )
}
