  var DATAFILE = 'data/randdata.csv' // input data file

  var FACTORS = [ {name:"Producing Acres", min:"0", max:"90000", start:"44,000", step:2000},
                  {name:"Number of Producable Wells", min:"0", max:"40000", start:"12,000", step:1000},
                  {name:"Number of Producible Completions", min:"0", max:"40000", start:"12,000", step:1000},
                  {name:"Mining/Logging Employees", min:"0", max:"40000", start:"12,000", step:1000} ]
  // FACTORS will auto populate the HTML file with the above values


  function theMODEL(inputs) {
    // theMODEL takes in inputs, sends it to the model, and returns a new data array
    // inputs is an array of integers scraped from the sliders: [ f1, f2, f3, f4 ]

    d3.csv('data/randdata2.csv', function(data){
      redrawAfterCall(data)
    })
  }


  // figure out the current year and set a keystring accordingly
  var currentYear = new Date().getFullYear()
  var year = 'predicted_incidents_' + currentYear

  // populate the sliders on the page from the FACTORS array
  FACTORS.forEach(function(el,i){
    d3.select('#labelf'+(i+1)).html(el.name)
    d3.select('#inputf'+(i+1))
        .attr('min',el.min)
        .attr('max',el.max)
        .attr('value',el.start)
    d3.select('#outputf'+(i+1))
        .html(el.start)
  })

  // dictionary for looking up {state: 'property to color by'}
  var colorMap = d3.map()

  var allData,
      fipsData,
      totalIncidents

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
        let position = d3.mouse(document.body);
        d3.select('#tooltip')
          .style('top', ( (position[1] + 30)) + "px")
          .style('left', ( position[0]) + "px");
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
  var width = 600,
      height = 400,
      active = d3.select(null);

  var projection = d3.geo.albersUsa()
      .scale(800)
      .translate([width / 2, height / 2]);

  var zoom = d3.behavior.zoom()
      .translate([0, 0])
      .scale(1)
      .scaleExtent([1, 8])
      .on("zoom", zoomed);

  var path = d3.geo.path()
      .projection(projection);

  var mapSvg = d3.select("#map_container").append("svg")
      .attr("width", width)
      .attr("height", height)
      .on("click", stopped, true);

  mapSvg.append("rect")
      .attr("class", "background")
      .attr("width", width)
      .attr("height", height)
      .on("click", reset);

  var g = mapSvg.append("g");

  mapSvg
      .call(zoom) // delete this line to disable free zooming
      .call(zoom.event);

  // d3 scale for coloring via css
  var quantize = d3.scale.quantize()
      .range(d3.range(9).map(function(i) { return 'q' + i + '-9' }))

  queue()
    .defer(d3.json, 'data/topo/us-states-10m.json') // get map
    .defer(d3.csv, DATAFILE) // get data
    .await(renderFirst)

  function renderFirst(error, us, csvData) {
    if (error) throw error;

    allData = csvData
    setColorKey(allData, year)
    totalIncidents = calculateTotalIncidents(allData, year)
    d3.select('#total-incidents-label').html('Nationwide Predicted Incidents for ' + currentYear + ':')
    d3.select('#total-incidents').html(totalIncidents.toLocaleString())

    // draw map
    g.selectAll("path")
        .data(topojson.feature(us, us.objects.states).features)
      .enter().append("path")
        .attr("d", path)
        .on("click", clicked)
        .attr("class", function(d){
          return 'state ' + quantize(colorMap.get(d.id))
        })
        .on('mouseover', function(d) {
            let me = d3.select(this),
                thisText = fipsToState(+d.id)
            tt.follow(me, thisText)
            setStateCallout(d3.select(this).data()[0].id)
          })
        .on("mouseout", tt.hide )

    g.append("path")
        .datum(topojson.mesh(us, us.objects.states, function(a, b) { return a !== b; }))
        .attr("class", "mesh")
        .attr("d", path);

    // g.selectAll('path')
    //     .data(topojson.feature(us, us.objects.counties).features)
    //   .enter().append("path")
    //     .attr("d", path)
    //     .attr('class', 'county')
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
        scale = .9 / Math.max(dx / width, dy / height),
        translate = [width / 2 - scale * x, height / 2 - scale * y];

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
    g.style("stroke-width", 1.5 / d3.event.scale + "px");
    g.attr("transform", "translate(" + d3.event.translate + ")scale(" + d3.event.scale + ")");
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
  let dispatcher = d3.dispatch('changeInput')
  dispatcher.on('changeInput', function(year){
      // read input values,
      var inputs = [
        d3.select("#inputf1").node().value,
        d3.select("#inputf2").node().value,
        d3.select("#inputf3").node().value,
        d3.select("#inputf4").node().value
      ]

      theMODEL(inputs)
  })

  function redrawAfterCall(data){
    allData = data
    totalIncidents = calculateTotalIncidents(allData, year)
    d3.select('#total-incidents-label').html('Nationwide Predicted Incidents for ' + currentYear + ':')
    d3.select('#total-incidents').html(totalIncidents.toLocaleString())

    setColorKey(allData, year)
    d3.selectAll(".state")
        .attr("class", function(d){
          return 'state ' + quantize(colorMap.get(d.id))
        })
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

  function fipsToState (fips) {
    // translate fips id number to state name (long)
    // ie. fipsToState(1) -> "Alabama"
    var stateObj = fipsData.find(function(el){
      return +el.id === fips
    })
    return stateObj.name
  }


  function calculateTotalIncidents(data, year){
    return data.reduce(function(prev,curr){
      return prev + +curr[year]
    },0)
  }

  function firstLoad(csvData){
    var dict = {
      employees_mining_loging:'f1',
      num_of_producible_wells:'f2',
      num_of_producible_completions:'f3',
      num_producing_acres:'f4'
    }

    csvData.forEach(function(el){

    })

  }
