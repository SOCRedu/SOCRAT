'use strict'

BaseService = require 'scripts/BaseClasses/BaseService.coffee'

###
  @name:
  @type: service
  @desc: Performs spectral clustering using NJW algorithm

###

module.exports = class NormalDist extends BaseService
  @inject 'socrat_analysis_modeler_getParams'
  initialize: () ->
    @getParams = @socrat_analysis_modeler_getParams

    @name = 'Normal'


  getName: () ->
    return @name


  getChartData: (data) ->
    histData = data.dataPoints
    histData = histData.map (row) ->
            x: row[0]
            y: row[1]
            z: row[2]
            r: row[3]
    stats = @getParams.getParams(data)
    data.stats = stats
    data.xMin = d3.min(histData, (d)->parseFloat d.x)
    data.xMax = d3.max(histData, (d)->parseFloat d.x)
    data.curveData = @getParams.getGaussianFunctionPoints(stats.standardDev, stats.mean, stats.variance, data.xMin , data.xMax)
    console.log("hist")
    console.log(histData)
    console.log("xMin")

    console.log(data.xMin)

    
    return data


