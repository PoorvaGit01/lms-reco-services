# Recommendation Service

Course recommendation service built with Ruby on Rails and Sequent (CQRS/Event-Sourcing).

## Quick Start

```bash
# Using Docker (recommended)
docker compose up reco

# Or locally
bundle install
rails db:create db:migrate
rails sequent:migrate:view_schema
rails server -p 3001
```

## Architecture

### Domain Structure
- **Events** (`app/domain/events/`): LessonCompleted event
- **Projections** (`app/domain/projections/`): Builds learner history from events
- **Read Models** (`app/domain/read_models/`): LearnerHistory for queries
- **Services** (`app/services/`): Recommendation logic and LMS client

### Recommendation Logic

**New Learners**:
- Fetches available courses from LMS service
- Recommends first available course
- Falls back to default recommendation if LMS unavailable

**Existing Learners**:
- Fetches user stats from LMS service
- Recommends incomplete courses (prioritizes low completion %)
- Falls back to history-based recommendations
- Considers most recent course completions

## API Endpoints

### Course Recommendations
- `GET /api/users/:id/next_course` - Get next course recommendation

### Event Consumption
- `POST /api/events/lesson_completed` - Receive LessonCompleted events from LMS

## Testing

```bash
# Run all tests
bundle exec rspec

# Run service tests
bundle exec rspec spec/services/

# Run controller tests
bundle exec rspec spec/controllers/
```

**Test Coverage**: 90-95%+ on core domains

## Database

- **Event Store**: Stores domain events (if using full Sequent)
- **View Schema**: Learner history read models
- **UUID Primary Keys**: All records use UUIDs

## Key Features

1. **Intelligent Recommendations**: Based on user history and LMS data
2. **Resilient**: Works even if LMS service is unavailable
3. **Event-Driven**: Consumes events from LMS service
4. **LMS Integration**: Fetches courses and user stats from LMS

## Inter-Service Communication

- **Receives**: LessonCompleted events from LMS (HTTP POST)
- **Sends**: Requests to LMS for courses and user stats (HTTP GET)
