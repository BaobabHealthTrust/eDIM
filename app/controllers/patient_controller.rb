class PatientController < ApplicationController
  def show

    @patient = Patient.find(params[:id]) rescue nil

    if @patient.blank?
      flash[:errors] = "Patient with ID #{params[:id]} not found"
      redirect_to "/" and return
    else
      @history = Dispensation.where("patient_id = ? and voided = ?",@patient.id,false).order(dispensation_date: :desc).limit(10)

      if YAML.load_file("#{Rails.root}/config/application.yml")['has_prescribing']
        @prescriptions = Prescription.where("patient_id = ? and voided = ?",@patient.id,false).order(date_prescribed: :desc).limit(10)
      end
    end

  end

  def ajax_patient

    date = params[:patient][:date_of_birth].to_date.strftime("%Y") rescue nil

    if  params[:patient][:first_name].blank?
      if params[:patient][:last_name].blank?
        rawPatients = Patient.where("voided = ? AND (birthdate LIKE ?)",false,
                                    "%#{date}%").pluck(:first_name, :last_name, :gender,:birthdate,:state,
                                                       :city,:patient_id)
      elsif date.blank?
        rawPatients = Patient.where("voided = ? AND (last_name LIKE ?)", false,
                                    "%#{params[:patient][:last_name]}%").pluck(:first_name, :last_name, :gender,
                                                                               :birthdate,:state, :city,:patient_id)
      else

        rawPatients = Patient.where("voided = ? AND (last_name LIKE ? OR birthdate LIKE ?)", false,
                                    "%#{params[:patient][:last_name]}%","%#{date}%").pluck(:first_name, :last_name,
                                                                                           :gender,:birthdate,:state,
                                                                                           :city,:patient_id)
      end
    else
      if params[:patient][:last_name].blank? and date.blank?
        rawPatients = Patient.where("voided = ? AND first_name LIKE ? ",
                                    false, "%#{params[:patient][:first_name]}%").pluck(:first_name, :last_name, :gender,
                                                                                       :birthdate,:state,:city,:patient_id)
      elsif params[:patient][:last_name].blank? and !date.blank?
        rawPatients = Patient.where("voided = ? AND (first_name LIKE ? OR birthdate LIKE ?)",
                                    false, "%#{params[:patient][:first_name]}%",
                                    "%#{date}%").pluck(:first_name, :last_name, :gender,:birthdate,:state,
                                                       :city,:patient_id)
      elsif date.blank? and !params[:patient][:last_name].blank?
        rawPatients = Patient.where("voided = ? AND (first_name LIKE ? OR last_name LIKE ?)", false,
                                    "%#{params[:patient][:first_name]}%",
                                    "%#{params[:patient][:last_name]}%").pluck(:first_name, :last_name, :gender,
                                                                               :birthdate,:state,:city,:patient_id)
      else

        rawPatients = Patient.where("voided = ? AND (first_name LIKE ? OR last_name LIKE ? OR birthdate LIKE ?)",
                                    false, "%#{params[:patient][:first_name]}%","%#{params[:patient][:last_name]}%",
                                    "%#{date}%").pluck(:first_name, :last_name, :gender,:birthdate,:state,:city,:patient_id)

      end
    end
    @patients =  view_context.patients(rawPatients)

    render "index"
  end
end
