require 'net/http'
require 'json'

class JobRecordsController < ApplicationController
  def index
    @job_records = JobRecord.all
  end

  # temporary hardcoded
  def parse_job_details
    page_content = <<~PAGE_CONTENT
      76344 - Firmware Designer
          Genetec
          Job Posting Status: 	Approved
          Internal Status 	Not Set
          Actions

              Posting Detail

              Overview
              Map

          Organization
          Name of Organization 	Genetec
          Job Posting Information / Information sur le poste
          Job Title / Titre du poste: 	Firmware Designer
          Job Location / Lieu du stage: 	2280 Alfred-Nobel Blvd
          Job Location Type / Type de stage: 	Hybrid (remotely & On-site) / Hybride (télétravail et présentiel)
          Salary (specify $/hour or $/year) / Salaire (préciser $/heure ou $/année): 	Non spécifié/Not Specified
          Number of Positions / Nombre de postes: 	1
          Duration / Durée: 	4 Months / 4 Mois
          Job Description / Description de poste:

          Who are we?

          We're a Quebec-based company offering unified security solutions that combine IP video surveillance, access control, automatic license plate recognition and much more! The company was founded on the principle of innovation, and is constantly on the lookout for emerging technologies. Our collaborative environment will enable you to put your ideas to good use and take part in rewarding projects.

          Why work at Genetec?

          We offer a range of incredible benefits, including a low-cost bistro, a free 24-hour gym, unlimited fruit and coffee, free parking and several special events. An internship at Genetec is a must for anyone looking for a rewarding work experience. Take the first step towards starting your career with us by applying for this internship opportunity!

          Your role and your team

          Hardware developers at Genetec apply their creative and technical talents to design new products and features for the automatic license plate recognition (ALPR) market. They work closely with the product management team in order to meet customer expectations.

          An embedded software development position at Genetec is an opportunity to participate in the development of a product that is used daily by municipalities and law enforcement agencies in traffic surveillance.

          The intern is an integral part of the hardware development group and works on the development of features along with the other developers. Each internship is an investment for us to discover new talents who can join the research and development team once they have completed their studies.

          Your responsibilities

              Design, implement and integrate embedded software ("firmware") for various systems ("bare metal" or RTOS)

              Develop and maintain low-level libraries (BSP, HAL)

              Develop test code (unit testing, regression testing) to ensure that the design (software and electronics) meets the requirements

              Debug and resolve problems in the embedded software (firmware)

              Conduct experiments on new operating principles, including the completion of special setups for R&D

              Participate in brainstorming sessions for the design of a new product (architecture phase)

          Requirements

              Bachelor's degree in electrical or computer engineering

              Relevant experience in embedded software development (ARM architecture)

              Knowledge of the C/C++ programming language

              Understanding of communication protocols (I2C, SPI, UART, USB)

              Ability to understand schematics and work with electronic designers

              Knowledge of the use of digital oscilloscope and other common debugging tools (multimeter, logic analyzer...)

              Ability to communicate in French and English

              Strong autonomy and creativity, enjoy challenges

              Results oriented

          Assets

              Familiarity with C# development with Visual Studio (.NET / .NET Core)

              Knowledge of networking (Ethernet, TCP/IP)

    PAGE_CONTENT
    prompt = <<~PROMPT
      Extract the job title, company name, and job description from the following webpage content.#{' '}
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
                           url: 'tbd',
                           status: 'applied',
                           raw_html: 'tbd'
                         })
      @job_record = JobRecord.new(job_details)

      if @job_record.save!
        render json: @job_record, status: :created
      else
        render json: @job_record.errors, status: :unprocessable_entity
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
