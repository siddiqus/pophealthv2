jQuery ->
        $('#logTable').dataTable()
        sPaginationType: "full_numbers"
        bJQueryUI: true
        
jQuery ->
        $('#adminPatientTable').dataTable()
        sPaginationType: "full_numbers"
        bJQueryUI: true
					
class @QualityReport
	constructor: (@measure, @sub_id, @filters) ->
		@sub_id or= null
		@filters or= ActiveFilters.all()
	url: -> 
		base = "#{rootContext}/measure/#{@measure}"
		if @sub_id? then "#{base}/#{@sub_id}" else base
	fetch: (extraParams, callback) ->
		params = $.extend({}, @filters, extraParams)
		$.getJSON this.url(), $.extend({}, @filters, params), (data) -> 
			callback(data)
	poll: (params, callback) ->
		this.fetch params, (response) =>
			uuids={}
			console.log(response)
			$.each response.jobs, (i, job) =>
				sub_id = ''
				sub_id = job['sub_id'] if job['sub_id']
				uuids[job['measure_id'] + sub_id] = job['uuid']
			pollParams = $.extend(params, {jobs: uuids})
			if (!response.complete && !response.failed)
				setTimeout (=> @poll(pollParams, callback)), 3000
			else if (response.complete)
				callback(response)
@Page = {
	onMeasureSelect: (measure_id) ->
	onMeasureRemove: (measure_id) ->
	onFilterChange: (qr, li) ->
	onReportComplete: (qr) ->
	onLoad: ->
	params: {}
}

@ActiveFilters = {
	all: ->
		ActiveFilters.findFilters(".filterItemList input:checked:not(:disabled)")
	providers: ->
		ActiveFilters.findFilters(".filterItemList input:checked:not(:disabled)[data-filter-type='provider']")
	nonProvider: ->
		ActiveFilters.findFilters(".filterItemList input:checked:not([data-filter-type='provider'])")
	findFilters: (selector) ->
		filterElements = _.map $(selector), (el) -> type: $(el).data("filter-type"), value: $(el).data("filter-value")
		filters = _.reduce filterElements, (memo, filter) ->
			if filter.type?
				filter_key = "#{filter.type}\[\]"
				memo[filter_key] = [] unless memo[filter_key]?
				memo[filter_key].push(filter.value)
			return memo
		, {}
		return filters
}

@Render = {
	fraction: (selector, data) ->
		selector.find(".numeratorValue").html(data.NUMER)
		selector.find(".denominatorValue").html(data.DENOM)
	
	full_percent: (selector, data) -> 
		percent = if (data.full_denom == 0 || data.full_denom == undefined) then 0 else  (data.full_numer / data.full_denom) * 100
		selector.html("#{Math.floor(percent)}%")	
	
	percent: (selector, data) -> 
		percent = if (data.DENOM == 0 || data.DENOM == undefined) then 0 else  (data.NUMER / data.DENOM) * 100
		selector.html("#{Math.floor(percent)}%")	
		
	barChart: (selector, data) ->
		numerator_width = 0
		denominator_width = 0
		exclusion_width = 0
		if data.IPP != 0
			numerator_width = Math.floor((data.NUMER / data.considered) * 100)
			denominator_width = Math.floor( ((data.DENOM - data.NUMER) / data.considered) * 100) 
			exclusion_width = Math.floor( (data.DENEX / data.considered) * 100	)
		selector.find("div.measureBarNumerator").animate({width: "#{numerator_width}%"}, "slow");
		selector.find("div.measureBarDenominator").animate({width: "#{denominator_width}%"}, "slow");
		selector.find("div.measureBarExclusions").animate({width: "#{exclusion_width}%"}, "slow");	

}

@makeMeasureListClickable = ->
	$("#providerReports .accordion a").click -> 
		others = $(@).parentsUntil("#providerReports").last().find("a").not(@)
		others.children("i").replaceWith("<i class=\"icon-chevron-right pull-left\"></i>")
		$(@).children("i").toggleClass("icon-chrevron-right icon-chevron-down")

	$(".measureItemList input").on "change", ->
		measure = $(this).attr("data-measure-id")
		subs = $(this).data("sub-measures")
		sub_ids = if subs? then subs.split(",") else [null]
		if $(this).attr("checked")
			Page.onMeasureSelect(measure)
			$.each sub_ids, (i, sub) ->
				qr = new QualityReport(measure, sub)
				qr.poll({npi: Page.npi}, Page.onReportComplete)
		else
			Page.onMeasureRemove(measure)
@makeFilterListsClickable = ->
	$("ul input.all").change ->
		filterList = $(@).parents("ul").filter(":first")
		allSelected = $(@).attr("checked")?
		$.each filterList.find("input:not(.all)"), (i, filter) =>
			$(filter).attr("checked", true)	
			$(filter).attr("disabled", $(@).attr("checked")?)
	$(".filterItemList li input").change ->
		Page.onFilterChange(@)


	
# Load Page
$ ->
	setTimeout ->
		makeMeasureListClickable()
		makeFilterListsClickable()
		#makeListsExpandable()
		Page.onLoad();
#		, 10
