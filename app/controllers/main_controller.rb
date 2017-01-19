class MainController < ApplicationController
  def index
  end

  def settings
  end

  def select_report
    render :layout => "touch"
  end

  def report
    case params[:report_duration]
      when "daily"
        @report_type = "Daily Inventory and Dispensation Report for #{params[:start_date].to_date.strftime('%d %B, %Y')}"
        start_date = params[:start_date].to_date.strftime('%Y-%m-%d 00:00:00')
        end_date = params[:start_date].to_date.strftime('%Y-%m-%d 23:59:59')

      when "weekly"
        @report_type = "Weekly Inventory and Dispensation Report from #{params[:start_date].to_date.beginning_of_week.strftime('%d %B, %Y')}
                        to #{params[:start_date].to_date.end_of_week.strftime('%d %B, %Y')}"

        start_date = params[:start_date].to_date.beginning_of_week.strftime('%Y-%m-%d 00:00:00')
        end_date = params[:start_date].to_date.end_of_week.strftime('%Y-%m-%d 23:59:59')

      when "monthly"
        @report_type = "Monthly Inventory and Dispensation Report for #{params[:start_date].to_date.strftime('%B %Y')}"
        start_date = params[:start_date].to_date.beginning_of_month.strftime('%Y-%m-%d 00:00:00')
        end_date = params[:start_date].to_date.end_of_month.strftime('%Y-%m-%d 23:59:59')
      when "range"
        @report_type = "Inventory and Dispensation report from #{params[:start_date].to_date.strftime('%d %B, %Y')}
                        to #{params[:end_date].to_date.strftime('%d %B, %Y')}"
        start_date = params[:start_date].to_date.strftime('%Y-%m-%d 00:00:00')
        end_date = params[:end_date].to_date.strftime('%Y-%m-%d 23:59:59')
    end

    dispensations = Dispensation.find_by_sql("SELECT sum(d.quantity) as quantity,g.drug_id FROM `dispensations` d left
                                              outer join general_inventories g on d.inventory_id = g.gn_identifier
                                              where d.voided = 0 and g.drug_id is not null and dispensation_date BETWEEN
                                              '#{start_date}' and '#{end_date}' GROUP BY g.drug_id")

    inventory = GeneralInventory.select("SUM(current_quantity) as current_quantity, drug_id").where("voided = ? and
                                         date_received <= ?", false, end_date.to_date.strftime("%Y-%m-%d")).group("drug_id")


    later_dispensations = Dispensation.find_by_sql("SELECT sum(d.quantity) as quantity,g.drug_id FROM `dispensations` d left
                                              outer join general_inventories g on d.inventory_id = g.gn_identifier
                                              where d.voided = 0 and g.drug_id is not null and dispensation_date > '#{end_date}'
                                              and g.date_received <= '#{end_date.to_date.strftime("%Y-%m-%d")}'
                                              GROUP BY g.drug_id")

    @items = view_context.compile_report(dispensations,inventory,later_dispensations)

  end
end
