const date = new Intl.DateTimeFormat('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })
const dateTime = new Intl.DateTimeFormat('en-IN', { day: 'numeric', month: 'short', year: 'numeric', hour: 'numeric', minute: '2-digit' })

export const fmtDate = (ms: number | null | undefined) => (ms == null ? '—' : date.format(ms))
export const fmtDateTime = (ms: number | null | undefined) => (ms == null ? '—' : dateTime.format(ms))

/** Whole days from now to [ms] (negative when in the past). */
export const daysUntil = (ms: number, now = Date.now()) => Math.ceil((ms - now) / 86_400_000)

/** `yyyy-mm-dd` for <input type="date">, in local time. */
export function toDateInput(ms: number): string {
  const d = new Date(ms)
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

/** End of the chosen local day, in ms. */
export const fromDateInput = (v: string) => new Date(`${v}T23:59:59`).getTime()

export const shortId = (id: string) => id.slice(0, 8).toUpperCase()
