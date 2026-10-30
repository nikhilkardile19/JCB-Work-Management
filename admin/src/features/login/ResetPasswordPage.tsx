import { useState, type FormEvent } from 'react'
import { Link, useSearchParams } from 'react-router'
import { Icon } from '../../components/Icon'
import { Button, TextField } from '../../components/ui'
import { NOT_CONFIGURED_MESSAGE, PasswordResetError, useAuth } from '../../lib/authContext'
import { validators } from '../../lib/validators'
import logoUrl from './login-logo.webp'
import './login.css'

type Errors = { password?: string | null; confirm?: string | null }

/** Public target of the emailed reset link, for admins and app users alike. */
export function ResetPasswordPage() {
  const { configured, resetPassword } = useAuth()
  const [params] = useSearchParams()
  const token = params.get('token')?.trim() ?? ''

  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [errors, setErrors] = useState<Errors>({})
  const [formError, setFormError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [state, setState] = useState<'form' | 'done' | 'invalid'>(token ? 'form' : 'invalid')

  async function onSubmit(e: FormEvent) {
    e.preventDefault()
    const next: Errors = {
      password: password ? validators.password(password) : 'Enter a new password',
      confirm: !confirm ? 'Enter the new password again' : confirm !== password ? 'Passwords do not match' : null,
    }
    setErrors(next)
    setFormError(null)
    if (next.password || next.confirm) return
    setSubmitting(true)
    try {
      await resetPassword(token, password)
      setState('done')
    } catch (err) {
      if (err instanceof PasswordResetError && err.kind === 'invalid_link') setState('invalid')
      else if (err instanceof PasswordResetError && err.kind === 'invalid_password') setErrors({ password: err.message })
      else setFormError(err instanceof Error ? err.message : 'Could not change the password. Please try again.')
    } finally {
      setSubmitting(false)
    }
  }

  const backToSignIn = (variant: 'primary' | 'secondary') => (
    <Link className={`btn btn-${variant}`} to="/login">
      <Icon name="login" />
      <span>Back to sign in</span>
    </Link>
  )

  return (
    <div className="login">
      <div className="login-panel">
        <div className="login-brand">
          <img className="brand-mark" src={logoUrl} alt="" width={64} height={64} />
          <span>
            <span className="brand-accent">JCB</span> Works
          </span>
        </div>
        <h1>Reset password</h1>
        <p className="login-sub">Choose a new password for your JCB Works account.</p>

        {state === 'done' ? (
          <div className="login-form">
            <p className="login-notice" role="status">
              Your password has been changed. Sign in with the new password, here or in the JCB Works app.
            </p>
            {backToSignIn('primary')}
          </div>
        ) : state === 'invalid' ? (
          <div className="login-form">
            <div className="login-error" role="alert">
              <Icon name="alert" />
              This reset link is invalid or has expired.
            </div>
            <p className="login-help">Ask for a new link with “Forgot password?” on the sign-in screen, then use the newest email.</p>
            {backToSignIn('secondary')}
          </div>
        ) : (
          <form onSubmit={onSubmit} noValidate className="login-form">
            <TextField
              label="New password"
              type={showPassword ? 'text' : 'password'}
              autoComplete="new-password"
              icon="lock"
              placeholder="At least 8 characters"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              error={errors.password}
              autoFocus
              end={
                <button
                  type="button"
                  className="login-reveal"
                  onClick={() => setShowPassword((s) => !s)}
                  aria-label={showPassword ? 'Hide password' : 'Show password'}
                >
                  <Icon name={showPassword ? 'eyeOff' : 'eye'} />
                </button>
              }
            />
            <TextField
              label="Confirm new password"
              type={showPassword ? 'text' : 'password'}
              autoComplete="new-password"
              icon="lock"
              placeholder="Type it again"
              value={confirm}
              onChange={(e) => setConfirm(e.target.value)}
              error={errors.confirm}
            />
            {!configured && (
              <div className="login-error" role="alert">
                <Icon name="alert" />
                {NOT_CONFIGURED_MESSAGE}
              </div>
            )}
            {formError && (
              <div className="login-error" role="alert">
                <Icon name="alert" />
                {formError}
              </div>
            )}
            <Button type="submit" loading={submitting} icon="lock" disabled={!configured}>
              Change password
            </Button>
          </form>
        )}

        <p className="login-note">
          <Icon name="lock" />
          <span>Changing your password signs you out on every device.</span>
        </p>
      </div>
      <div className="login-art" aria-hidden="true" />
    </div>
  )
}
