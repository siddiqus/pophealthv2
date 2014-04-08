class Record
  include Mongoid::Document
  
  # ===========================================================
  # = This record extends the record in health data standards =
  # ===========================================================
  
  field :measures, type: Hash
	field :practice, type: String

  scope :alphabetical, order_by([:last, :asc], [:first, :asc])
  scope :with_provider, where(:provider_performances.ne => nil).or(:provider_proformances.ne => [])
  scope :without_provider, any_of({provider_performances: nil}, {provider_performances: []})
  scope :provider_performance_between, ->(effective_date) { where("provider_performances.start_date" => {"$lt" => effective_date}).and('$or' => [{'provider_performances.end_date' => nil}, 'provider_performances.end_date' => {'$gt' => effective_date}]) }

	# added from bstrezze 
  def self.provider_in(provider_list) 
    any_in("provider_performances.provider_id" => provider_list)
  end

  def update_section_old(data, existing, section)	
		data[section].each do |nex|					
			exists = false
			if section == :allergies # type.code, start_time 				
				existing[section].each do |ex|
					if nex.type.code==ex.type.code && nex.start_time == ex.start_time
						exists = true
					end
					break if exists				
				end
			elsif (section == :immunizations) || (section == :results) || (section == :vital_signs) # time, cda...
				existing[section].each do |ex|
					if nex.cda_identifier.root == ex.cda_identifier.root && nex.cda_identifier.extension == ex.cda_identifier.extension && nex.time == ex.time
					end
					break if exists			
				end
			else 
				existing[section].each do |ex|
					if nex.cda_identifier.root == ex.cda_identifier.root && nex.cda_identifier.extension == ex.cda_identifier.extension && nex.start_time == ex.start_time
						exists = true
					end
					break if exists
				end
			end  		
			if !exists
				existing[section].push(nex)
			end
		end		
	end


	def update_section(data, existing, section)
		data[section].each do |con|
			#if start_date and cda_identifier.oid exist for any entry in existing
			exists = false				
			existing[section].each do |excon|
				if con.start_time==excon.start_time && con.cda_identifier.root==excon.cda_identifier.root
					exists = true
				end
				break if exists
			end
			#if doesn't exist, add to list of conditions				
			if !exists
				existing[section].push(con)		
			end					
		end			
	end

  def self.update_or_create(data)
    existing = Record.where(medical_record_number: data.medical_record_number, practice: data.practice).first
    if existing
    	#update
      existing.update_attributes!(data.attributes.except('_id', 'practice'))
						
#			update_section(data, existing, "encounters")				
#			update_section(:allergies)
#			update_section(:conditions)
#			update_section(data, existing, 'encounters')
#			update_section(:immunizations)
#			update_section(:medications)
#			update_section(:procedures)			
#			update_section(:vital_signs)
#			update_section(:results)
			
			Record::Sections.each do |section|				
				# for each data entry in the section
				# allergies - type.code, start_time
				# imm, results, vitals - time, cda root and extension
				if data.send(section) != nil && "#{section}" == 'encounters'								
					# for each data entry in the section
					data.send(section).each do |nex|
						exists = false
						existing.send(section).each do |ex|
							if nex.cda_identifier.root == ex.cda_identifier.root && nex.cda_identifier.extension == ex.cda_identifier.extension && nex.start_time == ex.start_time
								exists = true
							end
							break if exists
						end
						existing.send(section).push(nex) unless exists					
					end			
				end				
			end
			
			
#			# ALLERGIES --------------------------------------------------------------------			
#			# for each new entry, check if entry exists with start_date and 			
#			data.allergies.each do |con|
#				#if start_date and cda_identifier.oid exist for any entry in existing.conditions
#				exists = false				
#				existing.allergies.each do |excon|
#					if con.start_time==excon.start_time && con.reaction.code==excon.reaction.code
#						exists = true
#					end
#					break if exists
#				end
#				#if doesn't exist, add to list of conditions				
#				if !exists
#					existing.allergies.push(con)		
#				end					
#			end						
#			
#			# CONDITIONS --------------------------------------------------------------------
#			# for each new entry, check if entry exists with start_date and 			
#			data['conditions'].each do |con|
#				#if start_date and cda_identifier.oid exist for any entry in existing
#				exists = false				
#				existing['conditions'].each do |excon|
#					if con.start_time==excon.start_time && con.cda_identifier.root==excon.cda_identifier.root
#						exists = true
#					end
#					break if exists
#				end
#				#if doesn't exist, add to list of conditions				
#				if !exists
#					existing['conditions'].push(con)		
#				end					
#			end			
#						
#			# ENCOUNTERS --------------------------------------------------------------------
#			# for each new entry, check if entry exists with start_date and 			
#			data.encounters.each do |con|
#				#if start_date and cda_identifier.oid exist for any entry in existing
#				exists = false				
#				existing.encounters.each do |excon|
#					if con.start_time==excon.start_time && con.cda_identifier.root==excon.cda_identifier.root
#						exists = true
#					end
#					break if exists
#				end
#				#if doesn't exist, add to list of conditions				
#				if !exists
#					existing.encounters.push(con)		
#				end					
#			end			
#			
#			# MEDICATIONS --------------------------------------------------------------------			
#			# for each new entry, check if entry exists with start_date and 			
#			data.medications.each do |con|
#				#if start_date and cda_identifier.oid exist for any entry in existing
#				exists = false				
#				existing.medications.each do |excon|
#					if con.start_time==excon.start_time && con.cda_identifier.root==excon.cda_identifier.root
#						exists = true
#					end
#					break if exists
#				end
#				#if doesn't exist, add to list of conditions				
#				if !exists
#					existing.medications.push(con)		
#				end					
#			end			

#			# PROCEDURES --------------------------------------------------------------------			
#			# for each new entry, check if entry exists with start_date and 			
#			data.procedures.each do |con|
#				#if start_date and cda_identifier.oid exist for any entry in existing.conditions
#				exists = false				
#				existing.procedures.each do |excon|
#					if con.start_time==excon.start_time && con.cda_identifier.root==excon.cda_identifier.root #&& con.cda_identifier.extension == excon.cda_identifier.extension
#						exists = true
#					end
#					break if exists
#				end
#				#if doesn't exist, add to list of conditions				
#				if !exists
#					existing.procedures.push(con)		
#				end					
#			end			
#			
#			# RESULTS --------------------------------------------------------------------			
#			# for each new entry, check if entry exists with start_date and 			
#			data.results.each do |con|
#				#if start_date and cda_identifier.oid exist for any entry in existing.conditions
#				exists = false				
#				existing.results.each do |excon|
#					if con.time==excon.time && con.cda_identifier.root==excon.cda_identifier.root
#						exists = true
#					end
#					break if exists
#				end
#				#if doesn't exist, add to list of conditions				
#				if !exists
#					existing.results.push(con)		
#				end					
#			end			

#			# VITAL SIGNS --------------------------------------------------------------------			
#			# for each new entry, check if entry exists with start_date and 			
#			data.vital_signs.each do |con|
#				#if start_date and cda_identifier.oid exist for any entry in existing.conditions
#				exists = false				
#				existing.vital_signs.each do |excon|
#					if con.time==excon.time && con.cda_identifier.root==excon.cda_identifier.root
#						exists = true
#					end
#					break if exists
#				end
#				#if doesn't exist, add to list of conditions				
#				if !exists
#					existing.vital_signs.push(con)		
#				end					
#			end			
			
      existing
    else
    	# create
      data.save!
      data
    end
  end
  
  def language_names
    lang_codes = (languages.nil?) ? [] : languages.map { |l| l.gsub(/\-[A-Z]*$/, "") }
    Language.ordered.by_code(lang_codes).map(&:name)
  end
    
end
