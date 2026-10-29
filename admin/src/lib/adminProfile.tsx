import { createContext, useContext, type ReactNode } from 'react'
import { can, useAdminApi, type AdminPermission, type AdminProfile } from './adminApi'
import { useAsync } from './hooks'

interface ProfileValue {
  profile: AdminProfile | null
  can: (p: AdminPermission) => boolean
}

const ProfileContext = createContext<ProfileValue>({ profile: null, can: () => false })

/** Loads the signed-in admin's role so the UI only offers allowed actions. */
export function AdminProfileProvider({ children }: { children: ReactNode }) {
  const api = useAdminApi()
  const { data } = useAsync(() => api.me(), [api])
  const profile = data ?? null
  return <ProfileContext.Provider value={{ profile, can: (p) => can(profile, p) }}>{children}</ProfileContext.Provider>
}

// oxlint-disable-next-line react/only-export-components
export const useAdminProfile = () => useContext(ProfileContext)
