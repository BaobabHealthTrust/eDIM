class PatientIdentifiersController < ApplicationController
  def show
    @patient = PatientIdentifier.find_by_identifier(params[:id]).patient rescue nil
    if @patient.blank?
      flash[:errors] = "Patient with ID #{params[:id]} not found" if @patient.blank?
      redirect_to root_path
    else
      redirect_to @patient
    end

  end
end
