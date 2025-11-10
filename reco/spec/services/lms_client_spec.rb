require 'rails_helper'
require 'net/http'

RSpec.describe LmsClient do
  let(:base_url) { 'http://lms:3000' }

  before do
    allow(ENV).to receive(:fetch).with('LMS_SERVICE_URL', 'http://lms:3000').and_return(base_url)
  end

  describe '.get_courses' do
    let(:courses_response) do
      [
        { 'id' => 'course-1', 'title' => 'Course 1' },
        { 'id' => 'course-2', 'title' => 'Course 2' }
      ]
    end

    context 'when request succeeds' do
      it 'returns parsed courses array' do
        response = double('response', code: '200', body: courses_response.to_json)
        http = double('http')
        request = double('request')

        allow(Net::HTTP).to receive(:new).with('lms', 3000).and_return(http)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:open_timeout=)
        allow(Net::HTTP::Get).to receive(:new).with('/api/courses').and_return(request)
        allow(request).to receive(:[]=).with('Content-Type', 'application/json')
        allow(http).to receive(:request).with(request).and_return(response)

        result = LmsClient.get_courses

        expect(result).to eq(courses_response)
      end

      it 'returns empty array when response body is empty' do
        response = double('response', code: '200', body: '[]')
        http = double('http')
        request = double('request')

        allow(Net::HTTP).to receive(:new).with('lms', 3000).and_return(http)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:open_timeout=)
        allow(Net::HTTP::Get).to receive(:new).with('/api/courses').and_return(request)
        allow(request).to receive(:[]=).with('Content-Type', 'application/json')
        allow(http).to receive(:request).and_return(response)

        result = LmsClient.get_courses

        expect(result).to eq([])
      end
    end

    context 'when request fails' do
      it 'returns empty array on non-200 status' do
        response = double('response', code: '500', body: 'Internal Server Error')
        http = double('http')
        request = double('request')

        allow(Net::HTTP).to receive(:new).with('lms', 3000).and_return(http)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:open_timeout=)
        allow(Net::HTTP::Get).to receive(:new).with('/api/courses').and_return(request)
        allow(request).to receive(:[]=).with('Content-Type', 'application/json')
        allow(http).to receive(:request).and_return(response)
        allow(Rails.logger).to receive(:error)

        result = LmsClient.get_courses

        expect(result).to eq([])
        expect(Rails.logger).to have_received(:error).with(match(/Failed to fetch courses from LMS/))
      end

      it 'logs error message with response body when request fails' do
        long_body = 'x' * 500
        response = double('response', code: '500', body: long_body)
        http = double('http')
        request = double('request')

        allow(Net::HTTP).to receive(:new).with('lms', 3000).and_return(http)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:open_timeout=)
        allow(Net::HTTP::Get).to receive(:new).with('/api/courses').and_return(request)
        allow(request).to receive(:[]=).with('Content-Type', 'application/json')
        allow(http).to receive(:request).and_return(response)
        allow(Rails.logger).to receive(:error)

        result = LmsClient.get_courses

        expect(result).to eq([])
        # Verify logger was called with truncated body (first 200 chars)
        expect(Rails.logger).to have_received(:error).with(match(/500.*#{long_body[0..200]}/))
      end

      it 'handles network errors gracefully' do
        allow(Net::HTTP).to receive(:new).and_raise(SocketError.new('Connection refused'))
        allow(Rails.logger).to receive(:error)

        result = LmsClient.get_courses

        expect(result).to eq([])
        expect(Rails.logger).to have_received(:error).with(match(/Error fetching courses from LMS/))
      end

      it 'handles timeout errors gracefully' do
        allow(Net::HTTP).to receive(:new).and_raise(Timeout::Error.new('Request timeout'))
        allow(Rails.logger).to receive(:error)

        result = LmsClient.get_courses

        expect(result).to eq([])
        expect(Rails.logger).to have_received(:error).with(match(/Error fetching courses from LMS/))
      end

      it 'handles JSON parsing errors gracefully' do
        response = double('response', code: '200', body: 'invalid json')
        http = double('http')
        request = double('request')

        allow(Net::HTTP).to receive(:new).with('lms', 3000).and_return(http)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:open_timeout=)
        allow(Net::HTTP::Get).to receive(:new).with('/api/courses').and_return(request)
        allow(request).to receive(:[]=).with('Content-Type', 'application/json')
        allow(http).to receive(:request).and_return(response)
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
        allow(Rails.logger).to receive(:error)

        result = LmsClient.get_courses

        expect(result).to eq([])
        expect(Rails.logger).to have_received(:error).with(match(/Error fetching courses from LMS/))
      end
    end
  end

  describe '.get_course' do
    let(:course_id) { 'course-123' }
    let(:course_response) { { 'id' => course_id, 'title' => 'Test Course' } }

    context 'when request succeeds' do
      it 'returns parsed course hash' do
        response = double('response', code: '200', body: course_response.to_json)
        http = double('http')
        request = double('request')

        allow(Net::HTTP).to receive(:new).with('lms', 3000).and_return(http)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:open_timeout=)
        allow(Net::HTTP::Get).to receive(:new).with('/api/courses/course-123').and_return(request)
        allow(request).to receive(:[]=).with('Content-Type', 'application/json')
        allow(http).to receive(:request).and_return(response)

        result = LmsClient.get_course(course_id)

        expect(result).to eq(course_response)
      end

      it 'includes user_id in query string when provided' do
        user_id = 'user-123'
        response = double('response', code: '200', body: course_response.to_json)
        http = double('http')
        request = double('request')

        allow(Net::HTTP).to receive(:new).with('lms', 3000).and_return(http)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:open_timeout=)
        allow(Net::HTTP::Get).to receive(:new).with('/api/courses/course-123?user_id=user-123').and_return(request)
        allow(request).to receive(:[]=).with('Content-Type', 'application/json')
        allow(http).to receive(:request).and_return(response)

        result = LmsClient.get_course(course_id, user_id)

        expect(result).to eq(course_response)
      end

      it 'handles course without user_id parameter' do
        response = double('response', code: '200', body: course_response.to_json)
        http = double('http')
        request = double('request')

        allow(Net::HTTP).to receive(:new).with('lms', 3000).and_return(http)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:open_timeout=)
        allow(Net::HTTP::Get).to receive(:new).with('/api/courses/course-123').and_return(request)
        allow(request).to receive(:[]=).with('Content-Type', 'application/json')
        allow(http).to receive(:request).and_return(response)

        result = LmsClient.get_course(course_id, nil)

        expect(result).to eq(course_response)
      end

      it 'handles course with empty string user_id' do
        user_id = ''
        response = double('response', code: '200', body: course_response.to_json)
        http = double('http')
        request = double('request')

        allow(Net::HTTP).to receive(:new).with('lms', 3000).and_return(http)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:open_timeout=)
        allow(Net::HTTP::Get).to receive(:new).with('/api/courses/course-123?user_id=').and_return(request)
        allow(request).to receive(:[]=).with('Content-Type', 'application/json')
        allow(http).to receive(:request).and_return(response)

        result = LmsClient.get_course(course_id, user_id)

        expect(result).to eq(course_response)
      end

      it 'handles course with query string when user_id is provided' do
        user_id = 'user-123'
        response = double('response', code: '200', body: course_response.to_json)
        http = double('http')
        request = double('request')

        allow(Net::HTTP).to receive(:new).with('lms', 3000).and_return(http)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:open_timeout=)
        allow(Net::HTTP::Get).to receive(:new).with("/api/courses/course-123?user_id=#{user_id}").and_return(request)
        allow(request).to receive(:[]=).with('Content-Type', 'application/json')
        allow(http).to receive(:request).and_return(response)

        result = LmsClient.get_course(course_id, user_id)

        expect(result).to eq(course_response)
      end
    end

    context 'when request fails' do
      it 'returns nil on non-200 status' do
        response = double('response', code: '404', body: 'Not Found')
        http = double('http')
        request = double('request')

        allow(Net::HTTP).to receive(:new).with('lms', 3000).and_return(http)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:open_timeout=)
        allow(Net::HTTP::Get).to receive(:new).with('/api/courses/course-123').and_return(request)
        allow(request).to receive(:[]=).with('Content-Type', 'application/json')
        allow(http).to receive(:request).and_return(response)
        allow(Rails.logger).to receive(:error)

        result = LmsClient.get_course(course_id)

        expect(result).to be_nil
        expect(Rails.logger).to have_received(:error).with(match(/Failed to fetch course from LMS/))
      end

      it 'logs error when network error occurs' do
        allow(Net::HTTP).to receive(:new).and_raise(SocketError.new('Connection refused'))
        allow(Rails.logger).to receive(:error)

        result = LmsClient.get_course(course_id)

        expect(result).to be_nil
        expect(Rails.logger).to have_received(:error).with(match(/Error fetching course from LMS/))
      end

      it 'handles JSON parsing errors gracefully' do
        response = double('response', code: '200', body: 'invalid json')
        http = double('http')
        request = double('request')

        allow(Net::HTTP).to receive(:new).with('lms', 3000).and_return(http)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:open_timeout=)
        allow(Net::HTTP::Get).to receive(:new).with('/api/courses/course-123').and_return(request)
        allow(request).to receive(:[]=).with('Content-Type', 'application/json')
        allow(http).to receive(:request).and_return(response)
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
        allow(Rails.logger).to receive(:error)

        result = LmsClient.get_course(course_id)

        expect(result).to be_nil
        expect(Rails.logger).to have_received(:error).with(match(/Error fetching course from LMS/))
      end
    end
  end

  describe '.get_user_stats' do
    let(:user_id) { 'user-123' }
    let(:stats_response) do
      {
        'user_id' => user_id,
        'total_lessons_completed' => 10,
        'total_courses_enrolled' => 3,
        'courses' => [
          { 'course_id' => 'course-1', 'title' => 'Course 1', 'completion_percentage' => 50.0 }
        ]
      }
    end

    context 'when request succeeds' do
      it 'returns parsed stats hash' do
        response = double('response', code: '200', body: stats_response.to_json)
        http = double('http')
        request = double('request')

        allow(Net::HTTP).to receive(:new).with('lms', 3000).and_return(http)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:open_timeout=)
        allow(Net::HTTP::Get).to receive(:new).with("/api/users/#{user_id}/stats").and_return(request)
        allow(request).to receive(:[]=).with('Content-Type', 'application/json')
        allow(http).to receive(:request).and_return(response)

        result = LmsClient.get_user_stats(user_id)

        expect(result).to eq(stats_response)
      end
    end

    context 'when request fails' do
      it 'returns nil on non-200 status' do
        response = double('response', code: '404', body: 'Not Found')
        http = double('http')
        request = double('request')

        allow(Net::HTTP).to receive(:new).with('lms', 3000).and_return(http)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:open_timeout=)
        allow(Net::HTTP::Get).to receive(:new).with("/api/users/#{user_id}/stats").and_return(request)
        allow(request).to receive(:[]=).with('Content-Type', 'application/json')
        allow(http).to receive(:request).and_return(response)
        allow(Rails.logger).to receive(:error)

        result = LmsClient.get_user_stats(user_id)

        expect(result).to be_nil
        expect(Rails.logger).to have_received(:error).with(match(/Failed to fetch user stats from LMS/))
      end

      it 'logs error when network error occurs' do
        allow(Net::HTTP).to receive(:new).and_raise(SocketError.new('Connection refused'))
        allow(Rails.logger).to receive(:error)

        result = LmsClient.get_user_stats(user_id)

        expect(result).to be_nil
        expect(Rails.logger).to have_received(:error).with(match(/Error fetching user stats from LMS/))
      end

      it 'logs error when timeout occurs' do
        allow(Net::HTTP).to receive(:new).and_raise(Timeout::Error.new('Request timeout'))
        allow(Rails.logger).to receive(:error)

        result = LmsClient.get_user_stats(user_id)

        expect(result).to be_nil
        expect(Rails.logger).to have_received(:error).with(match(/Error fetching user stats from LMS/))
      end

      it 'handles JSON parsing errors gracefully' do
        response = double('response', code: '200', body: 'invalid json')
        http = double('http')
        request = double('request')

        allow(Net::HTTP).to receive(:new).with('lms', 3000).and_return(http)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:open_timeout=)
        allow(Net::HTTP::Get).to receive(:new).with("/api/users/#{user_id}/stats").and_return(request)
        allow(request).to receive(:[]=).with('Content-Type', 'application/json')
        allow(http).to receive(:request).and_return(response)
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
        allow(Rails.logger).to receive(:error)

        result = LmsClient.get_user_stats(user_id)

        expect(result).to be_nil
        expect(Rails.logger).to have_received(:error).with(match(/Error fetching user stats from LMS/))
      end
    end
  end
end

