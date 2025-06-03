# Architecture Decisions

## Overview

This document captures key architectural decisions made during the development of the Activity Tracker API.

## Decision Record

### ADR-001: API-Only Architecture
**Status**: Accepted  
**Date**: 2025-06-03

**Context**: Need to build a flexible activity tracking system that can serve multiple frontends.

**Decision**: Implement as Rails API-only application.

**Consequences**:
- ✅ Clean separation of concerns
- ✅ Can serve web, mobile, and third-party integrations
- ✅ Smaller memory footprint
- ❌ No built-in UI for quick demos

### ADR-002: Database Design - JSONB for Metadata
**Status**: Accepted  
**Date**: 2025-06-03

**Context**: Activities need flexible metadata that varies by type.

**Decision**: Use PostgreSQL JSONB column instead of separate tables.

**Consequences**:
- ✅ Schema flexibility
- ✅ Indexed JSON queries
- ✅ Single table simplicity
- ❌ PostgreSQL-specific

### ADR-003: Multi-tenancy Strategy
**Status**: Accepted  
**Date**: 2025-06-03

**Context**: System must support multiple companies with complete data isolation.

**Decision**: Row-level multi-tenancy with company_id.

**Alternatives Considered**:
1. **Schema-based**: Too complex for this use case
2. **Database-per-tenant**: Overkill for current requirements

## System Architecture