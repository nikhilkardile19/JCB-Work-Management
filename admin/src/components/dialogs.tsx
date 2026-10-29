import { useEffect, useId, useLayoutEffect, useRef, useState, type FormEvent, type ReactNode } from 'react'
import { Copyable } from './data'
import { Button, TextField } from './ui'

/** Accessible modal: focus moves in, Escape closes, page behind is inert. */
export function Modal({ title, onClose, children }: { title: string; onClose: () => void; children: ReactNode }) {
  const id = useId()
  const ref = useRef<HTMLDivElement>(null)
  const close = useRef(onClose)
  useLayoutEffect(() => {
    close.current = onClose
  })
  // Runs once on open: focus must not jump back while the user types.
  useEffect(() => {
    const previous = document.activeElement as HTMLElement | null
    ref.current?.querySelector<HTMLElement>('input, textarea, select, button')?.focus()
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && close.current()
    document.addEventListener('keydown', onKey)
    return () => {
      document.removeEventListener('keydown', onKey)
      previous?.focus()
    }
  }, [])
  return (
    <div className="modal-backdrop" onMouseDown={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal" role="dialog" aria-modal="true" aria-labelledby={id} ref={ref}>
        <h2 id={id}>{title}</h2>
        {children}
      </div>
    </div>
  )
}

/**
 * Form dialog that runs [onSubmit]; server errors are shown inline and the
 * dialog stays open. Closes on success.
 */
export function ActionDialog({
  title,
  submitLabel,
  danger,
  onSubmit,
  onClose,
  children,
}: {
  title: string
  submitLabel: string
  danger?: boolean
  onSubmit: () => Promise<void>
  onClose: () => void
  children: ReactNode
}) {
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  async function submit(e: FormEvent) {
    e.preventDefault()
    setBusy(true)
    setError(null)
    try {
      await onSubmit()
      onClose()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'The action failed.')
    } finally {
      setBusy(false)
    }
  }
  return (
    <Modal title={title} onClose={onClose}>
      <form onSubmit={submit} className="modal-form" noValidate>
        {children}
        {error && (
          <p className="form-error" role="alert">
            {error}
          </p>
        )}
        <div className="modal-actions">
          <Button type="button" variant="ghost" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" variant={danger ? 'danger' : 'primary'} loading={busy}>
            {submitLabel}
          </Button>
        </div>
      </form>
    </Modal>
  )
}

/** Confirmation that requires a written reason (kept in the audit log). */
export function ReasonDialog({
  title,
  message,
  submitLabel,
  danger,
  onConfirm,
  onClose,
}: {
  title: string
  message: string
  submitLabel: string
  danger?: boolean
  onConfirm: (reason: string) => Promise<void>
  onClose: () => void
}) {
  const [reason, setReason] = useState('')
  const [error, setError] = useState<string | null>(null)
  return (
    <ActionDialog
      title={title}
      submitLabel={submitLabel}
      danger={danger}
      onClose={onClose}
      onSubmit={async () => {
        if (reason.trim().length < 3) {
          setError('Enter a reason (at least 3 characters)')
          throw new Error('A reason is required.')
        }
        await onConfirm(reason.trim())
      }}
    >
      <p>{message}</p>
      <TextField label="Reason" value={reason} error={error} onChange={(e) => (setReason(e.target.value), setError(null))} />
    </ActionDialog>
  )
}

/** Shows a new activation code exactly once. */
export function CodeDialog({ code, onClose }: { code: string; onClose: () => void }) {
  return (
    <Modal title="Activation code" onClose={onClose}>
      <p>Give this code to the company owner. It is shown only now and is not stored — copy it before closing.</p>
      <p className="code-display">
        <Copyable text={code} />
      </p>
      <div className="modal-actions">
        <Button onClick={onClose}>I've copied it</Button>
      </div>
    </Modal>
  )
}
