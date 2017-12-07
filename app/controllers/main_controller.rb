class MainController < ApplicationController
  def index
  end

  def settings
  end

  def select_report
    case params[:type]
      when 'prescription'
        @path = '/main/prescription_report'
      when 'dispensation'
        @path = '/main/dispensation_report'
    end
    render :layout => "touch"
  end

  def dispensation_report
    case params[:report_duration]
      when t('forms.options.daily')
        @report_type = "#{t('menu.terms.daily_report')} #{l(params[:start_date].to_date, format:'%d %B, %Y')}"
        start_date = params[:start_date].to_date.strftime('%Y-%m-%d 00:00:00')
        end_date = params[:start_date].to_date.strftime('%Y-%m-%d 23:59:59')

      when t('forms.options.weekly')
        @report_type = "#{t('menu.terms.weekly_report')} #{l(params[:start_date].to_date.beginning_of_week, format:'%d %B, %Y')}
                        #{t('menu.terms.to')} #{l(params[:start_date].to_date.end_of_week, format: '%d %B, %Y')}"

        start_date = params[:start_date].to_date.beginning_of_week.strftime('%Y-%m-%d 00:00:00')
        end_date = params[:start_date].to_date.end_of_week.strftime('%Y-%m-%d 23:59:59')

      when t('forms.options.monthly')
        @report_type = "#{t('menu.terms.monthly_report')} #{l(params[:start_date].to_date, format: '%B %Y')}"
        start_date = params[:start_date].to_date.beginning_of_month.strftime('%Y-%m-%d 00:00:00')
        end_date = params[:start_date].to_date.end_of_month.strftime('%Y-%m-%d 23:59:59')
      when t('forms.options.range')
        @report_type = "#{t('menu.terms.custom_report')} #{l(params[:start_date].to_date, format: '%d %B, %Y')}
                        #{t('menu.terms.to')} #{l(params[:end_date].to_date, format: '%d %B, %Y')}"
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


  def prescription_report
    case params[:report_duration]
      when t('forms.options.daily')
        @report_type = "#{t('menu.terms.daily_report')} #{l(params[:start_date].to_date, format:'%d %B, %Y')}"
        start_date = params[:start_date].to_date.strftime('%Y-%m-%d 00:00:00')
        end_date = params[:start_date].to_date.strftime('%Y-%m-%d 23:59:59')

      when t('forms.options.weekly')
        @report_type = "#{t('menu.terms.weekly_report')} #{l(params[:start_date].to_date.beginning_of_week, format:'%d %B, %Y')}
        #{t('menu.terms.to')} #{l(params[:start_date].to_date.end_of_week, format: '%d %B, %Y')}"

        start_date = params[:start_date].to_date.beginning_of_week.strftime('%Y-%m-%d 00:00:00')
        end_date = params[:start_date].to_date.end_of_week.strftime('%Y-%m-%d 23:59:59')

      when t('forms.options.monthly')
        @report_type = "#{t('menu.terms.monthly_report')} #{l(params[:start_date].to_date, format: '%B %Y')}"
        start_date = params[:start_date].to_date.beginning_of_month.strftime('%Y-%m-%d 00:00:00')
        end_date = params[:start_date].to_date.end_of_month.strftime('%Y-%m-%d 23:59:59')
      when t('forms.options.range')
        @report_type = "#{t('menu.terms.custom_report')} #{l(params[:start_date].to_date, format: '%d %B, %Y')}
        #{t('menu.terms.to')} #{l(params[:end_date].to_date, format: '%d %B, %Y')}"
        start_date = params[:start_date].to_date.strftime('%Y-%m-%d 00:00:00')
        end_date = params[:end_date].to_date.strftime('%Y-%m-%d 23:59:59')
    end

    @items = []

  end

  def time
    render :text => Time.current().strftime('%Y-%m-%d %H:%M').to_s
  end
end
