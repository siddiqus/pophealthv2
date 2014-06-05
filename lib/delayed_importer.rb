class DelayedImporter
  attr_accessor :file, :current_user

  def initialize(options)
    @file = options['file']
    @current_user = options['user']
    @practice = options['practice'] 	
  end

  def before
    Log.create(:username => @current_user.username, :event => 'bulk record import')
  end

  def after
    File.delete(@file)
  end

	def perform
		upload_patients(@file, @practice)
	end

	def upload_patients(file, practice)
		error_files = File.open("error_files.txt",'a')
		up_log = File.open("upload_errors.txt", 'a')
	
	  Zip::ZipFile.open(file) do |zipfile|
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
		
		missing_info = File.open("missing_provider_info.txt", 'a')
		empty_providers = []
				
		Provider.where(:npi => nil).each do |prov|
			empty_providers.push("#{prov.given_name} " + "#{prov.family_name}")
		end
		
		unique = empty_providers.uniq.sort # * "\n"
		$missing_info_text = unique
		missing_info.write(unique * "\n")
				
		Provider.where(:npi => nil).delete
  end
  
end
