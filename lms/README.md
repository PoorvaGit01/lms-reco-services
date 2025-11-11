# LMS Service

Learning Management System service built with Ruby on Rails and Sequent (CQRS/Event-Sourcing).

## Quick Start

```bash
# Using Docker (recommended)
docker compose up lms

# Or locally
bundle install
rails db:create db:migrate
rails sequent:migrate:view_schema
rails server
```

## Architecture

### CQRS/Event-Sourcing with Sequent

**Domain Structure**:
- **Aggregates** (`app/domain/aggregates/`): Business entities (Course, Lesson)
- **Commands** (`app/domain/commands/`): User actions (CreateCourse, UpdateCourse, etc.)
- **Events** (`app/domain/events/`): Domain events (CourseCreated, LessonCompleted, etc.)
- **Command Handlers** (`app/domain/command_handlers/`): Routes commands to aggregates
- **Projections** (`app/domain/projections/`): Builds read models from events
- **Read Models** (`app/domain/read_models/`): Optimized query models

### Flow Example

```
User Action → Command → Aggregate → Event → Projection → Read Model → API Response
```

## API Endpoints

### Courses
- `GET /api/courses` - List all courses
  - **Pagination**: `?page=1&per_page=20` (default: page=1, per_page=20, max=100)
  - **Filtering**: 
    - `?title=search_term` - Case-insensitive title search
    - `?instructor_id=instructor-123` - Filter by instructor
  - **Sorting**: 
    - `?sort_by=title|created_at|instructor_id` (default: created_at)
    - `?sort_order=asc|desc` (default: desc)
  - **Response**: 
    ```json
    {
      "data": [...],
      "pagination": {
        "page": 1,
        "per_page": 20,
        "total": 50,
        "total_pages": 3
      }
    }
    ```
  - **Example**: `GET /api/courses?title=Ruby&sort_by=title&sort_order=asc&page=1&per_page=10`
- `GET /api/courses/:id?user_id=:user_id` - Get course with completion %
- `POST /api/courses` - Create course
- `PUT /api/courses/:id` - Update course
- `DELETE /api/courses/:id` - Delete course

### Lessons
- `GET /api/lessons` - List lessons (optional: `?course_id=:id`)
- `GET /api/lessons/:id` - Get lesson details
- `POST /api/lessons` - Create lesson
- `PUT /api/lessons/:id` - Update lesson
- `DELETE /api/lessons/:id` - Delete lesson
- `POST /api/lessons/:id/complete` - Mark lesson as completed

### User Statistics
- `GET /api/users/:id/stats` - Get learning statistics

## Testing

```bash
# Run all tests
bundle exec rspec

# Run domain tests
bundle exec rspec spec/domain/

# Run controller tests
bundle exec rspec spec/controllers/
```

**Test Coverage**: 90%+ on core domains

## Database

- **Event Store**: Stores all domain events
- **View Schema**: Read models for fast queries
- **UUID Primary Keys**: All aggregates use UUIDs

## Key Features

1. **Course Completion Percentage**: Calculated dynamically based on completed lessons
2. **Event-Driven**: Automatically sends LessonCompleted events to Reco service
3. **CQRS**: Separate read and write models for optimal performance
4. **Event Sourcing**: Complete audit trail of all changes
