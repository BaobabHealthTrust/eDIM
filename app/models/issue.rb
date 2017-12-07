class Issue < ActiveRecord::Base
  belongs_to :general_inventory, :foreign_key => :inventory_id
  has_one :location, foreign_key: :location_id
  has_one :user, foreign_key: :issued_by

  def drug_name
    #this method handles the need to access the drug name associated to the dispensation
    self.general_inventory.drug_name
  end

  def dispensation_location
    self.location.name
  end

  def self.void(id)
    dispensation = Issue.find(id)
    Issue.transaction do

      item = GeneralInventory.where("gn_identifier = ? AND voided = ?", dispensation.inventory_id, false).first

      if item.blank?
        return dispensation
      else
        prescription = dispensation.prescription

        item.current_quantity += dispensation.quantity
        item.save

        dispensation.voided = true
        dispensation.save

        prescription.amount_dispensed -= dispensation.quantity
        prescription.save
      end
    end
    return dispensation
  end

end
