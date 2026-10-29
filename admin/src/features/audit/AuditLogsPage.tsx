import { useId, useState } from 'react'
import { Async, LoadMore } from '../../components/data'
import { Card, PageHeader } from '../../components/ui'
import { useAdminApi } from '../../lib/adminApi'
import { usePaged } from '../../lib/hooks'
import { EventList } from './EventList'
import { eventLabel, eventTypes } from './events'

export function AuditLogsPage() {
  const api = useAdminApi()
  const id = useId()
  const [type, setType] = useState('')
  const events = usePaged((after) => api.listEvents({ type: type || undefined, after }), [api, type])
  return (
    <>
      <PageHeader title="Audit logs" subtitle="Every license, device and administrative action, newest first." />
      <div className="toolbar">
        <div className="field">
          <label htmlFor={id}>Action</label>
          <select id={id} className="select" value={type} onChange={(e) => setType(e.target.value)}>
            <option value="">All actions</option>
            {eventTypes.map((t) => (
              <option key={t} value={t}>
                {eventLabel({ type: t } as never)}
              </option>
            ))}
          </select>
        </div>
      </div>
      <Card>
        <Async state={events}>
          {(rows) => (
            <>
              <EventList events={rows} />
              <LoadMore hasMore={events.hasMore} loading={events.loadingMore} onClick={events.loadMore} />
            </>
          )}
        </Async>
      </Card>
    </>
  )
}
