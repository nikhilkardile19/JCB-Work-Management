import { useState, type FormEvent } from 'react'
import { Navigate, useLocation, useNavigate } from 'react-router'
import { Icon } from '../../components/Icon'
import { Button, TextField } from '../../components/ui'
import { useAuth } from '../../lib/authContext'
import { validators } from '../../lib/validators'
import './login.css'

export function LoginPage() {
  const { user, configured, signIn, sendPasswordReset } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const from = (location.state as { from?: string } | null)?.from ?? '/'

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [errors, setErrors] = useState<{ email?: string | null; password?: string | null }>({})
  const [formError, setFormError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [notice, setNotice] = useState<string | null>(null)

  if (user) return <Navigate to={from} replace />

  async function onForgot() {
    const emailError = validators.email(email)
    setErrors({ email: emailError })
    setFormError(null)
    setNotice(null)
    if (emailError) return
    try {
      await sendPasswordReset(email)
      setNotice(`If an admin account exists for ${email.trim()}, a reset link is on its way.`)
    } catch (err) {
      setFormError(err instanceof Error ? err.message : 'Could not send the reset email.')
    }
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault()
    const next = { email: validators.email(email), password: validators.password(password) }
    setErrors(next)
    setFormError(null)
    setNotice(null)
    if (next.email || next.password) return
    setSubmitting(true)
    try {
      await signIn(email, password)
      navigate(from, { replace: true })
    } catch (err) {
      setFormError(err instanceof Error ? err.message : 'Sign-in failed. Please try again.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="login">
      <div className="login-panel">
        <div className="login-brand">
          <span className="brand-mark">
            <Icon name="excavator" size={26} />
          </span>
          <span>JCB Works</span>
        </div>
        <h1>Developer Admin</h1>
        <p className="login-sub">Manage customer companies, licenses and authorized devices.</p>

        <form onSubmit={onSubmit} noValidate className="login-form">
          <TextField
            label="Email"
            type="email"
            autoComplete="username"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            error={errors.email}
            autoFocus
          />
          <TextField
            label="Password"
            type="password"
            autoComplete="current-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            error={errors.password}
          />
          {!configured && (
            <div className="login-error" role="alert">
              <Icon name="alert" />
              Admin sign-in is not configured. Add the Firebase web app settings to admin/.env.local (see .env.example).
            </div>
          )}
          {notice && (
            <p className="login-notice" role="status">
              {notice}
            </p>
          )}
          {formError && (
            <div className="login-error" role="alert">
              <Icon name="alert" />
              {formError}
            </div>
          )}
          <Button type="submit" loading={submitting} icon="login" disabled={!configured}>
            Sign in
          </Button>
          <Button type="button" variant="ghost" onClick={onForgot} disabled={!configured}>
            Forgot password?
          </Button>
        </form>

        <p className="login-note">
          <Icon name="lock" size={16} />
          Access is restricted to authorized developer administrators. All actions are audited.
        </p>
      </div>
      <div className="login-art" aria-hidden="true">
        <div className="login-art-inner">
          <Icon name="excavator" size={160} />
          <p>Licenses · Devices · Audit</p>
        </div>
      </div>
    </div>
  )
}
