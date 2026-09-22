# Worked examples

The shapes below follow patterns from 37signals' Fizzy (Card::Closeable, Cards::ClosuresController,
Event::Relaying), rewritten for a generic `Project`. Adapt names; keep the shape.

## 1. A behaviour concern with a state record

```ruby
# app/models/project.rb
class Project < ApplicationRecord
  include Archivable, Commentable

  belongs_to :account, default: -> { Current.account }
  belongs_to :creator, class_name: "User", default: -> { Current.user }
end

# app/models/project/archival.rb
class Project::Archival < ApplicationRecord
  belongs_to :project, touch: true
  belongs_to :user, default: -> { Current.user }
end

# app/models/project/archivable.rb
module Project::Archivable
  extend ActiveSupport::Concern

  included do
    has_one :archival, dependent: :destroy

    scope :archived, -> { joins(:archival) }
    scope :active,   -> { where.missing(:archival) }
  end

  def archived?
    archival.present?
  end

  def archived_by
    archival&.user
  end

  def archive(user: Current.user)
    unless archived?
      create_archival! user: user
    end
  end

  def unarchive
    if archived?
      archival.destroy
      reload_archival
    end
  end
end
```

Migration:

```ruby
create_table :project_archivals do |t|
  t.references :project, null: false, foreign_key: true, index: { unique: true }
  t.references :user, null: false, foreign_key: true
  t.timestamps
end
```

(Rails infers the `project_archivals` table for `Project::Archival` because `Project` is a model.)

## 2. The matching singular-resource controller

```ruby
# config/routes.rb
resources :projects do
  resource :archival, only: %i[ create destroy ], module: :projects
end

# app/controllers/concerns/project_scoped.rb
module ProjectScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_project
  end

  private
    def set_project
      @project = Current.account.projects.find(params[:project_id])
    end
end

# app/controllers/projects/archivals_controller.rb
class Projects::ArchivalsController < ApplicationController
  include ProjectScoped

  def create
    @project.archive

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @project }
      format.json { head :no_content }
    end
  end

  def destroy
    @project.unarchive

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @project }
      format.json { head :no_content }
    end
  end
end
```

## 3. A `_later` / `_now` job pair

```ruby
# app/models/project/notifying.rb
module Project::Notifying
  extend ActiveSupport::Concern

  included do
    after_create_commit :notify_watchers_later
  end

  def notify_watchers_later
    Project::NotifyWatchersJob.perform_later(self)
  end

  def notify_watchers_now
    watchers.each { |user| ProjectMailer.created(self, user).deliver_later }
  end
end

# app/jobs/project/notify_watchers_job.rb
class Project::NotifyWatchersJob < ApplicationJob
  def perform(project)
    project.notify_watchers_now
  end
end
```

## 4. A model test for the concern

```ruby
# test/models/project/archivable_test.rb
require "test_helper"

class Project::ArchivableTest < ActiveSupport::TestCase
  setup do
    Current.user = users(:paul)
  end

  test "archive records who archived it" do
    project = projects(:website)

    assert_difference -> { Project::Archival.count }, +1 do
      project.archive
    end

    assert project.archived?
    assert_equal users(:paul), project.archived_by
  end

  test "archive is idempotent" do
    project = projects(:website)
    project.archive

    assert_no_difference -> { Project::Archival.count } do
      project.archive
    end
  end

  test "scopes" do
    projects(:website).archive

    assert_includes Project.archived, projects(:website)
    assert_not_includes Project.active, projects(:website)
  end
end
```
