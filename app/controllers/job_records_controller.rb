require 'net/http'
require 'json'

class JobRecordsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:parse_job_details, :create]

  def index
    email = params[:email]
    user = User.find_by(email: email)
    if user
      # @job_records = [user.first_name]
      @job_records = JobRecord.where(user_id: user.id).order(:date_applied)
      render json: @job_records
    else
      render json: { error: "User not found" }, status: :not_found
    end
  end

  def create
    title = params[:title]
    company = params[:company]
    description = params[:description]
    url = params[:url]
    raw_html = params[:raw_html]
    email = params[:email]

    @job_record = JobRecord.new(
      title:,
      company:,
      description:,
      date_applied: Date.today,
      url:,
      status: 'applied',
      raw_html:,
      user_id: User.find_by(email:).id
    )

    if @job_record.save!
      render json: @job_record, status: :created
    else
      render json: @job_record.errors, status: :unprocessable_entity, status: 420
    end
  end

  def parse_job_details
    url = params[:url]
    page_content = params[:page_content]
    raw_html = params[:raw_html]
    email = params[:email]

    prompt = <<~PROMPT
      Extract the job title, company name, and job description from the following webpage content.
      The job description should be extracted in its entirety without any summarization or omission.

      Return your answer in a JSON format like this:
      {
      "title": "the job title",
      "description": "the full job description",
      "companyName": "the company name"
      }

      If any of the fields (title, description, companyName) are not found in the content, return an empty string for that field.

      Content:
      #{page_content}
    PROMPT

    response = call_gpt4o_mini(prompt)

    if response
      job_details = parse_response(response)
      job_details.merge!({
                           date_applied: Date.today,
                           url:,
                           status: 'applied',
                           raw_html:,
                           user_id: User.find_by(email:).id
                         })
      @job_record = JobRecord.new(job_details)

      if @job_record.save!
        render json: @job_record, status: :created
      else
        render json: @job_record.errors, status: :unprocessable_entity, status: 420
      end
    else
      render json: { error: 'Failed to get response from AI service' }, status: :unprocessable_entity
    end
  end

  private

  def call_gpt4o_mini(prompt)
    uri = URI('https://api.openai.com/v1/chat/completions')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path, {
                                    'Content-Type' => 'application/json',
                                    'Authorization' => "Bearer #{ENV['OPENAI_API_KEY']}"
                                  })

    request.body = {
      model: 'gpt-4o-mini',
      messages: [
        { role: 'user', content: prompt }
      ]
    }.to_json

    response = http.request(request)

    JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
  end

  def parse_response(response)
    json_text = response['choices'][0]['message']['content']
    json_text = json_text.gsub(/^```json\n/, '').gsub(/```\s*$/, '')

    job_details = JSON.parse(json_text)
    {
      title: job_details['title'],
      description: job_details['description'],
      company: job_details['companyName']
    }
  end
end
