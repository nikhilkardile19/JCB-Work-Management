import { createContext, useCallback, useContext, useState, type ReactNode } from 'react'

type Tone = 'success' | 'danger' | 'info'
interface Toast {
  id: number
  text: string
  tone: Tone
}

const ToastContext = createContext<(text: string, tone?: Tone) => void>(() => {})

let seq = 0

/** Short confirmations after actions, announced to screen readers. */
export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([])
  const show = useCallback((text: string, tone: Tone = 'success') => {
    const id = ++seq
    setToasts((t) => [...t, { id, text, tone }])
    setTimeout(() => setToasts((t) => t.filter((x) => x.id !== id)), 4000)
  }, [])
  return (
    <ToastContext.Provider value={show}>
      {children}
      <div className="toasts" role="status" aria-live="polite">
        {toasts.map((t) => (
          <div key={t.id} className={`toast toast-${t.tone}`}>
            {t.text}
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  )
}

// oxlint-disable-next-line react/only-export-components
export const useToast = () => useContext(ToastContext)
