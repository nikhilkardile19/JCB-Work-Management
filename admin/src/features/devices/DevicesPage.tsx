import { Link, useSearchParams } from 'react-router'
import { Async, DataTable, FilterTabs, LoadMore, StatusBadge } from '../../components/data'
import { Card, EmptyState, PageHeader } from '../../components/ui'
import { useAdminApi, type DeviceStatus } from '../../lib/adminApi'
import { fmtDateTime, shortId } from '../../lib/format'
import { usePaged } from '../../lib/hooks'

type Filter = DeviceStatus | 'all'

export function DevicesPage() {
  const api = useAdminApi()
  const [params, setParams] = useSearchParams()
  const filter = (params.get('status') as Filter | null) ?? 'active'
  const devices = usePaged((after) => api.listDevices({ status: filter === 'all' ? undefined : filter, after }), [api, filter])
  return (
    <>
      <PageHeader title="Devices" subtitle="Phones authorized to use each license. Most recently seen first." />
      <div className="toolbar">
        <FilterTabs<Filter>
          label="Status"
          value={filter}
          onChange={(v) => setParams({ status: v })}
          options={[
            { value: 'active', label: 'Active' },
            { value: 'revoked', label: 'Revoked' },
            { value: 'all', label: 'All' },
          ]}
        />
      </div>
      <Card>
        <Async state={devices}>
          {(rows) => (
            <>
              <DataTable
                caption="Devices"
                rows={rows}
                rowKey={(d) => `${d.companyId}/${d.id}`}
                columns={[
                  {
                    header: 'Phone',
                    cell: (d) => (
                      <>
                        <Link to={`/devices/${d.companyId}/${d.id}`}>{d.deviceModel ?? 'Phone'}</Link>
                        <span className="cell-sub">Device {shortId(d.id)}</span>
                      </>
                    ),
                  },
                  { header: 'Status', cell: (d) => <StatusBadge status={d.status} /> },
                  { header: 'Company', cell: (d) => <Link to={`/companies/${d.companyId}`}>{shortId(d.companyId)}</Link> },
                  { header: 'Last seen', cell: (d) => fmtDateTime(d.lastSeenAt), secondary: true },
                ]}
                empty={<EmptyState icon="phone" title="No devices" message="Phones appear here once they are activated with a license code." />}
              />
              <LoadMore hasMore={devices.hasMore} loading={devices.loadingMore} onClick={devices.loadMore} />
            </>
          )}
        </Async>
      </Card>
    </>
  )
}
