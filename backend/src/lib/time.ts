/** Injectable clock so time-based rules can be tested. */
export type Clock = () => Date

export const systemClock: Clock = () => new Date()

export const ms = (d: Date | null | undefined): number | null => (d ? d.getTime() : null)

export const HOUR_MS = 3_600_000
export const DAY_MS = 86_400_000
