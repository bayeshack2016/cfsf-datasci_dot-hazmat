  var DATAFILE = 'data/randdata.csv' // input data file

  var FACTORS = [ {name:"Producing Acres", min:"0", max:"6035593", start:"0"/*, step:2000*/},
                  {name:"Number of Producable Wells", min:"0", max:"47100", start:"0"/*, step:1000*/},
                  {name:"Number of Producible Completions", min:"0", max:"53746", start:"0"/*, step:1000*/},
                  {name:"Mining/Logging Employees (x1000)", min:"0", max:"410611", start:"0"/*, step:1000*/} ]
  // FACTORS will auto populate the HTML file with the above values

  function theMODEL(inputs) {
    // theMODEL takes in inputs, sends it to the model, and returns a new data array
    // inputs is an array of integers scraped from the sliders: [ f1, f2, f3, f4 ]

    var coeffs = [
      -0.0001434256,
      0.218208344,
      -0.1488391305,
      5.3622173277,
      261.8082131641
    ]
    var newValue = Math.round(coeffs[0] * inputs[0] + coeffs[1] * inputs[1] + coeffs[2] * inputs[2] + coeffs[3] * inputs[3] + coeffs[4])

    redrawAfterCall(newValue)

    // d3.csv('data/randdata2.csv', function(data){
    //   redrawAfterCall(data)
    // })

  }

  // figure out the current year and set a keystring accordingly
  var yearOfInterest = new Date().getFullYear()
  var year = 'predicted_incidents_' + yearOfInterest

  //TODO: set min/max per state
  // populate the sliders on the page from the FACTORS array
  FACTORS.forEach(function(el,i){
    var slider = document.getElementById('inputf'+(i+1))
    slider.value = el.start
    slider.min = el.min
    slider.max = el.max
    slider.step = el.step
    document.getElementById('outputf'+(i+1)).innerHTML = el.start
    document.getElementById('labelf'+(i+1)).innerHTML = el.name
  })

  // dictionary for looking up {state: 'property to color by'}
  var colorMap = d3.map()

  var allData,
      incidentsByYear,
      fipsData,
      totalIncidents,
      incidentsByState,
      stateincidents

  // get the fips dictionary used for the topojson map
  d3.json('data/statefips.json', function(data){
        fipsData = data
      })

  // tooltip methods
  var tt = {
    init: function(element){
      d3.select(element).append('div')
          .attr('id', 'tooltip')
          .attr('class', 'hidden')
        .append('span')
          .attr('class', 'value')
    },
    follow: function(element, caption, options) {
      element.on('mousemove', null);
      element.on('mousemove', function() {
        var position = d3.mouse(document.body);
        d3.select('#tooltip')
          .style('top', ( position[1] - 8 ) + "px")
          .style('left', ( position[0] + 16 ) + "px");
        d3.select('#tooltip .value')
          .html(caption);
      });
      d3.select('#tooltip').classed('hidden', false);
    },
    hide: function() {
      d3.select('#tooltip').classed('hidden', true);
    }
  }

  tt.init("body")

  // define the svg properties
  var active = d3.select(null),
      fullWidth = 625,
      fullHeight = 400,
      barFullWidth = 950,
      barFullHeight = 200,
      lineFullWidth = 500,
      lineFullHeight = 300

  var margin = {top: 20, right: 10, bottom: 25, left: 40},
      barWidth = barFullWidth - margin.left - margin.right,
      barHeight = barFullHeight - margin.top - margin.bottom

  var projection = d3.geo.albersUsa()
      .scale(800)
      .translate([fullWidth / 2, fullHeight / 2]);

  var zoom = d3.behavior.zoom()
      .translate([0, 0])
      .scale(1)
      .scaleExtent([1, 8])
      .on("zoom", zoomed);

  var path = d3.geo.path()
      .projection(projection);

  var mapSvg = d3.select("#map-container").append("svg")
      .attr("width", fullWidth)
      .attr("height", fullHeight)
      // .on("click", stopped, true);

  mapSvg.append("rect")
      .attr("class", "background")
      .attr("width", fullWidth)
      .attr("height", fullHeight)
      // .on("click", reset);

  var mg = mapSvg.append("g");

  mapSvg
      .call(zoom) // delete this line to disable free zooming
      .call(zoom.event);

  var barSvg = d3.select("#bar-container").append("svg")
      .attr("width", barFullWidth)
      .attr("height", barFullHeight)
  var bg = barSvg.append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

  var lineChart = d3.select('#line-container')
  lineFullWidth = lineChart.node().getBoundingClientRect().width

  var line = lineGraph()
    .width(lineFullWidth)
    .height(lineFullHeight)
    .margin(margin)
    .xaccessor('key')
    .yaccessor('values')
    .yAxisLabel('Total Incidents')
    .xAxisLabel('Year')
    .tickFormat(d3.format('0s'))


  var x = d3.scale.ordinal()
      .rangeRoundBands([0, barWidth], .2);

  var y = d3.scale.linear()
      .range([barHeight, 0]);

  var xAxis = d3.svg.axis()
      .scale(x)
      .orient("bottom");

  var yAxis = d3.svg.axis()
      .scale(y)
      .orient("left")
      .ticks(10)
      .tickFormat(d3.format(".2s"))

  // d3 scale for coloring via css
  var quantize = d3.scale.quantize()
      .range(d3.range(9).map(function(i) { return 'q' + i + '-9' }))

  queue()
    .defer(d3.json, 'data/topo/us-states-10m.json') // get map
    .defer(d3.csv, DATAFILE) // get data
    .defer(d3.csv, 'data/hazmat_incidents_by_state_and_year.csv') // get historical data by state
    .await(renderFirst)

  function renderFirst(error, us, csvData, stateData) {
    if (error) throw error;

    allData = csvData
    incidentsByState = d3.nest().key(function(d){return d.State}).entries(stateData)
    incidentsByYear = d3.nest().key(function(d){return d.year}).rollup(function(v) { return d3.sum(v, function(d) { return d.number_of_hazardous_incidents; }); }).entries(stateData)

    setColorKey(allData, year)
    totalIncidents = calculateTotalIncidents(allData, year)
    d3.select('#total-incidents-label').html('Nationwide Predicted Incidents for ' + yearOfInterest + ':')
    d3.select('#total-incidents').html(totalIncidents.toLocaleString())

    // draw map
    mg.selectAll("path")
        .data(topojson.feature(us, us.objects.states).features)
      .enter().append("path")
        .attr("d", path)
        .on("click", function(d) {return setStateActive(d.id)})
        .attr("class", function(d){
          return 'state ' + quantize(colorMap.get(d.id))
        })
        .on('mouseover', function(d) {
            var me = d3.select(this),
                thisText = fipsToState(+d.id)
            tt.follow(me, thisText)
            setStateCallout(d3.select(this).data()[0].id)
          })
        .on("mouseout", tt.hide )

    mg.append("path")
        .datum(topojson.mesh(us, us.objects.states, function(a, b) { return a !== b; }))
        .attr("class", "mesh")
        .attr("d", path);

    // mg.selectAll('path')
    //     .data(topojson.feature(us, us.objects.counties).features)
    //   .enter().append("path")
    //     .attr("d", path)
    //     .attr('class', 'county')

    // draw barchart
    x.domain(allData.map(function(d) { return d.state; }));
    y.domain([0, d3.max(allData, function(d) { return +d[year]; })]);

    bg.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + barHeight + ")")
        .call(xAxis);

    bg.append("g")
        .attr("class", "y axis")
        .call(yAxis)
      .append("text")
        .attr("transform", "rotate(-90)")
        .attr("y", 6)
        .attr("dy", ".71em")
        .style("text-anchor", "end")
        .text("Incidents");

    bg.selectAll(".bar")
        .data(allData)
      .enter().append("rect")
        .attr("class", function(d){
          return 'bar ' + quantize(colorMap.get(d.id))
        })
        .attr("x", function(d) { return x(d.state); })
        .attr("width", x.rangeBand())
        .attr("y", function(d) { return y(d[year]); })
        .attr("height", function(d) { return barHeight - y(d[year]); })
        .on('mouseover', function(d) {
            var me = d3.select(this),
                thisText = fipsToState(+d.id) + ': ' + colorMap.get(d.id).toLocaleString()
            tt.follow(me, thisText)
        })
        .on("mouseout", tt.hide )

    // draw lineGraph
    incidentsByYear.push({key: yearOfInterest, values: totalIncidents})
    incidentsByYear.forEach(function(el){ el.values = +el.values})
    lineChart.datum(incidentsByYear).call(line)
  };

  function setColorKey (data, value) {
    data.forEach(function(d){
      colorMap.set(d.id, +d[value]);
    })
    quantize.domain( d3.extent(data,function(d){return +d[value]}) )
  }

  function clicked(d) {
    //zoom in on click
    setStateCallout(d3.select(this).data()[0].id)

    if (active.node() === this) return reset();
    active.classed("active", false);
    active = d3.select(this).classed("active", true);

    var bounds = path.bounds(d),
        dx = bounds[1][0] - bounds[0][0],
        dy = bounds[1][1] - bounds[0][1],
        x = (bounds[0][0] + bounds[1][0]) / 2,
        y = (bounds[0][1] + bounds[1][1]) / 2,
        scale = .9 / Math.max(dx / fullWidth, dy / fullHeight),
        translate = [fullWidth / 2 - scale * x, fullHeight / 2 - scale * y];

    mapSvg.transition()
        .duration(750)
        .call(zoom.translate(translate).scale(scale).event);
  }

  function reset() {
    //reset zoom
    active.classed("active", false);
    active = d3.select(null);

    mapSvg.transition()
        .duration(750)
        .call(zoom.translate([0, 0]).scale(1).event);

    d3.selectAll('.callout').html('')
  }

  function zoomed() {
    // calculate zoom
    mg.style("stroke-width", 1.5 / d3.event.scale + "px");
    mg.attr("transform", "translate(" + d3.event.translate + ")scale(" + d3.event.scale + ")");
  }

  function stopped() {
    // If the drag behavior prevents the default click,
    // also stop propagation so we don’t click-to-zoom.
    if (d3.event.defaultPrevented) d3.event.stopPropagation();
  }


  /* page listeners */
  d3.selectAll('#controls input').on('change', function(){
    return dispatcher.changeInput()
  })

  /* dispatcher events */
  var dispatcher = d3.dispatch('changeInput')
  dispatcher.on('changeInput', function(year){
      // read input values,
      var inputs = [
        +d3.select("#inputf1").node().value,
        +d3.select("#inputf2").node().value,
        +d3.select("#inputf3").node().value,
        +d3.select("#inputf4").node().value
      ]
      theMODEL(inputs)
  })

  function redrawAfterCall(newValue){
    // allData = data
    // totalIncidents = calculateTotalIncidents(allData, year)
    // d3.select('#total-incidents-label').html('Nationwide Predicted Incidents for ' + yearOfInterest + ':')
    // d3.select('#total-incidents').html(totalIncidents.toLocaleString())
    // y.domain([0, d3.max(allData, function(d) { return +d[year]; })]);
    // d3.select('.y.axis').transition().call(yAxis)
    //
    // setColorKey(allData, year)
    // d3.selectAll(".state")
    //     .attr("class", function(d){
    //       return 'state ' + quantize(colorMap.get(d.id))
    //     })
    // bg.selectAll(".bar")
    //     .attr("class", function(d){
    //       return 'bar ' + quantize(colorMap.get(d.id))
    //     })
    //     .transition()
    //     .attr("x", function(d) { return x(d.state); })
    //     .attr("width", x.rangeBand())
    //     .attr("y", function(d) { return y(d[year]); })
    //     .attr("height", function(d) { return barHeight - y(d[year]); })

    d3.select('#state-incidents-label').html('Predicted Incidents for ' + yearOfInterest + ':')
    d3.select('#state-incidents').html(newValue.toLocaleString())

    var index = stateincidents.values.findIndex(function(el){
      //find the value to adjust
      return +el.year === yearOfInterest
    })
    //adjust the value
    stateincidents.values[index].number_of_hazardous_incidents = newValue
    //redraw the line
    lineChart.datum(stateincidents.values).call(line)
  }

  function setStateActive (id) {
    d3.select('#lower-context').html(fipsToState(id))
    d3.select('#state-incidents-label').html('Incidents for ' + yearOfInterest + ':')

    var data = allData.find(function(el) {
      return +el.id === id
    })

    var VARIABLES = [ {name:"num_producing_acres", min:"0", max:data.num_producing_acres*2, start: data.num_producing_acres},
                      {name:"num_of_producible_wells", min:"0", max:data.num_of_producible_wells*2, start: data.num_of_producible_wells},
                      {name:"num_of_producible_completions", min:"0", max:data.num_of_producible_completions*2, start: data.num_of_producible_completions},
                      {name:"employees_mining_loging_1000", min:"0", max:data.employees_mining_loging_1000*2, start: data.employees_mining_loging_1000} ]

    VARIABLES.forEach(function(el,i){
      var num = Math.round(el.start).toLocaleString()
      var slider = document.getElementById('inputf'+(i+1))
      slider.value = num
      slider.min = el.min
      slider.max = el.max
      document.getElementById('outputf'+(i+1)).innerHTML = num
    })
    stateincidents = incidentsByState.find(function(el){return el.key === fipsToState(id, true)})

    line.yaccessor('number_of_hazardous_incidents')
    line.xaccessor('year')
    stateincidents.values.forEach(function(el){ el.number_of_hazardous_incidents = +el.number_of_hazardous_incidents})
    lineChart.datum(stateincidents.values).call(line)

    var newValue = stateincidents.values.find(function(el){return +el.year === yearOfInterest}).number_of_hazardous_incidents
    d3.select('#state-incidents').html(newValue.toLocaleString())
  }

  function setStateCallout (id) {
    // render data table on the page for a specific state (fips id)
    var data = allData.find(function(el) {
      return +el.id === id
    })
    d3.select("#callout-statename").html(fipsToState(id))

    for (prop in data) {
      var domEl = d3.select("#callout-" + prop)
      if (domEl[0][0]) { //check to see if element corresponding to data object exists on dom
        domEl.html(Math.round(data[prop]).toLocaleString())
      }
    }

    d3.select("#callout-predicted-value").html(Math.round(data[year]).toLocaleString())

  }

  function fipsToState (fips, postal) {
    // translate fips id number to state name (default: long)
    // ie. fipsToState(1) -> "Alabama"
    var stateObj = fipsData.find(function(el){
      return +el.id === fips
    })
    return postal ? stateObj.state : stateObj.name
  }


  function calculateTotalIncidents(data, year){
    return data.reduce(function(prev,curr){
      return prev + +curr[year]
    },0)
  }

  function firstLoad(csvData){
    var dict = {
      employees_mining_loging_1000:'f1',
      num_of_producible_wells:'f2',
      num_of_producible_completions:'f3',
      num_producing_acres:'f4'
    }

    csvData.forEach(function(el){

    })

  }
