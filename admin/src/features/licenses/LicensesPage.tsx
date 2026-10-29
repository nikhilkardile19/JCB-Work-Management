import { Link, useSearchParams } from 'react-router'
import { Async, DataTable, FilterTabs, LoadMore, StatusBadge } from '../../components/data'
import { Card, EmptyState, PageHeader } from '../../components/ui'
import { useAdminApi, type LicenseStatus } from '../../lib/adminApi'
import { daysUntil, fmtDate, shortId } from '../../lib/format'
import { usePaged } from '../../lib/hooks'

type Filter = LicenseStatus | 'all'

export function LicensesPage() {
  const api = useAdminApi()
  const [params, setParams] = useSearchParams()
  const filter = (params.get('status') as Filter | null) ?? 'active'
  const licenses = usePaged((after) => api.listLicenses({ status: filter === 'all' ? undefined : filter, after }), [api, filter])

  return (
    <>
      <PageHeader title="Licenses" subtitle="Validity, status and phone limits per company. Soonest end date first." />
      <div className="toolbar">
        <FilterTabs<Filter>
          label="Status"
          value={filter}
          onChange={(v) => setParams({ status: v })}
          options={[
            { value: 'active', label: 'Active' },
            { value: 'suspended', label: 'Suspended' },
            { value: 'expired', label: 'Expired' },
            { value: 'revoked', label: 'Revoked' },
            { value: 'all', label: 'All' },
          ]}
        />
      </div>
      <Card>
        <Async state={licenses}>
          {(rows) => (
            <>
              <DataTable
                caption="Licenses"
                rows={rows}
                rowKey={(l) => `${l.companyId}/${l.id}`}
                columns={[
                  {
                    header: 'Company',
                    cell: (l) => (
                      <>
                        <Link to={`/licenses/${l.companyId}/${l.id}`}>{l.companyName ?? `Company ${shortId(l.companyId)}`}</Link>
                        <span className="cell-sub">License {shortId(l.id)}</span>
                      </>
                    ),
                  },
                  { header: 'Status', cell: (l) => <StatusBadge status={l.status} /> },
                  {
                    header: 'Valid until',
                    cell: (l) => {
                      const d = daysUntil(l.validUntil)
                      return (
                        <>
                          {fmtDate(l.validUntil)}
                          {l.status === 'active' && <span className="cell-sub">{d >= 0 ? `${d} days left` : 'ended'}</span>}
                        </>
                      )
                    },
                  },
                  { header: 'Phones allowed', cell: (l) => l.maxDevices, secondary: true },
                ]}
                empty={<EmptyState icon="key" title={`No ${filter === 'all' ? '' : filter} licenses`} message="Licenses are created from a company’s page." />}
              />
              <LoadMore hasMore={licenses.hasMore} loading={licenses.loadingMore} onClick={licenses.loadMore} />
            </>
          )}
        </Async>
      </Card>
    </>
  )
}
