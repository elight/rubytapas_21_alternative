# OLD CODE

class TasksController < ApplicationController
  # ...
  def update
    old_project_id = @task.project && @task.project.id

    previous_status = @task.status
    if @task.update_attributes(params[:task])
      if previous_status != @task.status
        notifiee = task.readers(false) - [current_user]
        if notifiee
          mail_completion_notice(notifiee) if new_status == Status::COMPLETED
          mail_uncomplete_notice(notifiee) if previous_status == Status::COMPLETED
        end
      end
      if old_project_id != (@task.project && @task.project.id)
        push_project_update(old_project_id)
        push_project_update(@task.project.id) if @task.project
      end
      if @task.project
        push_task('update_task')
      else
        push_task('create_task', assignee) if assignee
        push_task('delete_task', previous_assignee) if previous_assignee
        update_users = @task.readers
        update_users = update_users - [assignee] if assignee
        push_task('update_task', update_users)
      end

      mail_assignment if assignee
      mail_assignment_removal(previous_assignee) if previous_assignee

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
  # ...
end


# NEW CODE
class TasksController < ApplicationController
  def update
    old_project_id = @task.project && @task.project.id

    previous_status = @task.status
    if @task.update_attributes(params[:task])
      push_task_updates
      respond_to do |format|
        format.json {render 'show', status: :accepted}
      end
    else
      respond_with @task do |format|
        format.json {render @task.errors.messages, status: :unprocessable_entity}
      end
    end
  end

  protected

  def push_task_updates
    if task_status_changed?
      if notifiee
        mail_completion_notice(notifiee) if task_newly_completed?
        mail_uncomplete_notice(notifiee) if task_previously_completed?
      end
    end
    if old_project_id != (@task.project && @task.project.id)
      push_project_update(old_project_id)
      push_project_update(@task.project.id) if @task.project
    end
    if @task.project
      push_task('update_task')
    else
      push_task('create_task', assignee) if assignee
      push_task('delete_task', previous_assignee) if previous_assignee
      update_users = @task.readers
      update_users = update_users - [assignee] if assignee
      push_task('update_task', update_users)
    end

    mail_assignment if assignee
    mail_assignment_removal(previous_assignee) if previous_assignee

    #respond_with defaults to a blank response, we need the object sent back so that the id can be read
  end

  def task_status_changed?
    # Can't see where previous_status is defined. Only assuming for now it's available locally
    previous_status != @task.status
  end

  def task_newly_completed?
    # Can't see where new_status is defined. Only assuming for now it's available locally
    new_status == Status::COMPLETED
  end

  def task_previously_completed?
    # Can't see where previous_status is defined. Only assuming for now it's available locally
    previous_status == Status::COMPLETED
  end

  def notifiee
    @notifiee ||= task.readers(false) - [current_user]
  end
end
