import { useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react'
import type { Cursor, Page } from './adminApi'

export interface AsyncState<T> {
  data: T | undefined
  error: string | null
  loading: boolean
  reload: () => void
}

/** Runs [load] when [deps] change; exposes loading/error and reload. */
export function useAsync<T>(load: () => Promise<T>, deps: unknown[]): AsyncState<T> {
  const [data, setData] = useState<T>()
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [tick, setTick] = useState(0)
  useEffect(() => {
    let live = true
    setLoading(true)
    setError(null)
    load()
      .then((d) => live && setData(d))
      .catch((e: Error) => live && setError(e.message || 'Could not load data.'))
      .finally(() => live && setLoading(false))
    return () => {
      live = false
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [...deps, tick])
  return { data, error, loading, reload: useCallback(() => setTick((t) => t + 1), []) }
}

export interface PagedState<T> extends AsyncState<T[]> {
  hasMore: boolean
  loadingMore: boolean
  loadMore: () => void
}

/** Cursor pagination with "Load more"; restarts when [deps] change. */
export function usePaged<T>(fetchPage: (after?: Cursor) => Promise<Page<T>>, deps: unknown[]): PagedState<T> {
  const [items, setItems] = useState<T[]>([])
  const [next, setNext] = useState<Cursor | null>(null)
  const [loadingMore, setLoadingMore] = useState(false)
  const [moreError, setMoreError] = useState<string | null>(null)
  const fetchRef = useRef(fetchPage)
  useLayoutEffect(() => {
    fetchRef.current = fetchPage
  })
  const first = useAsync(async () => {
    const p = await fetchRef.current()
    setItems(p.items)
    setNext(p.next)
    setMoreError(null)
    return p.items
  }, deps)
  const loadMore = useCallback(() => {
    if (!next) return
    setLoadingMore(true)
    fetchRef
      .current(next)
      .then((p) => {
        setItems((prev) => [...prev, ...p.items])
        setNext(p.next)
      })
      .catch((e: Error) => setMoreError(e.message))
      .finally(() => setLoadingMore(false))
  }, [next])
  return {
    data: first.loading && !first.data ? undefined : items,
    error: first.error ?? moreError,
    loading: first.loading,
    reload: first.reload,
    hasMore: next !== null,
    loadingMore,
    loadMore,
  }
}

export function useDebounced<T>(value: T, ms = 300): T {
  const [v, setV] = useState(value)
  useEffect(() => {
    const t = setTimeout(() => setV(value), ms)
    return () => clearTimeout(t)
  }, [value, ms])
  return v
}
