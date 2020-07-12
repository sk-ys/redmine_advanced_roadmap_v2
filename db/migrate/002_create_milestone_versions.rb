class CreateMilestoneVersions < ActiveRecord::Migration[4.2]
  create_table :milestone_versions, force: true do |t|
    t.integer   :milestone_id, null: true
    t.integer   :version_id,   null: true
    t.datetime  :created_on
  end
  add_index :milestone_versions, :milestone_id, name: :fk_milestone_versions_milestone
  add_index :milestone_versions, :version_id,   name: :fk_milestone_versions_version
end
