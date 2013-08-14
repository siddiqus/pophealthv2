class Measure

  GROUP = {'$group' => {_id: "$id", 
                        name: {"$first" => "$name"},
                        description: {"$first" => "$description"},
                        sub_ids: {'$push' => "$sub_id"},
                        subs: {'$push' => {"sub_id" => "$sub_id", "short_subtitle" => "$short_subtitle"}},
                        category: {'$first' => "$category"}}}

  CATEGORY = {'$group' => {_id: "$category",
                           measures: {'$push' => {"id" => "$_id", 
                                                  'name' => "$name",
                                                  'description' => "$description",
                                                  'subs' => "$subs",
                                                  'sub_ids' => "$sub_ids"
                                                  }}}}

  ID = {'$project' => {'category' => '$_id', 'measures' => 1, '_id' => 0}}
  
  SORT = {'$sort' => {"category" => 1}}

  def self.all
    MONGO_DB['measures'].find({})
  end

  def self.categories
    aggregate(GROUP, CATEGORY, ID, SORT)
  end

  def self.list
    aggregate({'$project' => {'id' => 1, 'sub_id' => 1, 'name' => 1, 'short_subtitle' => 1}})
  end

  private

  def self.aggregate(*pipeline)
    Mongoid.default_session.command(aggregate: 'measures', pipeline: pipeline)['result']
  end

	# CATEGORY DEFS ADDED FROM BSTREZZE

 	# Finds all measures by category, except for core and core alternate measures
  # @return Array - This returns an Array of Hashes. Each Hash will have a category property for
  #         the name of the category. It will also have a measures property which will be
  #         another Array of Hashes. The sub hashes will have the name and id of each measure.
  def self.non_core_measures
    MONGO_DB['measures'].find(:key => :category, 
                            :cond => {:category => {"$nin" => ['Core', 'Core Alternate']}},
                            :initial => {:measures => []},
                            :reduce =>
                            'function(obj,prev) {
                                  var measureIds = [];
                                  for (var i = 0; i < prev.measures.length; i++) {
                                    measureIds.push(prev.measures[i].id)
                                  }
                                  if (contains(measureIds, obj.id) == false) {
                                    prev.measures.push({"id": obj.id, "name": obj.name, "description": obj.description});
                                  }
                                  
                             };')
  end
  
  # Finds all core measures
  # @return Array - This returns an Array of Hashes. Each Hash will have the name and id of each measure.
  def self.core_measures
    MONGO_DB['measures'].find(:key => [:id, :name, :description], 
                            :cond => {:category => 'Core'},
                            :initial => {:subs => [], 'short_subtitles' => {}},
                            :reduce => 
                            'function(obj,prev) {if (obj.sub_id != null) {prev.subs.push(obj.sub_id); prev.short_subtitles[obj.sub_id] = obj.short_subtitle; }}')
  end
  
  # Finds all core alternate measures
  # @return Array - This returns an Array of Hashes. Each Hash will have the name and id of each measure.
  def self.core_alternate_measures
    MONGO_DB['measures'].find(:key => [:id, :name, :description], 
                            :cond => {:category => 'Core Alternate'},
                            :initial => {:subs => [], 'short_subtitles' => {}},
                            :reduce => 'function(obj,prev) {if (obj.sub_id != null) {prev.subs.push(obj.sub_id); prev.short_subtitles[obj.sub_id] = obj.short_subtitle; }}')
  end
  
  # Finds all measures and groups the sub measures
  # @return Array - This returns an Array of Hashes. Each Hash will have a name property for
  #         the name of the measure as well and an id for each mesure. It will also have a subs
  #         property which will be an array of sub ids.
  def self.all_by_measure
    MONGO_DB['measures'].find(:key => [:id, :name],
                            :initial => {:subs => [], 'short_subtitles' => {}},
                            :reduce => 'function(obj,prev) {
                                          if (obj.sub_id != null) {
                                            prev.subs.push(obj.sub_id);
                                            prev.short_subtitles[obj.sub_id] = obj.short_subtitle
                                          }
                                          
                                        }')
  end
  
  # 
  def self.alternate_measures
    MONGO_DB['measures'].find(:key => [:id, :name, :description, :category], 
                            :cond => {:category => {"$nin" => ['Core', 'Core Alternate']}},
                            :initial => {:subs => [], 'short_subtitles' => {}},
                            :reduce => 'function(obj,prev) {if (obj.sub_id != null) {prev.subs.push(obj.sub_id); prev.short_subtitles[obj.sub_id] = obj.short_subtitle; }}')
  end

end