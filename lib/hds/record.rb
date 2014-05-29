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
  
  scope :valid_practice_patients, ->(effective_date, practice) { where("provider_performances.start_date" => {"$lt" => effective_date}).and('$or' => [{'provider_performances.end_date' => nil}, 'provider_performances.end_date' => {'$gt' => effective_date}]).and( 'practice' => practice )}


	# added from bstrezze 
  def self.provider_in(provider_list) 
    any_in("provider_performances.provider_id" => provider_list)
  end

  def self.update_or_create(data)
    existing = Record.where(medical_record_number: data.medical_record_number, practice: data.practice).first
    if existing
    	#update
      existing.update_attributes!(data.attributes.except('_id', 'practice'))
			
			Record::Valid_Sections.each do |section|				
				# for each data entry in the section
				# allergies - type.code, start_time
				# imm, results, vitals - time, cda root and extension
				# allergies, conditions, immunizations, encounters, procedures, medications, vital_signs
				
				if data.send(section) != nil && "#{section}" == 'allergies'								
					# for each data entry in the section
					data.send(section).each do |nex|
						exists = false
						existing.send(section).each do |ex|
							if nex.type.code == ex.type.code && ( (nex.start_time && nex.start_time==ex.start_time) || (nex.time && nex.time == ex.time)) #nex.start_time == ex.start_time
								exists = true
							end
							break if exists
						end
						existing.send(section).push(nex) unless exists					
					end			
				
				elsif data.send(section) != nil && ("#{section}" == 'immunizations' || "#{section}"=='vital_signs' || "#{section}"=='results') 								
					# for each data entry in the section
					data.send(section).each do |nex|
						exists = false
						existing.send(section).each do |ex|
							if nex.cda_identifier.root == ex.cda_identifier.root && nex.cda_identifier.extension == ex.cda_identifier.extension && ( (nex.start_time && nex.start_time==ex.start_time) || (nex.time && nex.time == ex.time)) #nex.time == ex.time
								exists = true
							end
							break if exists
						end
						existing.send(section).push(nex) unless exists					
					end			
				
				elsif data.send(section) != nil						
					# for each data entry in the section
					data.send(section).each do |nex|
						exists = false
						existing.send(section).each do |ex|
							if nex.cda_identifier.root == ex.cda_identifier.root && nex.cda_identifier.extension == ex.cda_identifier.extension && ( (nex.start_time && nex.start_time==ex.start_time) || (nex.time && nex.time == ex.time))
								exists = true
							end
							break if exists
						end
						existing.send(section).push(nex) unless exists					
					end			
				end					
			end

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
