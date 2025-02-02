Rails.application.routes.draw do
  get 'home/index'
  devise_for :users

  root 'home#index'

  get 'jobs', to: 'job_records#index'
  get 'jobs/parse_job_details', to: 'job_records#parse_job_details'
end
