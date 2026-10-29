import { useState } from 'react'
import { ActionDialog } from '../../components/dialogs'
import { TextField } from '../../components/ui'
import { useAdminApi } from '../../lib/adminApi'
import { fromDateInput, toDateInput } from '../../lib/format'

export function NewLicenseDialog({ companyId, onClose, onCreated }: { companyId: string; onClose: () => void; onCreated: (code: string) => void }) {
  const api = useAdminApi()
  const [from, setFrom] = useState(() => toDateInput(Date.now()))
  const [until, setUntil] = useState(() => toDateInput(Date.now() + 365 * 86_400_000))
  const [devices, setDevices] = useState('2')
  const [error, setError] = useState<string | null>(null)
  return (
    <ActionDialog
      title="New license"
      submitLabel="Create license"
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
        const r = await api.createLicense({ companyId, validFrom, validUntil, maxDevices })
        onCreated(r.activationCode)
      }}
    >
      <div className="form-grid">
        <TextField label="Starts" type="date" value={from} onChange={(e) => (setFrom(e.target.value), setError(null))} />
        <TextField label="Ends" type="date" value={until} onChange={(e) => (setUntil(e.target.value), setError(null))} />
        <TextField label="Phones allowed" type="number" min={1} max={100} value={devices} onChange={(e) => (setDevices(e.target.value), setError(null))} error={error} />
      </div>
    </ActionDialog>
  )
}
