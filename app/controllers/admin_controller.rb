require 'record_importer'
include Mongoid

class AdminController < ApplicationController

  before_filter :authenticate_user!
  before_filter :validate_authorization!
  add_breadcrumb 'Admin', :admin_users_path

  def patients
    @patient_count = Record.all.count
    @query_cache_count = QueryCache.all.count
    @patient_cache_count = PatientCache.all.count
  	@provider_count = Provider.all.count
  	time = Log.where(:event => 'patient record imported').count()
  	@last_upload_date = Log.where(:event => 'patient record imported').last.created_at.in_time_zone('Eastern Time (US & Canada)').ctime if time > 0
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
				      QME::QualityReport.update_patient_results(@record.medical_record_number)
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
		# the following gets rid of empty providers 
		provs=[]
		Provider.where(:npi => nil).each do |prov|
			provs << prov._id
		end				
		Record.all.each do |rec|
			rec.provider_performances.any_in('provider_id' => provs).delete
		end						
		Provider.where(:npi => nil).delete
			
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
