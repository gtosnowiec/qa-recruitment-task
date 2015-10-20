module Api
  class UsersController < ApplicationController
    before_action :restrict_current_user,
                  except: [:index, :users_without_birthday, :update_me, :me]

    def index
      render json: UsersRepresenter.new(User.sooners).basic
    end

    def send_emails
      User.where.not(id: params[:user_id]).each do |user|
        NotifyAboutGiftsWorker.perform_async(
          user.id,
          params[:user_id],
          params[:subject],
          params[:content],
        )
      end
      head :ok
    end

    def users_without_birthday
      users = User.without_birthday

      render json: UsersRepresenter.new(users).without_birthday
    end

    def show
      render json: OneUserRepresenter.new(User.find(params[:id])).to_json
    end

    def update
      user = User.find(params[:id])
      if user.update(user_params)
        render json: OneUserRepresenter.new(user).to_json
      else
        render json: { errors: user.errors.messages }, status: 422
      end
    end

    def update_me
      if current_user.update(user_params)
        render json: CurrentUserRepresenter.new(current_user).basic
      else
        render json: { errors: current_user.errors.messages }, status: 422
      end
    end

    def me
      render json: CurrentUserRepresenter.new(current_user).basic
    end

    private

    def restrict_current_user
      head :unauthorized if current_user.id.to_s == params[:id]
    end

    def user_params
      params.require(:user).permit(:birthday_day, :birthday_month, :szama, :about)
    end
  end
end
