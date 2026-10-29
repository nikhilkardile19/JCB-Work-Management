import { Link } from 'react-router'
import { Card, EmptyState } from '../../components/ui'

export function NotFoundPage() {
  return (
    <Card>
      <EmptyState
        icon="alert"
        title="Page not found"
        message="The page you were looking for does not exist."
        action={<Link to="/">Back to dashboard</Link>}
      />
    </Card>
  )
}
