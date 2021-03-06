R = React.DOM

@MovingRecordsApp = React.createClass
  propTypes:
    data:                React.PropTypes.arrayOf(React.PropTypes.object)
    itemNameSuggestions: React.PropTypes.object # {sofa: 30, desk: 10, ...}
    roomSuggestions:     React.PropTypes.arrayOf(React.PropTypes.string)
    categorySuggestions: React.PropTypes.arrayOf(React.PropTypes.string)

  getInitialState: ->
    records: @props.data
    barChartInstance: null
    pieChartInstance: null
    formDisplay:      false

  getDefaultProps: ->
    records: []

  addRecord: (record) ->
    records = React.addons.update(@state.records, { $unshift: [record] })
    @setState { records: records, formDisplay: true }

  deleteRecord: (record) ->
    index = @state.records.indexOf record
    records = React.addons.update(@state.records, { $splice: [[index, 1]] })
    @replaceState records: records

  # Relpace a record with the new one.
  updateRecord: (record, newRecord) ->
    index = @state.records.indexOf record
    records = React.addons.update(@state.records, { $splice: [[index, 1, newRecord]] })
    @replaceState records: records

  handleDisplayTable: (e) ->
    e.preventDefault()
    @setState(formDisplay: false) if @state.formDisplay

  handleDisplayForm: (e) ->
    e.preventDefault()
    @setState(formDisplay: true) if not @state.formDisplay

  # noticeProcessingAjax: ->
  #   R.div
  #     className: "alert alert-warning"
  #     R.i
  #       className: "fa fa-cog fa-spin fa-3x"
  #     R.div null,
  #       "Processing... If this is taking long, please make sure you are online."

  chartsPanelHeading: ->
    R.div
      className: 'panel-heading'
      R.div
        className: "row"
        R.div
          className: "col-xs-3"
          R.div
            className: "fa fa-home fa-5x"
          R.div
            className: "fa fa-truck fa-3x"
        R.div
          className: "col-xs-9 text-right"
          R.div
            className: 'huge'
            "Total: #{@totalVolume()}"
          R.div null,
            "cubic feet"

  chartsPanelBody: ->
    R.div
      className: 'panel-body'
      R.div
        className: 'row text-center'
        R.div
          className: 'col-sm-6'
          React.createElement ChartComponent("Bar"),
            name: "barChart"
            data: @dataForBarChart()
            height: 200
            width:  400
        R.div
          className: 'col-sm-6'
          React.createElement ChartComponent("Pie"),
            name: "pieChart"
            data: @dataForPieChart()
            height: 200
            width:  200

  chartsPanel: ->
    R.div
      className: "panel panel-blue"
      @chartsPanelHeading()
      @chartsPanelBody() if @state.records.length

  addForm: ->
    R.div null,
      R.h2 null,
        "Add a new item"
      if @state.formDisplay
        React.createElement NewMovingRecordForm,
          className: "new_record_form"
          handleNewRecord: @addRecord
          itemNameSuggestions: @props.itemNameSuggestions
          roomSuggestions:     @props.roomSuggestions
          categorySuggestions: @props.categorySuggestions

  tabs: ->
    R.ul
      className: "nav nav-tabs"
      role: 'tablist'
      R.li
        className: if not @state.formDisplay then "active" else ""
        R.a
          href:    "#tab_moving_items"
          onClick: @handleDisplayTable
          "All items"
      R.li
        className: if @state.formDisplay then "active" else ""
        R.a
          href:   "#tab_new_item"
          onClick: @handleDisplayForm
          "Add new item"

  tabContents: ->
    R.div
      className: "tab-content"
      R.div
        id: "tab_moving_items"
        className: if not @state.formDisplay then "tab-pane fade active in" else "tab-pane fade"
        React.createElement Records,
          records:            @state.records
          handleDeleteRecord: @deleteRecord
          handleUpdateRecord: @updateRecord
      R.div
        id: "tab_new_item"
        className: if @state.formDisplay then "tab-pane fade active in" else "tab-pane fade"
        @addForm()

  render: ->
    R.div
      className: "app_wrapper"
      @chartsPanel()
      @tabs()
      @tabContents()

  shuffleArray: (a) ->
    i = a.length
    while i
      # 1. Randomly pick one.
      j = Math.floor(Math.random() * i)
      # 2. Swap the tail with the random one.
      # 3. Cut off the tail at the same time.
      tmp  = a[--i]
      a[i] = a[j]
      a[j] = tmp
    a

  dataForPieChart: ->
    source = @volumeSortedBy("room")
    ary = []
    colors = ["#FE2E2E", "#FE9A2E", "#9AFE2E", "#2EFE2E", "#2EFE9A", "#2EFEF7",
              "#2E9AFE", "#2E2EFE", "#9A2EFE", "#FE2EF7", "#FE2E9A", "#0099cc",
              "#9933cc", "#669900", "#ff8a00", "#cc0000", "#6dcaec", "#cf9fe7",
              "#b6db49", "#ff7979"]

    @shuffleArray(colors)
    for item, i in source
      obj =
        value:     item.volume
        color:     colors[i]
        highlight: colors[i]
        label:     item.room
      ary.push(obj)
    ary

  dataForBarChart: ->
    source = @volumeSortedBy("category")
    labels = source.map (obj) -> obj.category
    data   = source.map (obj) -> obj.volume
    datasets = [
        {
          fillColor:       "rgba(151,187,205,0.5)"
          strokeColor:     "rgba(151,187,205,0.8)"
          highlightFill:   "rgba(151,187,205,0.75)"
          highlightStroke: "rgba(151,187,205,1)"
          data:            data
        }
      ]
    { labels: labels, datasets: datasets }

  # For sorting an array of objects by the value of specified property.
  predicateBy: (prop) ->
    (a, b) ->
      if a[prop] > b[prop]
        return -1
      else if a[prop] < b[prop]
        return 1
      0

  # prop: "room" or "category"
  volumeSortedBy: (prop) ->
    # 1. Filtering
    filtered = {}
    for obj in @state.records
      vol = parseFloat(obj.volume * obj.quantity)
      if filtered.hasOwnProperty(obj[prop])
        filtered[obj[prop]] += vol  # Add up data to the matched key
      else
        filtered[obj[prop]] = vol   # Create a key
    # 2. Converting to an array of data objects
    ary = []
    for room, volume of filtered
      data = {}
      data[prop] = room
      data["volume"] = volume
      ary.push data
    # 3. Sorting
    ary.sort( @predicateBy("volume") )

  totalVolume: ->
    sum = 0
    for obj in @state.records
      sum += (obj.volume * obj.quantity)
    sum
