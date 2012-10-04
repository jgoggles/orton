class PickCenterController < ApplicationController
  def show
    @year = Year.find_by_name(params[:year_name])
    @week = Week.where("name = ? and year_id = ?", params[:week_name], @year.id).first

  end
end
