class CreateJobRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :job_records do |t|
      t.string :title
      t.string :company
      t.text :description
      t.datetime :date_applied
      t.string :url
      t.string :status
      t.text :raw_html

      t.timestamps
    end
  end
end
