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
      task_was_updated
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

  def task_was_updated
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
  end
end
