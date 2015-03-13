require 'record_importer'
include Mongoid

class AdminController < ApplicationController

  before_filter :authenticate_user!
  before_filter :validate_authorization!
  add_breadcrumb 'Admin', :admin_users_path

  def patients
    @patient_count = Record.all.count
    @unassigned_patient_count = Record.where(provider_performances: nil).count + Record.where(provider_performances: []).count
    @query_cache_count = QueryCache.all.count
    @patient_cache_count = PatientCache.all.count
  	@provider_count = Provider.all.count
  	@practices = Practice.asc(:name).map {|p| p.name }

  	import_log = Log.where(:event => 'patient record imported')
  	med_id = import_log.last.medical_record_number unless import_log.count == 0
    @last_upload_date = import_log.count > 0 ? import_log.last.created_at.in_time_zone('Eastern Time (US & Canada)').ctime : nil
	  rec = (@patient_count == 0) ? 0 : Record.where(:medical_record_number => med_id).last
    @last_practice_upload = (rec != nil && rec != 0)? rec.practice : nil
  end
  def remove_patients
    Record.all.delete
    redirect_to action: 'patients'
  end
  def remove_caches
    QueryCache.all.delete
    PatientCache.all.delete
    MONGO_DB['delayed_backend_mongoid_jobs'].drop()
    redirect_to action: 'patients'
  end
  def remove_providers
    Provider.destroy_all
    redirect_to action: 'patients'
  end
	def delete_provider
  	Provider.where(:npi => params[:npi] ).first.delete
  	redirect_to providers_path
  end
	def user_profile
		@user = User.by_id(params[:id])
	end

	def patient_list
		@records = Record.all
	end

	def set_user_practice
		@user = User.by_id(params[:id])
		practice = params[:practice]
		@user.update_attribute(:practice, practice)		
		redirect_to :action => :user_profile, :id => @user.id
	end

	def remove_practice_patients
		Record.where( :practice => params[:practice] ).delete	
		redirect_to action: 'patients'
	end

	def remove_end_dates
		Record.all.each do |rec|
			rec.provider_performances.each do |prov|
				prov.end_date = nil
			end
			rec.save!
		end
		
		redirect_to :action => :patients
	end

  def upload_patients
		error_files = File.open("error_files.txt",'w')
		up_log = File.open("upload_errors.txt", 'w')
		$error_files = []
	
    file = params[:file]
    practice = params[:practice]
		$last_filename = file.original_filename
		
    if file!=nil && practice!=''
		  temp_file = Tempfile.new("patient_upload")
		
		  File.open(temp_file.path, "wb") { |f| f.write(file.read) }
		  
		  Zip::ZipFile.open(temp_file.path) do |zipfile|
		    zipfile.entries.each do |entry|
		      next if entry.directory?
		      xml = zipfile.read(entry.name)		      
					# if exists, import otherwise update
		      begin
		      	result = RecordImporter.import(xml, practice)		      
				    if (result[:status] == 'success') 
				      @record = result[:record]
#				      QME::QualityReport.update_patient_results(@record.medical_record_number)
				      Atna.log(current_user.username, :phi_import)
				      Log.create(:username => current_user.username, :event => 'patient record imported', :medical_record_number => @record.medical_record_number)
						end
		      rescue
		      	up_log.write( $! )
		      	up_log.write("\n")
		      	up_log.write ( $@ )
		      	error_files.write("error in file: " + "#{entry}" + "\n")
		      	$error_files << "#{entry}"
		      end    
		    end
		  end
		else
			flash[:notice] = "Please check file or Practice selection"
		end
		
		missing_info = File.open("missing_provider_info.txt", 'w')
		empty_providers = []
				
		Provider.where(:npi => nil).each do |prov|
			empty_providers.push("#{prov.given_name} " + "#{prov.family_name}")
		end
		
		unique = empty_providers.uniq.sort # * "\n"
		$missing_info_text = unique
		missing_info.write(unique * "\n")
	
		Provider.where(:npi => nil).delete
	
    # insert medication status code
    query = { '$or' => [{'conditions.codes.ICD-10-CM' => {'$in' => ["J45.30", "J45.31", "J45.32", "J45.40", "J45.41", "J45.42", "J45.50", "J45.51", "J45.52"]}},{'conditions.codes.ICD-9-CM' => {'$regex' => '493.*'}}]}
    Record.where(query).each do |rec|
      rec.medications.each do |med|
        if med.status_code == nil || med.status_code["HL7 ActStatus"] != ["dispensed"]
          med.status_code = {"HL7 ActStatus" => ["dispensed"]}
        end
      end
      rec.save
    end

  	redirect_to action: 'patients'
  end

  def users
    @users = User.all.ordered_by_username
  end

  def promote
    toggle_privilidges(params[:username], params[:role], :promote)
  end

  def demote
    toggle_privilidges(params[:username], params[:role], :demote)
  end

  def disable
    user = User.by_username(params[:username]);
    disabled = params[:disabled].to_i == 1
    if user
      user.update_attribute(:disabled, disabled)
      if (disabled)
        render :text => "<a href=\"#\" class=\"disable\" data-username=\"#{user.username}\">disabled</span>"
      else
        render :text => "<a href=\"#\" class=\"enable\" data-username=\"#{user.username}\">enabled</span>"
      end
    else
      render :text => "User not found"
    end
  end

  def approve
    user = User.where(:username => params[:username]).first
    if user
      user.update_attribute(:approved, true)
      render :text => "true"
    else
      render :text => "User not found"
    end
  end

  def update_npi
    user = User.by_username(params[:username]);
    user.update_attribute(:npi, params[:npi]);
    if Provider.valid_npi?(params[:npi]) 
    	user.update_attribute(:provider, true)
    end
    render :text => "true"
  end
  
  # added from bstrezze !--
  def edit_teams
    @user = User.by_id(params[:id])

    # Add item
    if (params[:add_team] && params[:add_team][:team_id])
      if (!@user.teams)
        @user.teams = Array.new
      end
      
    unless (params[:add_team][:team_id] == '')
		    if @user.teams.include?(Moped::BSON::ObjectId(params[:add_team][:team_id]))
		      flash[:notice] = 'Selected team has already been added.'
		    #  redirect_to :back, :notice => 'Selected team has already been added.'
			    redirect_to :back 
		    else
		      @user.teams << Moped::BSON::ObjectId(params[:add_team][:team_id])
		      @user.save
		      redirect_to :back
		    end
		  end
    end

    # Remove item
    if (params[:remove_team] && params[:remove_team][:team_id])
      @user.teams.delete_if {|item| item == Moped::BSON::ObjectId(params[:remove_team][:team_id]) }
      @user.save
    end
    
    
  end
  # --!  

  # added by ssiddiqui for button
  def delete_user
  	@user = User.by_id(params[:id])
  	if(User.count == 1)
			#render :text => "Cannot remove sole user. Please go back"
			redirect_to :back, notice: "Cannot remove sole user"
  	else
  		if(@user.admin?)
  			#render :text => "Cannot remove administrator. Please go back"
  			redirect_to :back, notice: "Cannot remove administrator"
  		else
  			@user.destroy
  			redirect_to(:back)
  		end
  	end  
  end

  private

  def toggle_privilidges(username, role, direction)
    user = User.by_username username

    if user
      if direction == :promote
        user.update_attribute(role, true)
        render :text => "Yes - <a href=\"#\" class=\"demote\" data-role=\"#{role}\" data-username=\"#{username}\">revoke</a>"
      else
        user.update_attribute(role, false)
        render :text => "No - <a href=\"#\" class=\"promote\" data-role=\"#{role}\" data-username=\"#{username}\">grant</a>"
      end
    else
      render :text => "User not found"
    end
  end
  
  def validate_authorization!
    authorize! :admin, :users
  end
end
