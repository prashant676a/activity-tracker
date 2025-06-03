# API Documentation

Base URL: `localhost:3000/`

## Authentication

All endpoints require Bearer token authentication:

## EndPoints

## Example Request
```bash
  curl -X GET "https://api.activitytracker.com/v1/admin/activities?activity_type=login&page=1" \
  -H "Authorization: Bearer your-token-here"
```

## Example Response
```bash
  {
    "activities": [
      {
        "id": 12345,
        "user": {
          "id": 123,
          "name": "John Doe",
          "email": "john@example.com",
          "deleted": false
        },
        "activity_type": "login",
        "metadata": {
          "user_agent": "Mozilla/5.0...",
          "login_method": "password"
        },
        "occurred_at": "2025-06-03T10:30:00Z"
      }
    ],
    "meta": {
      "current_page": 1,
      "total_pages": 5,
      "total_count": 234,
      "per_page": 50
    }
  }
```