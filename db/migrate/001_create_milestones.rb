class CreateMilestones < ActiveRecord::Migration[4.2]
  def change
    create_table :milestones, force: true do |t|
      t.string    :name,            null: true
      t.string    :description,     default: ""
      t.date      :effective_date
      t.integer   :user_id,         null: false
      t.integer   :project_id,      null: false
      t.datetime  :created_on
      t.datetime  :updated_on
    end
    add_index :milestones, :user_id,    name: :fk_milestones_user
    add_index :milestones, :project_id, name: :fk_milestones_project
  end
end
