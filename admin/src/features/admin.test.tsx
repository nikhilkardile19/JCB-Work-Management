import { cleanup, fireEvent, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, beforeEach, describe, expect, it } from 'vitest'
import { FakeAdminApi } from '../test/fakeAdminApi'
import { renderSignedIn } from '../test/renderApp'

let api: FakeAdminApi
const user = () => userEvent.setup()
const path = () => screen.getByTestId('path').textContent

beforeEach(() => {
  api = new FakeAdminApi()
})
afterEach(cleanup)

async function dialog() {
  return within(await screen.findByRole('dialog'))
}

describe('dashboard', () => {
  it('shows live metrics and recent activity', async () => {
    const c = api.addCompany({ name: 'Patil Constructions', status: 'active' })
    api.addCompany({ name: 'Shinde Infra' })
    const l = api.addLicense({ companyId: c.id, validUntil: Date.now() + 10 * 86_400_000 })
    api.addDevice({ companyId: c.id, licenseId: l.id })
    await api.setCompanyStatus(c.id, 'active', 'Verified')
    renderSignedIn('/', api)
    expect(await screen.findByText('Companies awaiting approval')).toBeInTheDocument()
    expect(screen.getByText('1 ending within 30 days')).toBeInTheDocument()
    expect(screen.getByText('Company status changed')).toBeInTheDocument()
  })
})

describe('companies', () => {
  it('filters awaiting approval and approves with a reason (audited)', async () => {
    api.addCompany({ name: 'Patil Constructions', status: 'active' })
    const pending = api.addCompany({ name: 'Shinde Infra' })
    renderSignedIn('/companies?status=pending', api)
    expect(await screen.findByRole('link', { name: 'Shinde Infra' })).toBeInTheDocument()
    expect(screen.queryByRole('link', { name: 'Patil Constructions' })).toBeNull()

    await user().click(screen.getByRole('link', { name: 'Shinde Infra' }))
    await user().click(await screen.findByRole('button', { name: 'Approve' }))
    const d = await dialog()
    await user().click(d.getByRole('button', { name: 'Approve' }))
    expect(await d.findByText('Enter a reason (at least 3 characters)')).toBeInTheDocument()
    await user().type(d.getByLabelText('Reason'), 'Verified by phone')
    await user().click(d.getByRole('button', { name: 'Approve' }))
    expect(await screen.findByText('Shinde Infra is now active')).toBeInTheDocument()
    expect(api.companies.find((c) => c.id === pending.id)!.status).toBe('active')
    expect(api.events[0]).toMatchObject({ type: 'company.status', reason: 'Verified by phone' })
  })

  it('searches by name prefix and pages with Load more', async () => {
    for (let i = 0; i < 30; i++) api.addCompany({ name: `Company ${String(i).padStart(2, '0')}` })
    api.addCompany({ name: 'Patil Constructions' })
    renderSignedIn('/companies', api)
    await screen.findByRole('button', { name: 'Load more' })
    expect(screen.getAllByRole('row')).toHaveLength(26) // header + 25
    await user().click(screen.getByRole('button', { name: 'Load more' }))
    expect(await screen.findAllByRole('row')).toHaveLength(32)
    expect(screen.queryByRole('button', { name: 'Load more' })).toBeNull()

    await user().type(screen.getByLabelText('Search by company name'), 'pat')
    // Search runs after a short pause in typing.
    await waitFor(() => expect(screen.getAllByRole('row')).toHaveLength(2))
    expect(screen.getByRole('link', { name: 'Patil Constructions' })).toBeInTheDocument()
  })

  it('creates a company after validating the form', async () => {
    renderSignedIn('/companies', api)
    await user().click(await screen.findByRole('button', { name: 'New company' }))
    const d = await dialog()
    await user().click(d.getByRole('button', { name: 'Create company' }))
    expect(d.getByText('Enter the company name')).toBeInTheDocument()
    expect(d.getByText('Enter the owner’s email')).toBeInTheDocument()
    await user().type(d.getByLabelText('Company name'), 'Jadhav Earthworks')
    await user().type(d.getByLabelText('Contact person'), 'Vikas Jadhav')
    await user().type(d.getByLabelText('Phone'), '9822012345')
    await user().type(d.getByLabelText('Address'), 'Satara Road, Pune')
    await user().type(d.getByLabelText('Invoice prefix'), 'jdw')
    await user().type(d.getByLabelText('Owner’s sign-in email'), 'vikas@jadhav.in')
    await user().click(d.getByRole('button', { name: 'Create company' }))
    expect(await screen.findByRole('heading', { name: 'Jadhav Earthworks' })).toBeInTheDocument()
    expect(api.companies[0]).toMatchObject({ invoicePrefix: 'JDW', status: 'active' })
    expect(path()).toMatch(/^\/companies\/co\d+$/)
  })

  it('issues a license and shows the activation code once', async () => {
    const c = api.addCompany({ name: 'Patil Constructions', status: 'active' })
    renderSignedIn(`/companies/${c.id}`, api)
    expect(await screen.findByText('No license yet')).toBeInTheDocument()
    await user().click(screen.getByRole('button', { name: 'New license' }))
    await user().click((await dialog()).getByRole('button', { name: 'Create license' }))
    const codeDialog = await screen.findByRole('dialog', { name: 'Activation code' })
    expect(within(codeDialog).getByText(api.issuedCodes[0])).toBeInTheDocument()
    await user().click(within(codeDialog).getByRole('button', { name: "I've copied it" }))
    expect(screen.queryByText(api.issuedCodes[0])).toBeNull()
    expect(await screen.findByRole('link', { name: /^LIC/ })).toBeInTheDocument()
  })
})

describe('licenses', () => {
  it('lists active licenses soonest first and suspends with a reason', async () => {
    const c = api.addCompany({ name: 'Patil Constructions', status: 'active' })
    const late = api.addLicense({ companyId: c.id, validUntil: Date.now() + 300 * 86_400_000 })
    api.addLicense({ companyId: c.id, validUntil: Date.now() + 5 * 86_400_000 })
    renderSignedIn('/licenses', api)
    const rows = await screen.findAllByRole('row')
    expect(within(rows[1]).getByText(/days left/)).toHaveTextContent(/^[45] days left$/)

    await user().click(within(rows[2]).getByRole('link', { name: 'Patil Constructions' }))
    await user().click(await screen.findByRole('button', { name: 'Suspend' }))
    const d = await dialog()
    await user().type(d.getByLabelText('Reason'), 'Payment overdue')
    await user().click(d.getByRole('button', { name: 'Suspend' }))
    expect(await screen.findByText('License suspended')).toBeInTheDocument()
    expect(late.status).toBe('suspended')
    expect(await screen.findByRole('button', { name: 'Reactivate' })).toBeInTheDocument()
  })

  it('refuses lowering the phone limit below active phones (server message shown)', async () => {
    const c = api.addCompany({ name: 'Patil', status: 'active' })
    const l = api.addLicense({ companyId: c.id, maxDevices: 3 })
    api.addDevice({ companyId: c.id, licenseId: l.id })
    api.addDevice({ companyId: c.id, licenseId: l.id })
    renderSignedIn(`/licenses/${c.id}/${l.id}`, api)
    await user().click(await screen.findByRole('button', { name: 'Change phones' }))
    const d = await dialog()
    fireEvent.change(d.getByLabelText('Phones allowed'), { target: { value: '1' } })
    await user().type(d.getByLabelText('Reason'), 'Downgrade')
    await user().click(d.getByRole('button', { name: 'Save' }))
    expect(await d.findByText(/2 devices are active/)).toBeInTheDocument()
    expect(l.maxDevices).toBe(3)
  })

  it('a new activation code is shown once', async () => {
    const c = api.addCompany({ name: 'Patil', status: 'active' })
    const l = api.addLicense({ companyId: c.id })
    renderSignedIn(`/licenses/${c.id}/${l.id}`, api)
    await user().click(await screen.findByRole('button', { name: 'Issue new code' }))
    const d = await dialog()
    await user().type(d.getByLabelText('Reason'), 'Owner lost it')
    await user().click(d.getByRole('button', { name: 'Issue new code' }))
    expect(await screen.findByRole('dialog', { name: 'Activation code' })).toHaveTextContent(/JCBW-NEWC/)
  })
})

describe('devices and roles', () => {
  it('revokes a phone with a reason', async () => {
    const c = api.addCompany({ name: 'Patil', status: 'active' })
    const l = api.addLicense({ companyId: c.id })
    const dev = api.addDevice({ companyId: c.id, licenseId: l.id, deviceModel: 'android 14 (Redmi)' })
    renderSignedIn('/devices', api)
    await user().click(await screen.findByRole('link', { name: 'android 14 (Redmi)' }))
    await user().click(await screen.findByRole('button', { name: 'Revoke' }))
    const d = await dialog()
    await user().type(d.getByLabelText('Reason'), 'Phone stolen')
    await user().click(d.getByRole('button', { name: 'Revoke phone' }))
    // Toast and the history entry.
    expect(await screen.findAllByText('Phone revoked')).not.toHaveLength(0)
    expect(dev).toMatchObject({ status: 'revoked', revokeReason: 'Phone stolen' })
    expect(await screen.findByText('Revoked because')).toBeInTheDocument()
  })

  it('support admins see data but not the actions they were not granted', async () => {
    api.profile = { ...api.profile, role: 'support', permissions: ['devices.revoke'] }
    const c = api.addCompany({ name: 'Patil' })
    const l = api.addLicense({ companyId: c.id })
    const dev = api.addDevice({ companyId: c.id, licenseId: l.id })
    renderSignedIn(`/companies/${c.id}`, api)
    expect(await screen.findByRole('heading', { name: 'Patil' })).toBeInTheDocument()
    expect(screen.getByText(/Support admin/)).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Approve' })).toBeNull()
    expect(screen.queryByRole('button', { name: 'Edit' })).toBeNull()
    cleanup()
    renderSignedIn(`/licenses/${c.id}/${l.id}`, api)
    await screen.findByText('Terms')
    expect(screen.queryByRole('button', { name: 'Suspend' })).toBeNull()
    expect(screen.queryByRole('button', { name: 'Issue new code' })).toBeNull()
    cleanup()
    renderSignedIn(`/devices/${c.id}/${dev.id}`, api)
    expect(await screen.findByRole('button', { name: 'Revoke' })).toBeInTheDocument()
  })
})

describe('audit logs', () => {
  it('filters by action', async () => {
    const c = api.addCompany({ name: 'Patil' })
    await api.setCompanyStatus(c.id, 'active', 'ok')
    const l = api.addLicense({ companyId: c.id })
    await api.setLicenseStatus(c.id, l.id, 'suspended', 'late payment')
    renderSignedIn('/audit-logs', api)
    const list = () => within(screen.getByRole('list'))
    expect(await screen.findByRole('list')).toBeInTheDocument()
    expect(list().getByText('Company status changed')).toBeInTheDocument()
    expect(list().getByText('License status changed')).toBeInTheDocument()
    await user().selectOptions(screen.getByLabelText('Action'), 'license.status')
    await waitFor(() => expect(list().queryByText('Company status changed')).toBeNull())
    expect(list().getByText(/late payment/)).toBeInTheDocument()
  })
})

describe('replacement requests', () => {
  function setup() {
    const c = api.addCompany({ name: 'Patil Constructions', status: 'active' })
    const l = api.addLicense({ companyId: c.id, maxDevices: 2 })
    const other = api.addDevice({ companyId: c.id, licenseId: l.id, userId: 'owner', deviceModel: 'Owner phone' })
    const old = api.addDevice({ companyId: c.id, licenseId: l.id, userId: 'ramesh', deviceModel: 'Ramesh old phone' })
    const req = api.addRequest({ companyId: c.id, licenseId: l.id, requestedBy: 'ramesh', reason: 'Phone fell in a trench' })
    return { c, l, other, old, req }
  }

  it('approving swaps the requester’s old phone for the new one', async () => {
    const { old, req } = setup()
    renderSignedIn('/replacement-requests', api)
    expect(await screen.findByText('Phone fell in a trench')).toBeInTheDocument()
    await user().click(screen.getByRole('button', { name: 'Review' }))
    const d = await dialog()
    expect(await d.findByText(/2 of 2 places used/)).toBeInTheDocument()
    // The requester's own phone is preselected; there is no "free place" option.
    expect(d.getByRole('radio', { name: /Ramesh old phone/ })).toBeChecked()
    expect(d.queryByRole('radio', { name: /None/ })).toBeNull()
    await user().type(d.getByLabelText('Reason'), 'Confirmed with owner by phone')
    await user().click(d.getByRole('button', { name: 'Approve' }))
    expect(await screen.findByText('Replacement approved')).toBeInTheDocument()
    expect(old).toMatchObject({ status: 'revoked', replacedBy: req.newDeviceId })
    expect(api.devices.filter((x) => x.status === 'active')).toHaveLength(2)
    expect(req).toMatchObject({ status: 'approved', reviewReason: 'Confirmed with owner by phone' })
    expect(await screen.findByText('No pending requests')).toBeInTheDocument()
  })

  it('rejecting keeps every phone as it was', async () => {
    const { old, req } = setup()
    renderSignedIn('/replacement-requests', api)
    await user().click(await screen.findByRole('button', { name: 'Review' }))
    const d = await dialog()
    await user().click(d.getByRole('radio', { name: 'Reject' }))
    await user().type(d.getByLabelText('Reason'), 'Not a company phone')
    await user().click(d.getByRole('button', { name: 'Reject' }))
    expect(await screen.findByText('Replacement rejected')).toBeInTheDocument()
    expect(old.status).toBe('active')
    expect(api.devices.find((x) => x.id === req.newDeviceId)).toBeUndefined()
    await user().click(screen.getByRole('radio', { name: 'Rejected' }))
    expect(await screen.findByText('Review: Not a company phone')).toBeInTheDocument()
  })

  it('support admins without devices.revoke can see but not review', async () => {
    setup()
    api.profile = { ...api.profile, role: 'support', permissions: [] }
    renderSignedIn('/replacement-requests', api)
    expect(await screen.findByText('Phone fell in a trench')).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Review' })).toBeNull()
  })
})
