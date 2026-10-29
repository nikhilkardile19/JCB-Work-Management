export const validators = {
  email(v: string): string | null {
    const t = v.trim()
    if (!t) return 'Enter your email address'
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(t)) return 'Enter a valid email address'
    return null
  },
  password(v: string, min = 8): string | null {
    if (!v) return 'Enter your password'
    if (v.length < min) return `Password must be at least ${min} characters`
    return null
  },
}
