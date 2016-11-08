'use strict'

BaseService = require 'scripts/BaseClasses/BaseService.coffee'

module.exports = class ChartsPieChart extends BaseService

  initialize: ->
    @valueSum = 0

  makePieData: (data) ->
    @valueSum = 0
    counts = {}
    if(!isNaN(data[0].x)) # data is number
      pieMax = d3.max(data, (d)-> parseFloat d.x)
      pieMin = d3.min(data, (d)-> parseFloat d.x)
      maxPiePieces = 7  # set magic constant to variable
      rangeInt = Math.ceil((pieMax - pieMin) / maxPiePieces)
      counts = {}
      for val in data
        index = Math.floor((val.x - pieMin) / rangeInt)
        groupName = index + "-" + (index + rangeInt)
        #console.log groupName
        counts[groupName] = counts[groupName] || 0
        counts[groupName]++
        @valueSum++
    else # data is string
      for i in [0..data.length-1] by 1
        currentVar = data[i].x
        counts[currentVar] = counts[currentVar] || 0
        counts[currentVar]++
        @valueSum++
    obj = d3.entries counts
    return obj

  drawPie: (data,width,height,_graph, pie) -> # "pie" is a boolean
      radius = Math.min(width, height) / 2
      outerRadius = radius
      arc = d3.svg.arc()
      .outerRadius(outerRadius)
      .innerRadius(0)

      if not pie # ring chart
        arc.innerRadius(radius-60)

      color = d3.scale.category20c()
      
      arcOver = d3.svg.arc()
      .outerRadius(radius + 10)
      
      if not pie # ring chart
        arcOver.innerRadius(radius-50)

      pie = d3.layout.pie()
      .value((d)-> d.value)
      .sort(null)

      formatted_data = @makePieData data
      
      # PIE ARCS / SLICES

      arcs = _graph.selectAll(".arc")
      .data(pie(formatted_data))
      .enter()
      .append('g')
      .attr("class", "arc")   
      
      sum = @valueSum
      
      # Create Event Handlers for mouse
      handleMouseOver = (d, i) ->
      
        # Use d3 to select element
        d3.select(this)
        .attr("stroke","white") 
        .transition()
        .attr("d", arcOver)
        .attr("stroke-width",3)
        
        # Specify where to put text label
        _graph.append('text').attr(
          # Create an id for text so we can select 
          # it later for removing on mouseout
          id: 't' + d.x + '-' + d.y + '-' + i
        ).attr('transform', () -> 
          c = arc.centroid(d)
          x = c[0]
          y = c[1]
          h = Math.sqrt(x*x + y*y)
          desiredLabelRad = 220
          'translate('+ (x/h * desiredLabelRad) + ',' + (y/h * desiredLabelRad) + ')'
        ).transition()
        .text () => 
          d.data.key + ' (' + parseFloat(100 * d.value / sum).toFixed(1) + '%)'
        .style('font-size', '16px')
        
        
      handleMouseOut= (d, i) ->
    
        d3.select(this)
        .transition()
        .attr('d', arc)
        .attr("stroke", "none")
        
        # remove the text label
        d3.select('#t' + d.x + '-' + d.y + '-' + i)
        .transition()
        .remove()

      arcs.append('path')
      .attr('d', arc)
      .attr('fill', (d) -> color(d.data.value))
      .on('mouseover', handleMouseOver)
      .on('mouseout', handleMouseOut)
      
      
      
      
      
      
      

      
      


