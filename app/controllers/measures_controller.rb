require 'ostruct'
class MeasuresController < ApplicationController
  include MeasuresHelper

  before_filter :authenticate_user!
  before_filter :validate_authorization!
  before_filter :filter_order
  after_filter :hash_document, :only => :measure_report
  
  # fixed by ssiddiqui. order important to establish selected_provider first
  def filter_order
  	setup_filters
  	set_up_environment 
  end

  add_breadcrumb_dynamic([:definition, :selected_provider], only: %w{show patients})  do |data| 
    measure = data[:definition]; provider = data[:selected_provider]
    {title: "#{measure['endorser']}" + "NQF#" + "#{measure['nqf_id']}" + (measure['sub_id'] ? "#{measure['sub_id']}" : ''), 
     url: "#{Rails.configuration.relative_url_root}/measure/#{measure['id']}"+(measure['sub_id'] ? "/#{measure['sub_id']}" : '')+(provider ? "?npi=#{provider.npi}" : "/providers")}
  end
  add_breadcrumb 'Parameters', '', only: %w{show}
  add_breadcrumb 'Patients', '', only: %w{patients}
  
  def index
    @categories = HealthDataStandards::CQM::Measure.categories    
    @last_upload_date = Log.where(:event => 'patient record imported').last.created_at.in_time_zone('Eastern Time (US & Canada)').ctime if (Log.where(:event => 'patient record imported').count() > 0)
  end

	def measure_table 
	end
	
  def show
    respond_to do |wants|
      wants.html do
        build_filters if (@selected_provider)
        generate_report
        @result = @quality_report.result
      end
      wants.json do
        measures = params[:sub_id] ? QME::QualityMeasure.get(params[:id], params[:sub_id]) : QME::QualityMeasure.sub_measures(params[:id])
        
        render_measure_response(measures, params[:jobs]) do |sub|
          {
            report: QME::QualityReport.new(sub['id'], sub['sub_id'], 'effective_date' => @effective_date, 'filters' => @filters, 'oid_dictionary' => @oid_dictionary),
            patient_count: @patient_count
          }
        end
      end
    end
  end
      
  def definition
    render :json => @definition
  end
  
  def result
    uuid = generate_report(params[:uuid])
    if (@result)
      render :json => @result
    else
      render :json => @quality_report.status(uuid)
    end  
  end  
  
  def providers    
    authorize! :manage, :providers
    
    respond_to do |wants|
      wants.html {}
      wants.js do    
      #  @providers = Provider.page(params[:page]).per(20).userfilter(current_user).alphabetical
       	@providers = Provider.user_filter(current_user) # added by ssiddiqui
        @providers = @providers.any_in(team_id: params[:team]) if params[:team]      	 
      end
      
      wants.json do
        providerIds = params[:provider].blank? ?  Provider.all.map { |pv| pv.id.to_s } : @filters.delete('providers')
        render_measure_response(providerIds, params[:jobs]) do |pvId|
          filters = @filters ? @filters.merge('providers' => [pvId]) : {'providers' => [pvId]}
          { 
            report: QME::QualityReport.new(params[:id], params[:sub_id], 'effective_date' => @effective_date, 'filters' => filters),
            patient_count: @patient_count
          }
        end
      end
    end
  end
  
  def remove
    SelectedMeasure.remove_measure(current_user.username, params[:id])
    render :text => 'Removed'
  end
  
	# ADDED FOR CLEAR SELECTION BUTTON - ssiddiqui
	def remove_selections
    SelectedMeasure.remove_all(current_user.username)
    redirect_to(:back)
  end

  def select
    SelectedMeasure.add_measure(current_user.username, params[:id])
    render :text => 'Select'
  end
  
  def patients
    build_filters if (@selected_provider)
    generate_report
  end

	def export_patients
		type = params['type']
		
		book = Spreadsheet::Workbook.new
		sheet = book.create_worksheet
		format = Spreadsheet::Format.new :weight => :bold
		today = Time.now.strftime("%D")
	
		# table headers
		sheet.row(0).push 'MRN', 'First Name', 'Last Name', 'Gender', 'Birthdate'
		sheet.row(0).default_format = format
		r=1;
		
		# measure info
		value_type = "value." + "#{type}";
		query = { 'value.measure_id' => params[:measure_id], 'value.sub_id' => params[:sub_id], 'value.effective_date' => @effective_date, "#{value_type}" => 1} 				
		cache = PatientCache.where( query )
		practice = @current_user.practice	;		
		selected_provider = Provider.where(:npi => params[:npi] ).first
		
		if @current_user.admin? && !(selected_provider) 
			cache.each do |pc|
				sheet.row(r).push pc.value['medical_record_id'], pc.value['first'], pc.value['last'], pc.value['gender'], Time.at(pc.value['birthdate']).strftime("%D") 
				r = r+1;
			end	
		elsif @current_user.staff_role? && (selected_provider) # if staff
			cache.each do |pc|
				pc_record = Record.where( :medical_record_number => pc.value['medical_record_id'] ).first
				pc_practice = pc_record.practice == practice
				pc_performer = (pc_record.provider_performances.any? {|perf| perf.provider_id == selected_provider._id});						
								
				if pc_practice && pc_performer 
					sheet.row(r).push pc.value['medical_record_id'], pc.value['first'], pc.value['last'], pc.value['gender'], Time.at(pc.value['birthdate']).strftime("%D")
					r = r+1;
				end
			end		
		elsif @current_user.staff_role? && !(selected_provider) # if staff
			cache.each do |pc|
				pc_record = Record.where( :medical_record_number => pc.value['medical_record_id'] ).first
				pc_practice = pc_record.practice == practice												
				if pc_practice 
					sheet.row(r).push pc.value['medical_record_id'], pc.value['first'], pc.value['last'], pc.value['gender'], Time.at(pc.value['birthdate']).strftime("%D")
					r = r+1;
				end
			end
		elsif @current_user.provider? || selected_provider
			cache.each do |pc|
				npi = (selected_provider)? selected_provider.npi : @current_user.npi
			  prov = Provider.where(:npi => npi).first
			  if pc.value['provider_performances'].any?{ |perf| perf['provider_id'] == prov._id }
			  	sheet.row(r).push pc.value['medical_record_id'], pc.value['first'], pc.value['last'], pc.value['gender'], Time.at(pc.value['birthdate']).strftime("%D")
					r = r+1;
			  end
			end
		end
		
		# if admin, then do all of them. else practice wise
		filename = "patients_" + "#{type}" + "_" + "#{today}" + ".xls"
		
		data = StringIO.new '';
		book.write data;
		send_data(data.string, {
		  :disposition => 'attachment',
		  :encoding => 'utf8',
		  :stream => false,
		  :type => 'application/excel',
		  :filename => filename
		})
		
#		redirect_to measures_patients_path( @definition => params['definition'])
	end


	# creates spreadsheet of dashboard reports
 	def export_report
  	book = Spreadsheet::Workbook.new
		sheet = book.create_worksheet
		
		format = Spreadsheet::Format.new :weight => :bold
		
		selected_measures = @current_user.selected_measures
		
		start_date = Time.at(@period_start).strftime("%D")
    end_date = Time.at(@effective_date).strftime("%D")
    
		# table headers
		sheet.row(0).push 'NQF ID', 'Sub ID', 'Name', 'Subtitle', 'Numerator', 'Denominator', 'Exclusions', 'Percentage', 'Aggregate'
		sheet.row(0).default_format = format
		r = 1
		
		selected_provider = @selected_provider || Provider.where(:npi => params[:npi]).first
		providers_for_filter = (selected_provider)? selected_provider._id.to_s : @providers.map{|pv| pv._id.to_s}
		
		# populate rows
		selected_measures.each do |measure|
			subs_iterator(measure['subs']) do |sub_id|
				info = measure_info(measure['id'], sub_id)

				if selected_provider != nil
					query = {:measure_id => measure['id'], :sub_id => sub_id, :effective_date => @effective_date, 'filters.providers' => [selected_provider._id.to_s] }
				else
					query = {:measure_id => measure['id'], :sub_id => sub_id, :effective_date => @effective_date, 'filters.providers' => {'$all' => providers_for_filter}, 'filters.providers' => {'$size' => providers_for_filter.count} }
				end
				
				cache = MONGO_DB['query_cache'].find(query).first
				percent =  percentage(cache['NUMER'].to_f, cache['DENOM'].to_f)
				full_percent = percentage(cache['full_numer'].to_f, cache['full_denom'].to_f)
				sheet.row(r).push info[:nqf_id], sub_id, info[:name], info[:subtitle], cache['NUMER'], cache['DENOM'], cache['DENEX'] , percent, full_percent 
				r = r + 1;
			end
		end
	
		today = Time.now.strftime("%D")
		if @selected_provider
			filename = "measure-report-" + "#{@selected_provider.npi}-" + "#{today}" + ".xls"	
		else	
			filename = "measure-report-" + "#{today}" + ".xls"
		end
		data = StringIO.new '';
		book.write data;
		send_data(data.string, {
		  :disposition => 'attachment',
		  :encoding => 'utf8',
		  :stream => false,
		  :type => 'application/excel',
		  :filename => filename
		})
  end 
  
  def provider_report
    book = Spreadsheet::Workbook.new
		sheet = book.create_worksheet
		measure_id = params[:measure_id]
		sub_id = params[:sub_id]
		format = Spreadsheet::Format.new :weight => :bold
		    
		# table headers
		sheet.row(0).push 'First Name', 'Last Name', 'Numerator', 'Denominator', 'Exclusions', 'Percentage'
		sheet.row(0).default_format = format
		r = 1
		
		provider_list = Provider.user_filter(@current_user).map {|pv| pv._id}
		
		provider_list.each do |prov|
		  provider = Provider.where(:_id => prov).first	  
  		cache = MONGO_DB['query_cache'].find(
  		  :measure_id => measure_id, 
  		  :sub_id => sub_id, 
  		  :effective_date => @effective_date, 
  		  'filters.providers' => [prov.to_s]).first
  		if (cache['NUMER'] != nil)
  		  percent =  percentage(cache['NUMER'].to_f, cache['DENOM'].to_f)
  		  sheet.row(r).push provider.family_name, provider.given_name, cache['NUMER'], cache['DENOM'], cache['DENEX'] , percent
				r = r + 1;
  		end
  	end
		nqf = measure_info(measure_id, sub_id)[:nqf_id]	
		today = Time.now.strftime("%D")
		filename = "provider-report-" + "NQF" + "#{nqf}" + "-" + "#{today}" + ".xls"
		
		data = StringIO.new '';
		book.write data;
		send_data(data.string, {
		  :disposition => 'attachment',
		  :encoding => 'utf8',
		  :stream => false,
		  :type => 'application/excel',
		  :filename => filename
		})
  end
  
  # returns info on measure
  def measure_info(id, sub_id)
		measure = MONGO_DB['measures'].find(:id => id, :sub_id => sub_id).first
		{:name => measure['name'], :subtitle => measure['short_subtitle'], :nqf_id => measure['nqf_id']}	
	end
	
		# returns percentage
	def percentage(numer,denom)	
		percent = (numer/denom * 100).round(1)
		(denom==0)? 0 : percent
	end

  # This is used to populate the patient list for a selected measure
  def measure_patients

    @type = params[:type] || 'DENOM'
    @limit = (params[:limit] || 20).to_i
    @skip = ((params[:page] || 1).to_i - 1 ) * @limit
    sort = params[:sort] || "_id"
    sort_order = params[:sort_order] || :asc
    measure_id = params[:id] 
    sub_id = params[:sub_id]
    
    query = {'value.measure_id' => measure_id, 'value.sub_id' => sub_id, 'value.effective_date' => @effective_date}
    
    if (@type == 'exclusions')
      query.merge!({'$or'=>[{"value.#{@type}" => 1}, {'value.manual_exclusion'=>true}]})
    else
      query.merge!({"value.#{@type}" => 1, 'value.manual_exclusion'=>{'$ne'=>true}})
    end
    
    if (@selected_provider)
      result = PatientCache.by_provider(@selected_provider, @effective_date).where(query);
    else
      authorize! :manage, :providers
      # added from bstrezze
      result = PatientCache.provider_in(Provider.generate_user_provider_ids(current_user)).where(query)
    end
    @total = result.count
    @records = result.order_by(["value.#{sort}", sort_order]).skip(@skip).limit(@limit);
    
    @manual_exclusions = {}
    ManualExclusion.selected(@records.map {|record| record['value']['medical_record_id']}).map {|exclusion| @manual_exclusions[exclusion.medical_record_id] = exclusion} if (@type == 'exclusions')
    
    @page_results = WillPaginate::Collection.create((params[:page] || 1), @limit, @total) do |pager|
       pager.replace(@records)
    end
    # log the medical_record_number of each of the patients that this user has viewed
    @page_results.each do |patient_container|
      Log.create(:username =>   current_user.username,
                 :event =>      'patient record viewed',
                 :medical_record_number => (patient_container['value'])['medical_record_id'])
    end
  end


  # excel patient list
  def patient_list
    measure_id = params[:id] 
    sub_id = params[:sub_id]
    
    query = {'value.measure_id' => measure_id, 'value.sub_id' => sub_id, 'value.effective_date' => @effective_date, 'value.population'=>true}

    if (@selected_provider)
      result = PatientCache.by_provider(@selected_provider, @effective_date).where(query);
    else
      authorize! :manage, :providers
			# added from bstrezze
      result = PatientCache.provider_in(Provider.generate_user_provider_ids(current_user)).where(query)
    end
    @records = result.order_by(["value.medical_record_id", 'desc']);
    
    @manual_exclusions = {}
    ManualExclusion.selected(@records.map {|record| record['value']['medical_record_id']}).map {|exclusion| @manual_exclusions[exclusion.medical_record_id] = exclusion}
    
    # log the medical_record_number of each of the patients that this user has viewed
    @records.each do |patient_container|
      Log.create(:username =>   current_user.username,
                 :event =>      'patient record viewed',
                 :medical_record_number => (patient_container['value'])['medical_record_id'])
    end
    respond_to do |format|
      format.xml do
        headers['Content-Disposition'] = 'attachment; filename="excel-export.xls"'
        headers['Cache-Control'] = ''
        render :content_type => "application/vnd.ms-excel"
      end
    end
  end

  def measure_report
    Atna.log(current_user.username, :query)
    selected_measures = current_user.selected_measures
    
    @report = {}
    @report[:registry_name] = current_user.registry_name
    @report[:registry_id] = current_user.registry_id
    @report[:provider_reports] = []
    
    case params[:type]
    when 'practice'
      authorize! :manage, :providers
      @report[:provider_reports] << generate_xml_report(nil, selected_measures, false)
    when 'provider'
      providers = Provider.selected_or_all(params[:provider])
      providers.each do |provider|
        authorize! :read, provider
        @report[:provider_reports] << generate_xml_report(provider, selected_measures)
      end
      # add patients without a provider
      if ((can? :manage, :providers) && (providers.size > 1))
        @report[:provider_reports] << generate_xml_report(nil, selected_measures) 
      end
    end

    respond_to do |format|
      format.xml do
        response.headers['Content-Disposition']='attachment;filename=quality.xml';
        render :content_type=>'application/pqri+xml'
      end
    end
  end
   
  def period
    month, day, year = params[:effective_date].split('/')
    set_effective_date(Time.gm(year.to_i, month.to_i, day.to_i).to_i + 43200, params[:persist]=="true")
    render :period, :status=>200
  end

  private

  def generate_xml_report(provider, selected_measures, provider_report=true)
    report = {}
    report[:start] = Time.at(@period_start)
    report[:end] = Time.at(@effective_date)
    report[:npi] = provider ? provider.npi : '' 
    report[:tin] = provider ? provider.tin : ''
    report[:results] = []
    
    selected_measures.each do |measure|
      subs_iterator(measure['subs']) do |sub_id|
        report[:results] << extract_result(measure['id'], sub_id, @effective_date, ((provider_report) ? [provider ? provider.id.to_s : nil] : nil))
      end
    end
    report
  end

  def generate_xls(selected_measures)
    report = {}
    report[:start] = Time.at(@period_start)
    report[:end] = Time.at(@effective_date)
    report[:results] = []
    
    selected_measures.each do |measure|
      subs_iterator(measure['subs']) do |sub_id|
        report[:results] << extract_result(measure['id'], sub_id)
      end
    end
    report
  end
  
#  def extract_result(id, sub_id, effective_date, providers=nil)
#    if (providers)
#      qr = QME::QualityReport.new(id, sub_id, 'effective_date' => effective_date, 'filters' => {'providers' => providers})
#    else
#      qr = QME::QualityReport.new(id, sub_id, 'effective_date' => effective_date)
#    end
	def extract_result(id, sub_id)
		qr = QME::QualityReport.new(id, sub_id, 'effective_date' => @effective_date, 
		'filters.providers' => @providers.map {|pv| pv._id.to_s})
#    qr.calculate unless qr.calculated?
    result = qr.result
#    measure = measure_name(id, sub_id)
    {
      :nqf_id => result['measure_id'],
      :id => id,
      :sub_id => sub_id,
      :name => measure[:name],
      :subtitle => measure[:subtitle],
#      :population => result['population'],
      :denominator => result['DENOM'],
      :numerator => result['NUMER'],
      :exclusions => result['DENEX'],
      :full_numer => result['full_numer'],
      :full_denom => result['full_denom']
    }
  end
    
    
  def set_up_environment
    user_npi = Provider.valid_npi?(@current_user.npi)? @current_user.npi : nil
    provider_npi = params[:npi] || user_npi
		if @current_user.admin? && provider_npi
    	@patient_count = Provider.where(:npi => "#{provider_npi}").first.records(@effective_date).count   
    elsif @current_user.admin?		
			@patient_count = Record.all.count
    elsif @selected_provider
      @patient_count = @selected_provider.records(@effective_date).count
    elsif @current_user.staff_role?
			@patient_count = Record.where(practice: "#{current_user.practice}").count
    	# for teams
#      @patient_count = Record.provider_in(Provider.generate_user_provider_ids(current_user)).count
    end

    if params[:id]
      measure = QME::QualityMeasure.new(params[:id], params[:sub_id])
      render(:file => "#{RAILS_ROOT}/public/404.html", :layout => false, :status => 404) unless measure
      @definition = measure.definition
      @oid_dictionary = OidHelper.generate_oid_dictionary(@definition)
    end
  end
  
  def generate_report(uuid = nil)
    @quality_report = QME::QualityReport.new(@definition['id'], @definition['sub_id'], 'effective_date' => @effective_date, 'filters' => @filters)
    if @quality_report.calculated?
      @result = @quality_report.result
    else
      unless uuid
        uuid = @quality_report.calculate
      end
    end
    return uuid
  end
  
  def render_measure_response(collection, uuids)
    result = collection.inject({jobs: {}, result: []}) do |memo, var|
      data = yield(var)
      report = data[:report]
      patient_count = data[:patient_count]

      if report.calculated?
        memo[:result] << report.result.merge({'patient_count'=>patient_count})
      else
        measure_id = report.instance_variable_get(:@measure_id)
        sub_id = report.instance_variable_get(:@sub_id)
        key = "#{measure_id}#{sub_id}"
        uuid = (uuids.nil? || uuids[key].nil?) ? report.calculate : uuids[key]
        filters = report.instance_variable_get(:@parameter_values)['filters']        
				job = {uuid: uuid, status: report.status(uuid)['status'], measure_id: measure_id, sub_id: sub_id, filters: filters}

        memo[:jobs][key] = job
        memo[:result] << {job: job}
      end

      memo
    end

    render :json => result.merge(:complete => result[:jobs].empty?, :failed => !(result[:jobs].values.keep_if {|job| job[:status] == 'failed'}).empty?)
  end
  
  
  # setup the filters to show on the left panel
  def setup_filters
    
    if !can?(:read, :providers) || params[:npi]
      npi = params[:npi] ? params[:npi] : current_user.npi
      @selected_provider = Provider.where(:npi => "#{npi}").first 
      authorize! :read, @selected_provider
    end
    
    if request.xhr?     
      build_filters
    else
      if can?(:read, :providers)
				# updated from bstrezze
        #@providers = Provider.page(@page).per(20).userfilter(current_user).alphabetical
				@providers = Provider.user_filter(current_user)								
				@providers_for_filter = Provider.user_filter(current_user) #.alphabetical
        if APP_CONFIG['disable_provider_filters']
          @teams = Team.user_filter(current_user).alphabetical
          @page = params[:page]
        else				
					other = Team.new(name: "Other")
          @providers_by_team = @providers.group_by { |pv| pv.team || other }
          @providers_by_team[other] ||= []
					@providers_for_filter_by_team = @providers_for_filter.group_by { |pv| pv.team.try(:name) || "Other" }
        end
      end

      @races = Race.ordered
      @ethnicities = Ethnicity.ordered
      @genders = [{name: 'Male', id: 'M'}, {name: 'Female', id: 'F'}].map { |g| OpenStruct.new(g)}
      @languages = Language.ordered          
    end			
  end
	
  def build_filters
    providers = nil
    
    if params[:provider]
      providers = params[:provider]
#    elsif params[:team] && params[:team].size != Team.count
#      providers = Provider.any_in(team_id: params[:team]).map { |pv| pv.id.to_s }   
		# provisional   
   	else
      # Changed to, with setting the filters, to filter based on the user
      # providers = nil
      providers = Provider.user_filter(current_user).map { |pv| pv.id.to_s } # added from bstrezze
    end

    races = params[:race] ? Race.selected(params[:race]).all : nil
    ethnicities = params[:ethnicity] ? Ethnicity.selected(params[:ethnicity]).all : nil
    languages = params[:language] ? Language.selected(params[:language]).all : nil
    genders = params[:gender] ? params[:gender] : nil
    
    @filters = {}
    @filters.merge!({'providers' => providers}) if providers
    @filters.merge!({'races'=>(races.map {|race| race.codes}).flatten}) if races
    @filters.merge!({'ethnicities'=>(ethnicities.map {|ethnicity| ethnicity.codes}).flatten}) if ethnicities
    @filters.merge!({'languages'=>(languages.map {|language| language.codes}).flatten}) if languages
    @filters.merge!({'genders' => genders}) if genders

    if @selected_provider
      @filters['providers'] = [@selected_provider.id.to_s]
    else
      authorize!(:read, :providers)
    end
    
    @filters = nil if @filters.empty?
       
  end

  def validate_authorization!
    authorize! :read, HealthDataStandards::CQM::Measure #Measure
  end
  
end
