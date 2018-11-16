'use strict'

BaseCtrl = require 'scripts/BaseClasses/BaseController.coffee'

# MISSING: SENDING HYPERPARAMETERS TO ALGORITHMS

module.exports = class ClassificationSidebarCtrl extends BaseCtrl
  @inject 'app_analysis_classification_dataService',
    'app_analysis_classification_msgService'
    'app_analysis_classification_algorithms'
    'app_analysis_classification_metrics'
    '$scope'
    '$timeout'

  initialize: ->
    @dataService = @app_analysis_classification_dataService
    @msgService = @app_analysis_classification_msgService
    @algorithmsService = @app_analysis_classification_algorithms
    @algorithms = @algorithmsService.getNames()

    @DATA_TYPES = @dataService.getDataTypes()
    # set up data and algorithm-agnostic controls

    @algParams = null
    @labelCol = null

    # dataset-specific
    @dataFrame = null
    @dataType = null
    @cols = []
    @chosenCols = []
    @numericalCols = []
    @categoricalCols = []
    @xCol = null
    @yCol = null

    # set up data controls
    @ready = off
    @running = off

    # dataset-specific
    @dataFrame = null

    # choose first algorithm as default one
    if @algorithms.length > 0
      @selectedAlgorithm = @algorithms[0]
      @updateAlgControls()

    # ASK BRADY
    @$timeout -> $('input[type=checkbox]').bootstrapSwitch()

    @dataService.getData().then (obj) =>
      if obj.dataFrame
        # make local copy of data
        @dataFrame = obj.dataFrame
        @parseData obj.dataFrame

  updateAlgControls: () ->
    @algParams = @algorithmsService.getParamsByName @selectedAlgorithm

  # update data-driven sidebar controls
  updateSidebarControls: (data) ->
    @cols = data.header
    @numericalCols = (col for col, idx in @cols when data.types[idx] in ['integer', 'number'])
    @categoricalCols = (col for col, idx in @cols when data.types[idx] in ['string', 'integer'])
    # make sure number of unique labels is less than maximum number of classes for visualization
    # if @algParams.c
    #   [minC, ..., maxC] = @algParams.c
    # Will probably make a longer if for each type of hyperparameter

    @$timeout =>
      #@updateDataPoints data

  uniqueVals: (arr) -> arr.filter (x, i, a) -> i is a.indexOf x

  ## Data preparation methods
  updateDataPoints: (data=null) ->
    if data
      xCol = data.header.indexOf @xCol unless !@xCol?
      yCol = data.header.indexOf @yCol unless !@yCol?
      @sendData = ([row[xCol], row[yCol]] for row in data.data) unless @chosenCols.length < 2
      @legendDict = {}
      labelDict = {}
      if @labelCol
        # HAVE SOMEONE REVISE THIS
        labelIndex = data.header.indexOf @labelCol
        @uniqueLabels = @uniqueVals (row[labelIndex] for row in data.data)

        console.log(@labelCol)
        console.log(row[labelIndex] for row in data.data)
        console.log("unique labels:")
        console.log(@uniqueLabels)

        if @uniqueLabels.length != 2
          labelDict[label] = i for label, i in @uniqueLabels

        else
          labelDict[@uniqueLabels[0]] = 1
          # labelDict[@uniqueLabels[1]] = -1
          labelDict[@uniqueLabels[1]] = 0



        # Make map from categorical label to numeric labels

        console.log("label dict:")
        console.log(labelDict)

        # Use map to create numeric labels
        @mappedLabels = (labelDict[row[data.header.indexOf(@labelCol)]] for row in data.data)

        console.log("mapped labels")
        console.log(@mappedLabels)

        # Reverse dict for the legend
        @legendDict[value] = key for key, value of labelDict

        console.log("legend dict")
        console.log(@legendDict)

      else
        @mappedLabels = (row[data.header.indexOf(@labelCol)] for row in data.data)


      console.log @xCol
      console.log @yCol

      @msgService.broadcast 'classification:updateDataPoints',
        dataPoints: @sendData
        labels: @mappedLabels
        legend: @legendDict
        xCol: @xCol
        yCol: @yCol


  updateChosenCols: () ->
    axis = [@xCol, @yCol]
    presentCols = ([name, idx] for name, idx in @chosenCols when name in axis)
    # if current X and Y are not among selected anymore
    switch presentCols.length
      when 0
        @xCol = if @chosenCols.length > 0 then @chosenCols[0] else null
        @yCol = if @chosenCols.length > 1 then @chosenCols[1] else null
      when 1
        upd = if @chosenCols.length > 1 then @chosenCols.find (e, i) -> i isnt presentCols[0][1] else null
        [@xCol, @yCol] = axis.map (c) -> if c isnt presentCols[0][0] then upd else c

    if @chosenCols.length > 1
      @updateDataPoints @dataFrame

  # get requested columns from data
  prepareData: () ->
    data = @dataFrame

    if @chosenCols.length > 1

      # get indices of feats to visualize in array of chosen
      xCol = @chosenCols.indexOf @xCol
      yCol = @chosenCols.indexOf @yCol
      chosenIdxs = @chosenCols.map (x) -> data.header.indexOf x

      # if usage of labels is on

      labelColIdx = data.header.indexOf @labelCol
      # labels = (row[labelColIdx] for row in data.data)

      data = (row.filter((el, idx) -> idx in chosenIdxs) for row in data.data)

      obj =
        features: data
        labels: @mappedLabels
        xIdx: xCol
        yIdx: yCol

    else false

  parseData: (data) ->
    @dataService.inferDataTypes data, (resp) =>
      if resp? and resp.dataFrame? and resp.dataFrame.data?
        df = @dataFrame
        # update data types with inferred
        for type, idx in df.types
         df.types[idx] = resp.dataFrame.data[idx]
        @updateSidebarControls(df)
        #@updateDataPoints(df)
        @ready = on

  startAlgorithm: ->
    algData = @prepareData()
    @running = on
    # Send selectedAlgorithm and hyperparameters

    if @algParams.c
      hyperPar =
        kernel: @selectedKernel
        c: @selectedC
      console.log "selected C"
      console.log @selectedC

    if @algParams.k
      hyperPar =
        k: @selectedK

    # Set data to model
    @algorithmsService.passDataByName(@selectedAlgorithm, algData)

    @algorithmsService.setParamsByName(@selectedAlgorithm, hyperPar)

    @msgService.broadcast 'classification:startAlgorithm',
      dataPoints: algData.data
      labels: algData.labels
      model: @selectedAlgorithm
      xCol: @xCol
      yCol: @yCol


  reset: ->
    # Resetting stuff in algorithms
    @algorithmsService.reset @selectedAlgorithm

    # Resetting main
    console.log("it is going into reset function in sidebar")
    # Gotta send resetting signal to main
    @msgService.broadcast 'classification:resetGrid',
      message: "reset grid"
      xCol : @xCol
      yCol : @yCol
      labels: @mappedLabels
      dataPoints: @sendData
      legend: @legendDict
      
    @running = off

    @$timeout -> $('input[type=checkbox]').bootstrapSwitch()


