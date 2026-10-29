import { useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router'
import { Async, DataTable, FilterTabs, LoadMore, SearchInput, StatusBadge } from '../../components/data'
import { Button, Card, EmptyState, PageHeader } from '../../components/ui'
import { useAdminApi, type CompanyStatus } from '../../lib/adminApi'
import { useAdminProfile } from '../../lib/adminProfile'
import { fmtDate } from '../../lib/format'
import { useDebounced, usePaged } from '../../lib/hooks'
import { useToast } from '../../lib/toast'
import { CompanyForm } from './CompanyForm'

type Filter = CompanyStatus | 'all'

export function CompaniesPage() {
  const api = useAdminApi()
  const { can } = useAdminProfile()
  const toast = useToast()
  const navigate = useNavigate()
  const [params, setParams] = useSearchParams()
  const filter = (params.get('status') as Filter | null) ?? 'all'
  const [search, setSearch] = useState('')
  const term = useDebounced(search)
  const [creating, setCreating] = useState(false)
  const companies = usePaged(
    (after) => api.listCompanies({ status: filter === 'all' ? undefined : filter, search: term, after }),
    [api, filter, term],
  )

  return (
    <>
      <PageHeader
        title="Companies"
        subtitle="Customer companies using the JCB Works app."
        actions={
          can('companies.manage') && (
            <Button icon="plus" onClick={() => setCreating(true)}>
              New company
            </Button>
          )
        }
      />
      <div className="toolbar">
        <FilterTabs<Filter>
          label="Status"
          value={filter}
          onChange={(v) => setParams(v === 'all' ? {} : { status: v })}
          options={[
            { value: 'all', label: 'All' },
            { value: 'pending', label: 'Awaiting approval' },
            { value: 'active', label: 'Active' },
            { value: 'suspended', label: 'Suspended' },
          ]}
        />
        <SearchInput label="Search by company name" value={search} onChange={setSearch} />
      </div>
      <Card>
        <Async state={companies}>
          {(rows) => (
            <>
              <DataTable
                caption="Companies"
                rows={rows}
                rowKey={(c) => c.id}
                columns={[
                  {
                    header: 'Company',
                    cell: (c) => (
                      <>
                        <Link to={`/companies/${c.id}`}>{c.name}</Link>
                        <span className="cell-sub">{c.contactPerson} · {c.phone}</span>
                      </>
                    ),
                  },
                  { header: 'Status', cell: (c) => <StatusBadge status={c.status} /> },
                  { header: 'Registered', cell: (c) => fmtDate(c.createdAt), secondary: true },
                  { header: 'Invoice prefix', cell: (c) => c.invoicePrefix, secondary: true },
                ]}
                empty={
                  <EmptyState
                    icon="building"
                    title={term ? `No companies match “${term}”` : 'No companies here'}
                    message={term ? 'Search matches the start of the company name.' : 'Companies appear when they register in the app or are created here.'}
                  />
                }
              />
              <LoadMore hasMore={companies.hasMore} loading={companies.loadingMore} onClick={companies.loadMore} />
            </>
          )}
        </Async>
      </Card>
      {creating && (
        <CompanyForm
          withOwner
          title="New company"
          submitLabel="Create company"
          onClose={() => setCreating(false)}
          onSubmit={async (p) => {
            const r = await api.createCompany(p)
            toast(r.newUser ? 'Company created. Ask the owner to set a password with “Forgot password”.' : 'Company created for the existing user.')
            navigate(`/companies/${r.companyId}`)
          }}
        />
      )}
    </>
  )
}
