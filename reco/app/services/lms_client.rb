# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

class LmsClient
  BASE_URL = ENV.fetch('LMS_SERVICE_URL', 'http://lms:3000')

  def self.get_courses
    uri = URI("#{BASE_URL}/api/courses")
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 5
    http.open_timeout = 5

    request = Net::HTTP::Get.new(uri.path)
    request['Content-Type'] = 'application/json'
    response = http.request(request)

    if response.code.to_i == 200
      JSON.parse(response.body)
    else
      Rails.logger.error "Failed to fetch courses from LMS: #{response.code} - #{response.body[0..200]}"
      []
    end
  rescue StandardError => e
    Rails.logger.error "Error fetching courses from LMS: #{e.message}"
    []
  end

  def self.get_course(course_id, user_id = nil)
    url = "#{BASE_URL}/api/courses/#{course_id}"
    url += "?user_id=#{user_id}" if user_id

    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 5
    http.open_timeout = 5

    request = Net::HTTP::Get.new(uri.path + (uri.query ? "?#{uri.query}" : ""))
    request['Content-Type'] = 'application/json'

    response = http.request(request)

    if response.code.to_i == 200
      JSON.parse(response.body)
    else
      Rails.logger.error "Failed to fetch course from LMS: #{response.code}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "Error fetching course from LMS: #{e.message}"
    nil
  end

  def self.get_user_stats(user_id)
    uri = URI("#{BASE_URL}/api/users/#{user_id}/stats")
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 5
    http.open_timeout = 5

    request = Net::HTTP::Get.new(uri.path)
    request['Content-Type'] = 'application/json'

    response = http.request(request)

    if response.code.to_i == 200
      JSON.parse(response.body)
    else
      Rails.logger.error "Failed to fetch user stats from LMS: #{response.code}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "Error fetching user stats from LMS: #{e.message}"
    nil
  end
end
