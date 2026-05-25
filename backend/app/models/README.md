# Models

This directory contains SQLAlchemy ORM models for the price monitoring system.

## Model Relationships

```
User (1) ──────< Product (N)
  │                 │
  │                 ├──< PriceHistory (N)
  │                 ├──< Alert (N)
  │                 └──< CrawlLog (N)
  │
  ├──< Session (N)
  ├──< LoginLog (N)
  ├──< UserAuditLog (N)
  ├──< JobSearchConfig (N) ────< Job (N) ────< MatchResult (N)
  ├──< UserResume (N) ───────────────┘
  └──< ResourcePermission (N)

Role (N) >────< Permission (N)
```

## Usage

Import models from `app.models`:

```python
from app.models import User, Product, PriceHistory, Alert, CrawlLog
```

`app.models.__init__` exports the most commonly used models. Domain-specific models such as `Session`, `LoginLog`, `Job`, `JobSearchConfig`, and `ResourcePermission` can also be imported from their concrete modules when needed.

## Indexes

- `products`: (user_id, platform, active)
- `products_price_history`: (product_id, scraped_at DESC)
- `crawl_logs`: (product_id, timestamp DESC)
- `users_sessions`: session/user and refresh-token hash indexes
- `users_permissions` / `users_roles_permissions`: DB-backed RBAC lookup
- `jobs`: search config, platform/job identity, active status, and last-active indexes
