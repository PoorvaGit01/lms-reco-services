# Learning Management System (LMS) - Microservices Architecture

A Learning Management System built with Ruby on Rails and Sequent (CQRS/Event-Sourcing), composed of two microservices.

## TLDR

```bash
# One command setup
docker compose up

# Services will be available at:
# - LMS Service: http://localhost:3000
# - Recommendation Service: http://localhost:3001
```

## Architecture Overview

This LMS consists of two microservices:

1. **LMS Service** (`/services/lms`): Manages courses, lessons, and learning progress
2. **Recommendation Service** (`/services/reco`): Provides personalized course recommendations

Both services use:
- **Ruby on Rails 7.2** (API mode)
- **Sequent 7.2** for CQRS/Event-Sourcing
- **PostgreSQL 15+** with UUID primary keys
- **RSpec** for testing (targeting 90%+ coverage)

## Prerequisites

- Docker and Docker Compose
- Ruby 3.2+ (for local development)
- PostgreSQL 15+ (for local development)

## Quick Start

### Using Docker Compose (Recommended)

```bash
# Clone the repository
git clone https://github.com/PoorvaGit01/lms-reco-services.git
cd lms-reco-services

# Start all services
docker compose up

# Services will be available at:
# - LMS Service: http://localhost:3000
# - Recommendation Service: http://localhost:3001
```

### Local Development Setup

#### LMS Service

```bash
cd services/lms

# Install dependencies
bundle install

# Setup database
rails db:create db:migrate

# Run Sequent migrations
rails sequent:migrate:view_schema

# Start server
rails server
```

#### Recommendation Service

```bash
cd services/reco

# Install dependencies
bundle install

# Setup database
rails db:create db:migrate

# Run Sequent migrations
rails sequent:migrate:view_schema

# Start server
rails server -p 3001
```

## API Documentation

### LMS Service (Port 3000)

#### Courses

- `GET /api/courses` - List all courses
- `GET /api/courses/:id?user_id=:user_id` - Get course details with completion percentage
- `POST /api/courses` - Create a new course
  ```json
  {
    "title": "Introduction to Ruby",
    "description": "Learn Ruby programming",
    "instructor_id": "instructor-123"
  }
  ```
- `PUT /api/courses/:id` - Update a course
- `DELETE /api/courses/:id` - Delete a course

#### Lessons

- `GET /api/lessons` - List all lessons (optional: `?course_id=:id`)
- `GET /api/lessons/:id` - Get lesson details
- `POST /api/lessons` - Create a new lesson
  ```json
  {
    "course_id": "course-uuid",
    "title": "Lesson 1",
    "content": "Lesson content",
    "order": 1
  }
  ```
- `PUT /api/lessons/:id` - Update a lesson
- `DELETE /api/lessons/:id` - Delete a lesson
- `POST /api/lessons/:id/complete` - Mark lesson as completed
  ```json
  {
    "user_id": "user-123"
  }
  ```

#### User Statistics

- `GET /api/users/:id/stats` - Get learning statistics for a user
  ```json
  {
    "user_id": "user-123",
    "total_lessons_completed": 10,
    "total_courses_enrolled": 2,
    "courses": [
      {
        "course_id": "course-uuid",
        "title": "Course Title",
        "completion_percentage": 75.5
      }
    ]
  }
  ```

### Recommendation Service (Port 3001)

#### Course Recommendations

- `GET /api/users/:id/next_course` - Get next course recommendation
  ```json
  {
    "user_id": "user-123",
    "recommended_course": {
      "course_id": "course-uuid",
      "title": "Recommended Course",
      "reason": "Based on your completion history"
    }
  }
  ```

## Testing

### Run Tests

```bash
# LMS Service
cd services/lms
bundle exec rspec

# Recommendation Service
cd services/reco
bundle exec rspec
```

### Test Coverage

Both services target 90%+ test coverage on core domain logic. Coverage reports are generated using SimpleCov.

## Design Decisions

### CQRS/Event-Sourcing with Sequent

- **Why Sequent?**: Provides a robust framework for CQRS and Event-Sourcing in Ruby, ensuring domain events are properly stored and projections are maintained.
- **Aggregates**: Course and Lesson aggregates handle business logic and enforce invariants.
- **Projections**: Read models are built from events, enabling fast queries and eventual consistency.

### Microservices Architecture

- **Separation of Concerns**: LMS service handles core learning functionality, while Recommendation service focuses on personalized recommendations.
- **Event-Driven Communication**: Services communicate via events (currently synchronous, can be extended to async via Redis Streams/NATS).
- **Independent Deployment**: Each service has its own database and can be deployed independently.

### Database Design

- **UUID Primary Keys**: All aggregates use UUIDs for better distributed system support.
- **View Schema**: Read models are stored in a separate `view_schema` for clear separation.
- **Event Store**: All domain events are stored in the event_records table for audit and replay capabilities.

## Trade-offs

1. **Eventual Consistency**: Read models may be slightly behind write models, but this is acceptable for most queries.
2. **Complexity**: CQRS/Event-Sourcing adds complexity but provides better scalability and auditability.
3. **Synchronous Communication**: Currently services communicate synchronously; async messaging would improve decoupling.

## Future Work

- [ ] Implement async event propagation (Redis Streams/NATS)
- [ ] Add JWT authentication
- [ ] Implement pagination and filtering on GET /courses
- [ ] Add CI/CD pipeline (GitHub Actions/GitLab CI)
- [ ] Enhance recommendation algorithm with ML
- [ ] Add comprehensive API documentation (Swagger/OpenAPI)
- [ ] Implement rate limiting
- [ ] Add monitoring and logging (Prometheus, Grafana)

## Sample API Collection

### HTTPie Script Examples

A comprehensive HTTPie script is available at `docs/api_examples.httpie` demonstrating all core API flows.

#### Installation

```bash
# Install HTTPie
pip install httpie

# Or using package manager
# macOS: brew install httpie
# Ubuntu/Debian: sudo apt-get install httpie
```

#### Usage

**Method 1: Copy and Paste Individual Commands**

```bash
# Start services first
docker compose up

# Then copy any command from docs/api_examples.httpie and run it
http GET http://localhost:3000/api/courses
```

**Method 2: Run Complete Workflow**

```bash
# Navigate to docs directory
cd docs

# Run the complete workflow (skips comments)
bash <(grep -v '^#' api_examples.httpie | grep -v '^$')
```

**Method 3: Interactive Testing**

```bash
# Open the file and copy commands one by one
cat docs/api_examples.httpie

# Or use with variables
COURSE_ID="your-course-uuid"
http GET http://localhost:3000/api/courses/$COURSE_ID user_id==user-123
```

#### Example Workflow

```bash
# 1. Create a course
COURSE_RESPONSE=$(http POST http://localhost:3000/api/courses \
  title="Ruby Fundamentals" \
  description="Learn Ruby from scratch" \
  instructor_id="instructor-123" --print=b)

COURSE_ID=$(echo $COURSE_RESPONSE | jq -r '.id')
echo "Created course: $COURSE_ID"

# 2. Create a lesson
LESSON_RESPONSE=$(http POST http://localhost:3000/api/lessons \
  course_id=$COURSE_ID \
  title="Introduction" \
  content="Welcome to Ruby" \
  order:=1 --print=b)

LESSON_ID=$(echo $LESSON_RESPONSE | jq -r '.id')
echo "Created lesson: $LESSON_ID"

# 3. Complete the lesson
http POST http://localhost:3000/api/lessons/$LESSON_ID/complete \
  user_id="user-123"

# 4. Get user statistics
http GET http://localhost:3000/api/users/user-123/stats

# 5. Get course recommendation
http GET http://localhost:3001/api/users/user-123/next_course
```

#### Script Contents

The `docs/api_examples.httpie` file includes:

- ✅ **LMS Service APIs**: Courses, Lessons, User Statistics
- ✅ **Recommendation Service APIs**: Course Recommendations
- ✅ **Complete Workflow Examples**: End-to-end scenarios
- ✅ **Error Handling Examples**: Testing error cases
- ✅ **Integration Examples**: LMS → Reco event flow

#### Tips

- Use `jq` for pretty JSON output: `http GET ... | jq`
- Save responses to variables: `RESPONSE=$(http GET ... --print=b)`
- Use `--print=HhBb` to see headers and body
- Replace placeholder IDs (`:course_id`, `:lesson_id`) with actual UUIDs

## Project Structure

```
.
├── services/
│   ├── lms/              # LMS Service
│   │   ├── app/
│   │   │   ├── controllers/
│   │   │   ├── domain/    # Domain models (Commands, Events, Aggregates, Projections)
│   │   │   └── services/
│   │   ├── db/
│   │   │   └── migrate/
│   │   └── spec/
│   └── reco/             # Recommendation Service
│       ├── app/
│       │   ├── controllers/
│       │   ├── domain/
│       │   └── services/
│       ├── db/
│       └── spec/
├── docs/
│   └── diagram.puml      # Architecture diagram
└── docker-compose.yml
```

## License

MIT

