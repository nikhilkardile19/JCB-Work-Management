import { useId, type ButtonHTMLAttributes, type InputHTMLAttributes, type ReactNode } from 'react'
import { Icon, type IconName } from './Icon'
import './ui.css'

type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger'

export function Button({
  variant = 'primary',
  loading = false,
  icon,
  children,
  disabled,
  ...rest
}: ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: ButtonVariant
  loading?: boolean
  icon?: IconName
}) {
  return (
    <button
      className={`btn btn-${variant}`}
      disabled={disabled || loading}
      aria-busy={loading || undefined}
      {...rest}
    >
      {loading ? <span className="spinner" aria-hidden /> : icon && <Icon name={icon} />}
      <span>{children}</span>
    </button>
  )
}

export function TextField({
  label,
  error,
  hint,
  icon,
  end,
  ...rest
}: InputHTMLAttributes<HTMLInputElement> & {
  label: string
  error?: string | null
  hint?: string
  /** Leading icon inside the input. */
  icon?: IconName
  /** Trailing control inside the input, e.g. a show-password toggle. */
  end?: ReactNode
}) {
  const id = useId()
  const describedBy = error ? `${id}-err` : hint ? `${id}-hint` : undefined
  const input = <input id={id} aria-invalid={!!error} aria-describedby={describedBy} {...rest} />
  return (
    <div className={`field${error ? ' field-error' : ''}`}>
      <label htmlFor={id}>{label}</label>
      {icon || end ? (
        <div className={`field-control${icon ? ' has-icon' : ''}${end ? ' has-end' : ''}`}>
          {icon && <Icon name={icon} />}
          {input}
          {end && <span className="field-end">{end}</span>}
        </div>
      ) : (
        input
      )}
      {error ? (
        <p id={`${id}-err`} className="field-msg" role="alert">
          {error}
        </p>
      ) : (
        hint && (
          <p id={`${id}-hint`} className="field-msg field-hint">
            {hint}
          </p>
        )
      )}
    </div>
  )
}

export function Card({ children, className = '' }: { children: ReactNode; className?: string }) {
  return <section className={`card ${className}`}>{children}</section>
}

export type Tone = 'success' | 'warning' | 'danger' | 'info' | 'neutral'

export function Badge({ tone = 'neutral', children }: { tone?: Tone; children: ReactNode }) {
  return <span className={`badge badge-${tone}`}>{children}</span>
}

export function StatCard({
  label,
  value,
  icon,
  caption,
}: {
  label: string
  value: string
  icon: IconName
  caption?: string
}) {
  return (
    <Card className="stat">
      <div className="stat-icon">
        <Icon name={icon} />
      </div>
      <div className="stat-value">{value}</div>
      <div className="stat-label">{label}</div>
      {caption && <div className="stat-caption">{caption}</div>}
    </Card>
  )
}

export function EmptyState({
  icon,
  title,
  message,
  action,
}: {
  icon: IconName
  title: string
  message?: string
  action?: ReactNode
}) {
  return (
    <div className="empty">
      <div className="empty-icon">
        <Icon name={icon} size={32} />
      </div>
      <h2>{title}</h2>
      {message && <p>{message}</p>}
      {action}
    </div>
  )
}

export function PageHeader({ title, subtitle, actions }: { title: string; subtitle?: string; actions?: ReactNode }) {
  return (
    <header className="page-header">
      <div>
        <h1>{title}</h1>
        {subtitle && <p>{subtitle}</p>}
      </div>
      {actions && <div className="page-actions">{actions}</div>}
    </header>
  )
}
