/// <reference types="vite/client" />

interface ImportMetaEnv {
  /** REST API base URL including the version prefix, e.g. http://localhost:3000/api/v1. Unset: sign-in shows "not configured". */
  readonly VITE_API_BASE_URL?: string
}
