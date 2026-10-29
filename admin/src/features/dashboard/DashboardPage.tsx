import { Link } from 'react-router'
import { Async } from '../../components/data'
import { Card, PageHeader, StatCard } from '../../components/ui'
import { EXPIRING_DAYS, useAdminApi } from '../../lib/adminApi'
import { useAsync } from '../../lib/hooks'
import { EventList } from '../audit/EventList'
import './dashboard.css'

export function DashboardPage() {
  const api = useAdminApi()
  const metrics = useAsync(() => api.metrics(), [api])
  const recent = useAsync(async () => (await api.listEvents({})).items.slice(0, 8), [api])

  return (
    <>
      <PageHeader title="Dashboard" subtitle="Licensing and device overview across all customer companies." />
      <Async state={metrics}>
        {(m) => (
          <div className="stat-grid">
            <Link to="/companies?status=pending" className="stat-link">
              <StatCard label="Companies awaiting approval" value={String(m.companies.pending)} icon="building" caption={`${m.companies.active} active · ${m.companies.suspended} suspended`} />
            </Link>
            <Link to="/licenses" className="stat-link">
              <StatCard label="Active licenses" value={String(m.licenses.active)} icon="key" caption={`${m.licenses.expiringSoon} ending within ${EXPIRING_DAYS} days`} />
            </Link>
            <Link to="/licenses?status=expired" className="stat-link">
              <StatCard label="Expired / suspended" value={String(m.licenses.expired + m.licenses.suspended)} icon="alert" caption={`${m.licenses.expired} expired · ${m.licenses.suspended} suspended`} />
            </Link>
            <Link to="/devices" className="stat-link">
              <StatCard label="Active phones" value={String(m.activeDevices)} icon="phone" caption="Across all licenses" />
            </Link>
            <Link to="/replacement-requests" className="stat-link">
              <StatCard label="Replacement requests" value={String(m.pendingRequests)} icon="swap" caption={m.pendingRequests ? 'Waiting for review' : 'Nothing to review'} />
            </Link>
          </div>
        )}
      </Async>
      <Card className="dash-activity">
        <div className="card-head">
          <h2>Recent activity</h2>
          <Link to="/audit-logs">View all</Link>
        </div>
        <Async state={recent}>{(events) => <EventList events={events} />}</Async>
      </Card>
    </>
  )
}
