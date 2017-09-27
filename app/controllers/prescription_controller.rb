class PrescriptionController < ApplicationController
  def destroy
    # This function voids a prescription and marks it as deleted

    prescription = Prescription.find(params[:id])
    prescription.update_attributes(:voided => true)
    if prescription.errors.blank?
      news = News.where("refers_to = ? AND resolved = ?", params[:id], false).first
      unless news.blank?
        news.resolved = true
        news.resolution = "Rx was cancelled"
        news.date_resolved= Date.today
        news.save
        logger.info "Prescription #{params[:id]} was voided by #{current_user.username}"
      end
    end
    redirect_to "/prescription"
  end

end
