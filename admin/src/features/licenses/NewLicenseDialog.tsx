import { useState } from 'react'
import { ActionDialog } from '../../components/dialogs'
import { TextField } from '../../components/ui'
import { useAdminApi, type IssuedCode } from '../../lib/adminApi'
import { fromDateInput, toDateInput } from '../../lib/format'

/** License terms for a new license; with [approve], also activates the pending company (needs a reason). */
export function NewLicenseDialog({
  companyId,
  approve,
  onClose,
  onCreated,
}: {
  companyId: string
  approve?: boolean
  onClose: () => void
  onCreated: (issued: IssuedCode) => void
}) {
  const api = useAdminApi()
  const [from, setFrom] = useState(() => toDateInput(Date.now()))
  const [until, setUntil] = useState(() => toDateInput(Date.now() + 365 * 86_400_000))
  const [devices, setDevices] = useState('2')
  const [reason, setReason] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [reasonError, setReasonError] = useState<string | null>(null)
  return (
    <ActionDialog
      title={approve ? 'Approve company' : 'New license'}
      submitLabel={approve ? 'Approve' : 'Create license'}
      onClose={onClose}
      onSubmit={async () => {
        const validFrom = new Date(`${from}T00:00:00`).getTime()
        const validUntil = fromDateInput(until)
        const maxDevices = Number(devices)
        if (!(validUntil > validFrom)) {
          setError('The end date must be after the start date')
          throw new Error('Check the dates.')
        }
        if (!Number.isInteger(maxDevices) || maxDevices < 1 || maxDevices > 100) {
          setError('Phones allowed must be 1–100')
          throw new Error('Check the number of phones.')
        }
        if (approve && reason.trim().length < 3) {
          setReasonError('Enter a reason (at least 3 characters)')
          throw new Error('A reason is required.')
        }
        const terms = { companyId, validFrom, validUntil, maxDevices }
        onCreated(approve ? await api.approveCompany({ ...terms, reason: reason.trim() }) : await api.createLicense(terms))
      }}
    >
      {approve && <p>The company becomes active with this license. Its activation code is emailed to the owner and works once, on one phone.</p>}
      <div className="form-grid">
        <TextField label="Starts" type="date" value={from} onChange={(e) => (setFrom(e.target.value), setError(null))} />
        <TextField label="Ends" type="date" value={until} onChange={(e) => (setUntil(e.target.value), setError(null))} />
        <TextField label="Phones allowed" type="number" min={1} max={100} value={devices} onChange={(e) => (setDevices(e.target.value), setError(null))} error={error} />
      </div>
      {approve && <TextField label="Reason" value={reason} error={reasonError} onChange={(e) => (setReason(e.target.value), setReasonError(null))} />}
    </ActionDialog>
  )
}
