'use strict'

require 'jquery-ui/ui/widgets/slider'

BaseDirective = require 'scripts/BaseClasses/BaseDirective'

module.exports = class ChartsDir extends BaseDirective
  @inject 'app_analysis_charts_areaChart',
          'app_analysis_charts_areaTrellisChart'
          'app_analysis_charts_barChart',
          'app_analysis_charts_bivariateLineChart',
          'app_analysis_charts_bubbleChart',
          'app_analysis_charts_histogram',
          'app_analysis_charts_lineChart',
          'app_analysis_charts_normalChart',
          'app_analysis_charts_pieChart',
          'app_analysis_charts_scatterPlot',
          'app_analysis_charts_streamChart',
          'app_analysis_charts_stackedBar',
          'app_analysis_charts_tilfordTree',
          'app_analysis_charts_trellisChart',
          'app_analysis_charts_treemap',
          'app_analysis_charts_tukeyBoxPlot',
          'app_analysis_charts_checkTime'

  initialize: ->
    @areaTrellis = @app_analysis_charts_areaTrellisChart
    @bar = @app_analysis_charts_barChart
    @bubble = @app_analysis_charts_bubbleChart
    @histogram = @app_analysis_charts_histogram
    @pie = @app_analysis_charts_pieChart
    @scatterPlot = @app_analysis_charts_scatterPlot
    @stackBar = @app_analysis_charts_stackedBar
    @time = @app_analysis_charts_checkTime
    @trellis = @app_analysis_charts_trellisChart
    @streamGraph = @app_analysis_charts_streamChart
    @area = @app_analysis_charts_areaChart
    @treemap = @app_analysis_charts_treemap
    @line = @app_analysis_charts_lineChart
    @bivariate = @app_analysis_charts_bivariateLineChart
    @normal = @app_analysis_charts_normalChart
    @pie = @app_analysis_charts_pieChart
    @tukeyBoxPlot = @app_analysis_charts_tukeyBoxPlot

    @restrict = 'E'
    @template = "<div id='vis' class='graph-container' style='overflow:auto; height: 600px'></div>"

    @link = (scope) =>
      data = null
      labels = null

      # add segments to a slider
      # https://designmodo.github.io/Flat-UI/docs/components.html#fui-slider
      $.fn.addSliderSegments = (amount, orientation) ->
        @.each () ->
          if orientation is "vertical"
            output = ''
            for i in [0..amount-2]
              output += '<div class="ui-slider-segment" style="top:' + 100 / (amount - 1) * i + '%;"></div>'
            $(this).prepend(output)
          else
            segmentGap = 100 / (amount - 1) + "%"
            segment = '<div class="ui-slider-segment" style="margin-left: ' + segmentGap + ';"></div>'
            $(this).prepend(segment.repeat(amount - 2))

      scope.$watch 'mainArea.chartData', (newChartData) =>
        if newChartData and newChartData.dataPoints
          data = newChartData.dataPoints
          labels = newChartData.labels
          scheme = newChartData.graph

          # trellis chart is called differently
          if scheme.name is 'Trellis Chart'
            @trellis.drawTrellis(data,labels,container)
          # standard charts
          else
            switch scheme.name
              when 'Area Trellis Chart'
                @areaTrellis.areaTrellisChart(data,ranges,width,height,_graph,labels,container)
              when 'Bar Graph'
                @bar.drawBar(data,labels)
              when 'Bubble Chart'
                @bubble.drawBubble(width,height,_graph,data,labels,container,ranges)
              when 'Histogram'
                @histogram.drawHist(_graph, data, container, labels, width, height, ranges)
              when 'Tukey Box Plot (1.5 IQR)'
                @tukeyBoxPlot.drawBoxPlot(_graph, data, container, labels, width, height, ranges)
              when 'Ring Chart'
                _graph = svg.append('g').attr("transform", "translate(300,250)").attr("id", "remove")
                @pie.drawPie(data,width,height,_graph,false)
              when 'Scatter Plot'
                @scatterPlot.drawScatterPlot(data,labels)
              when 'Stacked Bar Chart'
                @stackBar.stackedBar(data,ranges,width,height,_graph, labels,container)
              when 'Stream Graph'
                @streamGraph.streamGraph(data,ranges,width,height,_graph,scheme,labels)
              when 'Area Chart'
                @area.drawArea(height,width,_graph, data, labels)
              when 'Treemap'
                @treemap.drawTreemap(svg, width, height, container, data)
              when 'Line Chart'
                @line.lineChart(data,ranges,width,height,_graph, labels,container)
              when 'Bivariate Area Chart'
                # @time.checkTimeChoice(data)
                @bivariate.bivariateChart(height,width,_graph, data, labels)
              when 'Normal Distribution'
                @normal.drawNormalCurve(data, width, height, _graph)
              when 'Pie Chart'
                _graph = svg.append('g').attr("transform", "translate(300,250)").attr("id", "remove")
                @pie.drawPie(data,width,height,_graph,true)
