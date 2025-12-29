# RUM and Synthetic Tests

## Real User Monitoring (RUM)

Use RUM to understand:
- Page load performance.
- User geography and device breakdown.
- JS errors and UX issues.

You can embed the Datadog RUM snippet into the frontend and tag sessions with:
- User ID (if available).
- Release version.
- Environment (prod, staging).

## Synthetic Tests

Use synthetics to:
- Test API endpoints from multiple regions.
- Validate login and core user flows.
- Run tests before and during major events.

This repo’s `synthetic-test-run.sh` provides a CLI-friendly way to run basic availability checks as part of CI/CD or cron-based health checks.