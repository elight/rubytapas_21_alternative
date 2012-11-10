class ClientProxy
  attr_reader :task, :old_project_id

  # Virtus could be handy to constrain what instance variables can be set
  def initialize(params = {})
    params.each do |k, v|
      instance_variable_set(k, v)
    end

    if task
      @old_project_id = task.project && task.project.id
    end
  end

  def push_task_updates
    push_task_project_updates

    if @task.project
      # I'm unclear why the present of @task.project implies Task was updated.
      # This seems to imply that a newly minted task does not already have a Project...
      push_task('update_task')
    else
      push_task('create_task', assignee) if assignee
      push_task('delete_task', previous_assignee) if previous_assignee
      push_task('update_task', update_users)
    end
  end

  private

  def push_task_project_updates
    return unless task_project_id_changed?

    push_project_update(old_project_id)
    push_project_update(task.project.id) if task.project
  end

  def push_task
    # definition would occur here
  end

  def task_project_id_changed?
    old_project_id != (task.project && task.project.id)
  end
end

class EmailNotifier
  attr_reader :task, :previous_task_status

  # Virtus could be handy to constrain what instance variables can be set
  def initialize(params = {})
    params.each do |k, v|
      instance_variable_set(k, v)
    end
  end

  def send_task_updates
    send_task_changes
    send_task_assignment_changes
  end

  private

  def send_task_changes
    if task_status_changed? && notifiee
      mail_completion_notice(notifiee) if task_newly_completed?
      mail_uncomplete_notice(notifiee) if task_previously_completed?
    end
  end

  def send_task_assignment_changes
    mail_assignment if assignee
    mail_assignment_removal(previous_assignee) if previous_assignee
  end

  def task_status_changed?
    previous_task_status != task.status
  end

  def task_newly_completed?
    task.status == Status::COMPLETED
  end

  def task_previously_completed?
    previous_task_status == Status::COMPLETED
  end

  def notifiee
    @notifiee ||= task.readers(false) - [current_user]
  end

  def update_users
    task.readers - [assignee] if assignee
  end
end

class TasksController < ApplicationController
  def update
    previous_task_status = @task.status

    if @task.update_attributes(params[:task])
      ClientProxy.new(:task => @task).push_task_updates
      EmailNotifier.new(
        :task => @task,
        :previous_task_status => previous_task_status
      ).send_task_updates

      #respond_with defaults to a blank response, we need the object sent back so that the id can be read
      respond_to do |format|
        format.json {render 'show', status: :accepted}
      end
    else
      respond_with @task do |format|
        format.json {render @task.errors.messages, status: :unprocessable_entity}
      end
    end
  end
end
