import { Component, type ErrorInfo, type ReactNode } from 'react'
import { Button, EmptyState } from './ui'

/**
 * Keeps one broken page from blanking the whole portal: shows a message with
 * a reload, and logs the error with its component stack for support.
 * Give it a `key` (e.g. the path) so navigating away resets it.
 */
export class ErrorBoundary extends Component<{ children: ReactNode }, { error: Error | null }> {
  state = { error: null as Error | null }

  static getDerivedStateFromError(error: Error) {
    return { error }
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error('Portal page crashed', error, info.componentStack)
  }

  render() {
    if (!this.state.error) return this.props.children
    return (
      <EmptyState
        icon="alert"
        title="This page couldn't be shown"
        message="Something went wrong. Reload to try again; if it keeps happening, note what you were doing and contact the developer."
        action={<Button onClick={() => window.location.reload()}>Reload</Button>}
      />
    )
  }
}
