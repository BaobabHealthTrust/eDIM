class DispensationController < ApplicationController
  def refill

    @patient = Patient.find(params[:patient_id])

    GeneralInventory.transaction do
      item = GeneralInventory.where("gn_identifier = ? ", params[:bottle_id]).lock(true).first
      item.current_quantity = item.current_quantity.to_i - params[:quantity].to_i
      item.save

      if item.errors.blank?
        @new_prescription = Prescription.new
        @new_prescription.patient_id = @patient.id
        @new_prescription.drug_id = item.drug_id
        @new_prescription.directions = Misc.create_directions(params[:dose], params[:administration],params[:frequency],params[:doseType])
        @new_prescription.quantity = params[:quantity]
        @new_prescription.amount_dispensed = params[:quantity]
        @new_prescription.provider_id = User.current.id
        @new_prescription.date_prescribed = Time.current
        @new_prescription.save

        @dispensation = Dispensation.create({:rx_id => @new_prescription.id, :inventory_id => item.bottle_id,
                                             :patient_id => @new_prescription.patient_id, :quantity => @new_prescription.amount_dispensed,
                                             :dispensation_date => Time.current, :dispensed_by => User.current.id})

        if @dispensation.errors.blank?
          print_and_redirect("/print_dispensation_label/#{@new_prescription.id}", "/patient/#{@patient.id}") and return
        end
      else
        flash[:errors] = "Insufficient stock on hand"
      end
    end
    redirect_to "/patient/#{@patient.id}" and return
  end

  def print_dispensation_label
    #This function prints bottle barcode labels for both inventory types

    @prescription = Prescription.find(params[:id])
    date = l(@prescription.date_prescribed, format: '%d %B %Y')
    print_string = Misc.create_dispensation_label(@prescription.drug_name,@prescription.amount_dispensed,
                                              @prescription.directions, @prescription.patient_name, date)

    send_data(print_string,:type=>"application/label; charset=utf-8", :stream=> false, :filename=>"#{('a'..'z').to_a.shuffle[0,8].join}.lbl", :disposition => "inline")
  end

  def destroy
    #Delete an dispensation
    dispensation = Dispensation.void(params[:id])

    if dispensation.voided
      flash[:success] = "Dispensation successfully voided"
    else
      flash[:errors] = "Failed to void the dispensation"
    end

    redirect_to dispensation.patient
  end

  private

  def dispense_item(inventory,prescription,dispense_amount)

    Dispensation.transaction do

      inventory.current_quantity -= dispense_amount.to_i

      if inventory.save

        prescription.amount_dispensed += dispense_amount.to_i
        prescription.save

        dispensation = Dispensation.create({:rx_id => prescription.id, :inventory_id => inventory.bottle_id,
                                            :patient_id => prescription.patient_id, :quantity => dispense_amount,
                                            :dispensation_date => Time.now})

        logger.info "#{current_user.username} dispensed #{dispense_amount} of #{inventory.bottle_id} (RX:#{prescription.id})"
      else
        return false
      end
    end
  end
end
