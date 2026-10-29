import { useState } from 'react'
import { NavLink, Outlet, useLocation } from 'react-router'
import { ErrorBoundary } from '../components/ErrorBoundary'
import { Icon } from '../components/Icon'
import { Button } from '../components/ui'
import { AdminProfileProvider, useAdminProfile } from '../lib/adminProfile'
import { useAuth } from '../lib/authContext'
import { navItems } from './navItems'
import './layout.css'

export function AppLayout() {
  return (
    <AdminProfileProvider>
      <Shell />
    </AdminProfileProvider>
  )
}

function Shell() {
  const { profile } = useAdminProfile()
  const { user, signOut } = useAuth()
  const [navOpen, setNavOpen] = useState(false)
  const { pathname } = useLocation()

  return (
    <div className={`shell${navOpen ? ' nav-open' : ''}`}>
      <a className="skip-link" href="#main">
        Skip to content
      </a>
      <aside className="sidebar" aria-label="Primary">
        <div className="brand">
          <span className="brand-mark">
            <Icon name="excavator" size={22} />
          </span>
          <span>
            <strong>JCB Works</strong>
            <small>Developer Admin</small>
          </span>
        </div>
        <nav>
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/'}
              className="nav-link"
              onClick={() => setNavOpen(false)}
            >
              <Icon name={item.icon} />
              {item.label}
            </NavLink>
          ))}
        </nav>
      </aside>
      <button className="scrim" aria-label="Close menu" tabIndex={-1} onClick={() => setNavOpen(false)} />

      <div className="main-col">
        <header className="topbar">
          <button
            className="menu-btn"
            aria-label={navOpen ? 'Close menu' : 'Open menu'}
            aria-expanded={navOpen}
            onClick={() => setNavOpen((o) => !o)}
          >
            <Icon name={navOpen ? 'close' : 'menu'} />
          </button>
          <div className="topbar-spacer" />
          <span className="topbar-user" title={user?.email}>
            {user?.email}
            {profile && <small className="role"> · {profile.role === 'super' ? 'Super admin' : 'Support admin'}</small>}
          </span>
          <Button variant="ghost" icon="logout" onClick={signOut}>
            Sign out
          </Button>
        </header>
        <main id="main" className="content" tabIndex={-1}>
          <ErrorBoundary key={pathname}>
            <Outlet />
          </ErrorBoundary>
        </main>
      </div>
    </div>
  )
}
