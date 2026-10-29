import { useId, useState } from 'react'
import { Link, useSearchParams } from 'react-router'
import { Async, DataTable, FilterTabs, LoadMore, StatusBadge } from '../../components/data'
import { ActionDialog } from '../../components/dialogs'
import { Button, Card, EmptyState, PageHeader, TextField } from '../../components/ui'
import { useAdminApi, type ReplacementRequest, type RequestStatus } from '../../lib/adminApi'
import { useAdminProfile } from '../../lib/adminProfile'
import { fmtDateTime, shortId } from '../../lib/format'
import { useAsync, usePaged } from '../../lib/hooks'
import { useToast } from '../../lib/toast'

type Filter = RequestStatus | 'all'

export function ReplacementRequestsPage() {
  const api = useAdminApi()
  const { can } = useAdminProfile()
  const [params, setParams] = useSearchParams()
  const filter = (params.get('status') as Filter | null) ?? 'pending'
  const requests = usePaged((after) => api.listReplacementRequests({ status: filter === 'all' ? undefined : filter, after }), [api, filter])
  const [reviewing, setReviewing] = useState<ReplacementRequest | null>(null)

  return (
    <>
      <PageHeader title="Replacement requests" subtitle="Phones asking to take a place on a full license (old phone lost, damaged or replaced)." />
      <div className="toolbar">
        <FilterTabs<Filter>
          label="Status"
          value={filter}
          onChange={(v) => setParams({ status: v })}
          options={[
            { value: 'pending', label: 'Pending' },
            { value: 'approved', label: 'Approved' },
            { value: 'rejected', label: 'Rejected' },
            { value: 'all', label: 'All' },
          ]}
        />
      </div>
      <Card>
        <Async state={requests}>
          {(rows) => (
            <>
              <DataTable
                caption="Replacement requests"
                rows={rows}
                rowKey={(r) => `${r.companyId}/${r.id}`}
                columns={[
                  {
                    header: 'Company',
                    cell: (r) => (
                      <>
                        <Link to={`/companies/${r.companyId}`}>{r.companyName ?? shortId(r.companyId)}</Link>
                        <span className="cell-sub">{r.requesterEmail ?? shortId(r.requestedBy)}</span>
                      </>
                    ),
                  },
                  {
                    header: 'Why',
                    cell: (r) => (
                      <>
                        {r.reason}
                        {r.reviewReason && <span className="cell-sub">Review: {r.reviewReason}</span>}
                      </>
                    ),
                  },
                  { header: 'New phone', cell: (r) => `${r.newDeviceModel ?? 'Phone'} · ${shortId(r.newDeviceId)}`, secondary: true },
                  { header: 'Requested', cell: (r) => fmtDateTime(r.createdAt), secondary: true },
                  {
                    header: 'Status',
                    cell: (r) =>
                      r.status === 'pending' && can('devices.revoke') ? (
                        <Button variant="secondary" onClick={() => setReviewing(r)}>
                          Review
                        </Button>
                      ) : (
                        <StatusBadge status={r.status} />
                      ),
                  },
                ]}
                empty={<EmptyState icon="swap" title={filter === 'pending' ? 'No pending requests' : 'No requests'} message="Requests are sent from the app when a phone can’t activate because the license is full." />}
              />
              <LoadMore hasMore={requests.hasMore} loading={requests.loadingMore} onClick={requests.loadMore} />
            </>
          )}
        </Async>
      </Card>
      {reviewing && <ReviewDialog request={reviewing} onClose={() => setReviewing(null)} onDone={requests.reload} />}
    </>
  )
}

function ReviewDialog({ request, onClose, onDone }: { request: ReplacementRequest; onClose: () => void; onDone: () => void }) {
  const api = useAdminApi()
  const toast = useToast()
  const name = useId()
  const license = useAsync(() => api.getLicense(request.companyId, request.licenseId), [api, request])
  const phones = useAsync(async () => (await api.listDevices({ companyId: request.companyId, licenseId: request.licenseId, status: 'active' })).items, [api, request])
  const [decision, setDecision] = useState<'approve' | 'reject'>('approve')
  const [revoke, setRevoke] = useState<string | null>(null)
  const [reason, setReason] = useState('')
  const [error, setError] = useState<string | null>(null)
  const full = !!license.data && !!phones.data && phones.data.length >= license.data.maxDevices
  // Pre-select the requester's own old phone when there is one.
  const suggested = phones.data?.find((p) => p.userId === request.requestedBy)?.id ?? null
  const chosen = revoke ?? (full ? suggested : null)

  return (
    <ActionDialog
      title="Review replacement"
      submitLabel={decision === 'approve' ? 'Approve' : 'Reject'}
      danger={decision === 'reject'}
      onClose={onClose}
      onSubmit={async () => {
        if (reason.trim().length < 3) {
          setError('Enter a reason (at least 3 characters)')
          throw new Error('A reason is required.')
        }
        if (decision === 'approve' && full && !chosen) throw new Error('The license is full: choose the phone this one replaces.')
        await api.reviewReplacement({
          companyId: request.companyId,
          requestId: request.id,
          decision,
          reason: reason.trim(),
          ...(decision === 'approve' && chosen ? { revokeDeviceId: chosen } : {}),
        })
        toast(decision === 'approve' ? 'Replacement approved' : 'Replacement rejected')
        onDone()
      }}
    >
      <p>
        <strong>{request.requesterEmail ?? 'A member'}</strong> of {request.companyName ?? 'this company'}: “{request.reason}”
      </p>
      <fieldset className="radio-group">
        <legend>Decision</legend>
        <label><input type="radio" name={`${name}-d`} checked={decision === 'approve'} onChange={() => setDecision('approve')} /> Approve</label>
        <label><input type="radio" name={`${name}-d`} checked={decision === 'reject'} onChange={() => setDecision('reject')} /> Reject</label>
      </fieldset>
      {decision === 'approve' && (
        <fieldset className="radio-group">
          <legend>Phone to deactivate {license.data && `(${phones.data?.length ?? '…'} of ${license.data.maxDevices} places used)`}</legend>
          {phones.data?.map((p) => (
            <label key={p.id}>
              <input type="radio" name={`${name}-p`} checked={chosen === p.id} onChange={() => setRevoke(p.id)} />
              {p.deviceModel ?? 'Phone'} · {shortId(p.id)} · last seen {fmtDateTime(p.lastSeenAt)}
              {p.userId === request.requestedBy && <em> (requester’s phone)</em>}
            </label>
          ))}
          {!full && (
            <label>
              <input type="radio" name={`${name}-p`} checked={chosen === null} onChange={() => setRevoke(null)} /> None — a place is free
            </label>
          )}
        </fieldset>
      )}
      <TextField label="Reason" value={reason} error={error} onChange={(e) => (setReason(e.target.value), setError(null))} hint="Shown to the requester and kept in the history." />
    </ActionDialog>
  )
}
