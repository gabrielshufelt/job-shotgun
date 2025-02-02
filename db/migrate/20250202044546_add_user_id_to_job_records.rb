class AddUserIdToJobRecords < ActiveRecord::Migration[8.0]
  def change
    add_reference :job_records, :user, null: false, foreign_key: true
  end
end
