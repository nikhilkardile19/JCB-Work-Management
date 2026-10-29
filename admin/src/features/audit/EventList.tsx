import { Link } from 'react-router'
import { EmptyState } from '../../components/ui'
import type { AuditEvent } from '../../lib/adminApi'
import { fmtDateTime, shortId } from '../../lib/format'
import { eventLabel, eventSummary } from './events'

export function EventList({ events }: { events: AuditEvent[] }) {
  if (events.length === 0) return <EmptyState icon="history" title="No activity yet" />
  return (
    <ol className="events">
      {events.map((e) => (
        <li key={e.id}>
          <div>
            <strong>{eventLabel(e)}</strong>
            <span className="cell-sub">{eventSummary(e)}</span>
          </div>
          <div className="event-meta">
            <span>{fmtDateTime(e.at)}</span>
            {e.companyId && <Link to={`/companies/${e.companyId}`}>Company {shortId(e.companyId)}</Link>}
          </div>
        </li>
      ))}
    </ol>
  )
}
