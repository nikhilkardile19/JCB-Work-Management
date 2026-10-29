import { useId, type ReactNode } from 'react'
import { Icon } from './Icon'
import { Badge, Button, EmptyState, type Tone } from './ui'

export interface Column<T> {
  header: string
  cell: (row: T) => ReactNode
  /** Hide on narrow screens (cards show the main columns only). */
  secondary?: boolean
}

/** Table on wide screens, stacked cards on phones (CSS). */
export function DataTable<T>({
  rows,
  columns,
  rowKey,
  caption,
  empty,
}: {
  rows: T[]
  columns: Column<T>[]
  rowKey: (row: T) => string
  caption: string
  empty: ReactNode
}) {
  if (rows.length === 0) return <>{empty}</>
  return (
    <div className="table-wrap">
      <table className="data-table">
        <caption className="visually-hidden">{caption}</caption>
        <thead>
          <tr>
            {columns.map((c) => (
              <th key={c.header} scope="col" className={c.secondary ? 'secondary' : undefined}>
                {c.header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((r) => (
            <tr key={rowKey(r)}>
              {columns.map((c) => (
                <td key={c.header} data-label={c.header} className={c.secondary ? 'secondary' : undefined}>
                  {c.cell(r)}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

export function FilterTabs<V extends string>({
  label,
  value,
  options,
  onChange,
}: {
  label: string
  value: V
  options: { value: V; label: string }[]
  onChange: (v: V) => void
}) {
  return (
    <div className="tabs" role="radiogroup" aria-label={label}>
      {options.map((o) => (
        <button
          key={o.value}
          type="button"
          role="radio"
          aria-checked={o.value === value}
          className={`tab${o.value === value ? ' tab-active' : ''}`}
          onClick={() => onChange(o.value)}
        >
          {o.label}
        </button>
      ))}
    </div>
  )
}

export function SearchInput({ label, value, onChange }: { label: string; value: string; onChange: (v: string) => void }) {
  const id = useId()
  return (
    <div className="search">
      <label htmlFor={id} className="visually-hidden">
        {label}
      </label>
      <input id={id} type="search" placeholder={label} value={value} onChange={(e) => onChange(e.target.value)} />
    </div>
  )
}

export function LoadMore({ hasMore, loading, onClick }: { hasMore: boolean; loading: boolean; onClick: () => void }) {
  if (!hasMore) return null
  return (
    <div className="load-more">
      <Button variant="secondary" loading={loading} onClick={onClick}>
        Load more
      </Button>
    </div>
  )
}

export function LoadingState({ label = 'Loading…' }: { label?: string }) {
  return (
    <div className="boot inline" role="status" aria-live="polite">
      <span className="spinner" aria-hidden />
      <span>{label}</span>
    </div>
  )
}

export function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <EmptyState
      icon="alert"
      title="Something went wrong"
      message={message}
      action={onRetry && <Button variant="secondary" onClick={onRetry}>Try again</Button>}
    />
  )
}

/** Loading / error / content switch for async data. */
export function Async<T>({ state, children }: { state: { data: T | undefined; error: string | null; loading: boolean; reload: () => void }; children: (data: T) => ReactNode }) {
  if (state.error && state.data === undefined) return <ErrorState message={state.error} onRetry={state.reload} />
  if (state.data === undefined) return <LoadingState />
  return <>{children(state.data)}</>
}

const STATUS_TONES: Record<string, Tone> = {
  active: 'success',
  pending: 'warning',
  suspended: 'danger',
  expired: 'danger',
  revoked: 'neutral',
}

export function StatusBadge({ status }: { status: string }) {
  return <Badge tone={STATUS_TONES[status] ?? 'neutral'}>{status[0].toUpperCase() + status.slice(1)}</Badge>
}

export function DefinitionList({ items }: { items: [string, ReactNode][] }) {
  return (
    <dl className="deflist">
      {items.map(([k, v]) => (
        <div key={k}>
          <dt>{k}</dt>
          <dd>{v ?? '—'}</dd>
        </div>
      ))}
    </dl>
  )
}

export function Copyable({ text }: { text: string }) {
  return (
    <span className="copyable">
      <code>{text}</code>
      <button type="button" className="icon-btn" aria-label="Copy" onClick={() => navigator.clipboard?.writeText(text)}>
        <Icon name="copy" size={16} />
      </button>
    </span>
  )
}
