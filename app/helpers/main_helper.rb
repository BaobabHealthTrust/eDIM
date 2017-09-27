module MainHelper
  def compile_report(dispensations,inventory,late_disp)
    records = {}
    (inventory || []).each do |item|
      records[item.drug_id] = {"name" => Drug.find(item.drug_id).name, "available" => 0, "dispensed" => 0} if records[item.drug_id].blank?
      records[item.drug_id]["available"] += item.current_quantity
    end

    (dispensations || []).each do |item|
      records[item.drug_id] = {"name" => Drug.find(item.drug_id).name, "available" => 0, "dispensed" => 0} if records[item.drug_id].blank?
      records[item.drug_id]["dispensed"] += item.quantity
    end

    (late_disp || []).each do |item|
      records[item.drug_id] = {"name" => Drug.find(item.drug_id).name, "available" => 0, "dispensed" => 0} if records[item.drug_id].blank?
      records[item.drug_id]["available"] += item.quantity
    end

    return records
  end
end
