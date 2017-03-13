class GeneralInventoryController < ApplicationController

  def index
    @inventory = GeneralInventory.where("current_quantity > ? and voided = ?", 0, false)
  end

  def new
    render :layout => "touch"
  end

  def edit
    if request.post?
      # Edit a new record for general inventory
      @new_stock_entry = GeneralInventory.find_by_gn_identifier(params[:bottle_id])

      if @new_stock_entry.blank?
        flash[:errors] = "Item could not be found"
      else
        @new_stock_entry.expiration_date = params[:expiry_date].to_date rescue nil
        @new_stock_entry.received_quantity = params[:amount_received].to_i + (@new_stock_entry.received_quantity - @new_stock_entry.current_quantity)
        @new_stock_entry.current_quantity = params[:amount_received].to_i

        GeneralInventory.transaction do
          @new_stock_entry.save
        end

        if @new_stock_entry.errors.blank?
          flash[:success] = "#{@new_stock_entry.drug_name} (Bottle #: #{@new_stock_entry.gn_identifier}) was successfully updated."
        else
          flash[:errors] = @new_stock_entry.errors
        end
      end

      redirect_to "/" and return

    else
      @item = GeneralInventory.find(params[:id])
      render :layout => "touch"
    end
  end

  def create

    # Create a new record for general inventory
    @new_stock_entry = GeneralInventory.new
    @new_stock_entry.drug_id = Drug.find_by_name(params[:drug_name]).id rescue nil
    @new_stock_entry.current_quantity = params[:amount_received]
    @new_stock_entry.expiration_date = params[:expiry_date].to_date rescue nil
    @new_stock_entry.received_quantity = params[:amount_received]

    if @new_stock_entry.drug_id.blank?
      flash[:errors] = {} if flash[:errors].blank?
      flash[:errors][:missing] = ["Item #{params[:drug_name]} was not found"]
      redirect_to "/"
    else
      GeneralInventory.transaction do
        @new_stock_entry.save
      end

      if @new_stock_entry.errors.blank?
        #print barcode for new bottles
        flash[:success] = "#{params[:drug_name]} was successfully added to inventory."
        print_and_redirect("/print_bottle_barcode/#{@new_stock_entry.id}", "/")
      else
        flash[:errors] = @new_stock_entry.errors
        redirect_to "/"
      end
    end
  end

  def destroy
    #Delete an item from general inventory

    item = GeneralInventory.void_item(params[:id])
    if item.blank?
      flash[:errors] = {} if flash[:errors].blank?
      flash[:errors][:missing] = ["Item with bottle id #{params[:general_inventory][:gn_id]} could not be found"]
    elsif item.errors.blank?
      flash[:success] = "#{item.drug_name} #{item.gn_identifier} was successfully deleted."
=begin
      news = News.where("refers_to = ? AND resolved = ?",
                        params[:general_inventory][:gn_id], false).first
      unless news.blank?
        news.resolved = true
        news.resolution = "Item was voided"
        news.date_resolved= Date.today
        news.save
      end
=end
    else
      flash[:errors] = item.errors
    end

    redirect_to "/general_inventory"
  end

  def print_bottle_barcode
    #This function prints bottle barcode labels for both inventory types

    entry = GeneralInventory.find(params[:id])

    print_string = Misc.create_bottle_label(entry.drug_name,entry.gn_identifier,entry.expiration_date)
    chars = ("a".."z").to_a  + ("0".."9").to_a
    rand_str = ""
    1.upto(7) { |i| rand_str << chars[rand(chars.size-1)] }
    send_data(print_string,:type=>"application/label; charset=utf-8", :stream=> false, :filename=>"#{rand_str}.lbl", :disposition => "inline")
  end

end
