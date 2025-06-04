# API Documentation

Base URL: `localhost:3000/`

## Authentication

All endpoints (except login) require Bearer token authentication:
```
Authorization: Bearer <token>
```

## Authentication Endpoints

### Login
```
POST /api/v1/login
Content-Type: application/json

{
  "email": "admin@techcorp.com"
}
```

**Response:**
```json
{
  "message": "Login successful",
  "token": "demo-token-123-1234567890",
  "user": {
    "id": 123,
    "email": "admin@techcorp.com",
    "name": "Admin User",
    "role": "company_admin"
  }
}
```

**Note:** This endpoint automatically tracks a `login` activity.

### Logout
```
DELETE /api/v1/logout
Authorization: Bearer <token>
```

**Response:**
```json
{
  "message": "Logout successful"
}
```

**Note:** This endpoint automatically tracks a `logout` activity with session duration.

## Admin Endpoints

### Get Activities
```
GET /api/v1/admin/activities
Authorization: Bearer <token>
```

**Query Parameters:**
- `activity_type`: Filter by type (login, logout, etc.)
- `user_id`: Filter by user
- `start_date`: Filter from date (YYYY-MM-DD)
- `end_date`: Filter to date (YYYY-MM-DD)
- `page`: Page number (default: 1)
- `per_page`: Items per page (default: 25, max: 100)

### Get Activity Summary
```
GET /api/v1/admin/activities/summary
Authorization: Bearer <token>
```

**Query Parameters:**
- `period`: day, week, month (default: day)
- `group_by`: activity_type, user, hour (default: activity_type)

### Get Activity Stats
```
GET /api/v1/admin/activities/stats
Authorization: Bearer <token>
```

## Example Request Flow

```bash
# 1. Login
curl -X POST "http://localhost:3000/api/v1/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@techcorp.com"}'

# 2. Use the token from login response
curl -X GET "http://localhost:3000/api/v1/admin/activities" \
  -H "Authorization: Bearer demo-token-123-1234567890"

# 3. Logout
curl -X DELETE "http://localhost:3000/api/v1/logout" \
  -H "Authorization: Bearer demo-token-123-1234567890"
```

## Development Mode

In development, you can use query parameters for easier testing:
- `?dev_mode=true` - Auto-authenticates requests
- `?auth_token=dummy-token` - Sets auth token via query param