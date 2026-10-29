import { useState } from 'react'
import { ActionDialog } from '../../components/dialogs'
import { TextField } from '../../components/ui'
import type { CompanyProfile } from '../../lib/adminApi'
import { validateCompany, type Errors } from './companyValidation'

const empty: CompanyProfile = { name: '', contactPerson: '', phone: '', address: '', invoicePrefix: '', email: null, gstin: null }

export function CompanyForm({
  initial,
  withOwner,
  title,
  submitLabel,
  onSubmit,
  onClose,
}: {
  initial?: CompanyProfile
  withOwner: boolean
  title: string
  submitLabel: string
  onSubmit: (p: CompanyProfile & { ownerEmail: string }) => Promise<void>
  onClose: () => void
}) {
  const [p, setP] = useState<CompanyProfile>(initial ?? empty)
  const [ownerEmail, setOwnerEmail] = useState('')
  const [errors, setErrors] = useState<Errors>({})
  const set = (k: keyof CompanyProfile) => (e: React.ChangeEvent<HTMLInputElement>) => {
    const v = k === 'invoicePrefix' || k === 'gstin' ? e.target.value.toUpperCase() : e.target.value
    setP((x) => ({ ...x, [k]: k === 'email' || k === 'gstin' ? v || null : v }))
    setErrors((x) => ({ ...x, [k]: undefined }))
  }
  return (
    <ActionDialog
      title={title}
      submitLabel={submitLabel}
      onClose={onClose}
      onSubmit={async () => {
        const e = validateCompany({ ...p, ownerEmail }, withOwner)
        setErrors(e)
        if (Object.keys(e).length) throw new Error('Check the highlighted fields.')
        await onSubmit({ ...p, name: p.name.trim(), ownerEmail: ownerEmail.trim() })
      }}
    >
      <div className="form-grid">
        <TextField label="Company name" value={p.name} onChange={set('name')} error={errors.name} />
        <TextField label="Contact person" value={p.contactPerson} onChange={set('contactPerson')} error={errors.contactPerson} />
        <TextField label="Phone" value={p.phone} onChange={set('phone')} error={errors.phone} inputMode="tel" />
        <TextField label="Email (optional)" value={p.email ?? ''} onChange={set('email')} error={errors.email} type="email" />
        <TextField label="Address" value={p.address} onChange={set('address')} error={errors.address} />
        <TextField label="Invoice prefix" value={p.invoicePrefix} onChange={set('invoicePrefix')} error={errors.invoicePrefix} maxLength={10} />
        <TextField label="GSTIN (optional)" value={p.gstin ?? ''} onChange={set('gstin')} error={errors.gstin} maxLength={15} />
        {withOwner && (
          <TextField
            label="Owner’s sign-in email"
            hint="An account is created if needed; the owner sets a password with “Forgot password”."
            value={ownerEmail}
            onChange={(e) => (setOwnerEmail(e.target.value), setErrors((x) => ({ ...x, ownerEmail: undefined })))}
            error={errors.ownerEmail}
            type="email"
          />
        )}
      </div>
    </ActionDialog>
  )
}
