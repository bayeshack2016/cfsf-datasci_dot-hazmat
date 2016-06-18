  var DATAFILE = 'data/data.csv' // input data file

  var FACTORS = [ {name:"Variable 1", min:"0", max:"100", start:"75"},
                  {name:"Variable 2", min:"1", max:"10", start:"3"},
                  {name:"Variable 3", min:"20", max:"50", start:"40"} ]
  // FACTORS will auto populate the HTML file with the above values


  function theMODEL(inputs) {
    // inputs is an array of integers scraped from the sliders: [ f1, f2, f2 ]
    var result

  inputs[0]*inputs[1]-inputs[2]
    result = allData.map(function(el){
      el.value = Math.random()*inputs[0] + Math.random()*inputs[1] + Math.random()*inputs[2]
      return el
    })


    return result // result should look like data.json
  }





  FACTORS.forEach(function(el,i){
    d3.select('#labelf'+(i+1)).html(el.name)
    d3.select('#inputf'+(i+1))
        .attr('min',el.min)
        .attr('max',el.max)
        .attr('value',el.start)
    d3.select('#outputf'+(i+1))
        .html(el.start)
  })

  var colorMap = d3.map()

  var allData,
      curData,
      curState,
      fipsData

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

  var svg = d3.select("#map_container").append("svg")
      .attr("width", width)
      .attr("height", height)
      .on("click", stopped, true);

  svg.append("rect")
      .attr("class", "background")
      .attr("width", width)
      .attr("height", height)
      .on("click", reset);

  var g = svg.append("g");

  svg
      .call(zoom) // delete this line to disable free zooming
      .call(zoom.event);

  let quantize = d3.scale.quantize()
      .range(d3.range(9).map(function(i) { return 'q' + i + '-9' }))

  queue()
    .defer(d3.json, 'data/topo/us-states-10m.json')
    .defer(d3.csv, DATAFILE) //data file here
    .await(renderFirst)

  function renderFirst(error, us, csvData) {
    if (error) throw error;

    allData = csvData
    // allData = firstLoad(csvData)

    var year = 'predicted_incidents_2015'
    curData = allData
    // curData = chooseYear(allData, year)
    setColorKey(curData, year)

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

  function chooseYear(rawdata, year) {
    // filter data for just one year
    var result = []
    rawdata.forEach(function(d){
      if(+d.year === year) result.push(d)
    })
    return result
  }

  function setColorKey (data, value) {
    data.forEach(function(d){
      colorMap.set(d.id, +d[value]);
    })
    quantize.domain( d3.extent(data,function(d){return +d[value]}) )
  }

  function clicked(d) {
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

    svg.transition()
        .duration(750)
        .call(zoom.translate(translate).scale(scale).event);
  }

  function reset() {
    active.classed("active", false);
    active = d3.select(null);

    svg.transition()
        .duration(750)
        .call(zoom.translate([0, 0]).scale(1).event);

    d3.selectAll('.callout').html('')
  }

  function zoomed() {
    g.style("stroke-width", 1.5 / d3.event.scale + "px");
    g.attr("transform", "translate(" + d3.event.translate + ")scale(" + d3.event.scale + ")");
  }

  // If the drag behavior prevents the default click,
  // also stop propagation so we don’t click-to-zoom.
  function stopped() {
    if (d3.event.defaultPrevented) d3.event.stopPropagation();
  }


  /* page listeners */
  d3.select('#data-year-dropdown').on('change', function(){
    return dispatcher.changeYear(this.value);
  })

  d3.select('#recalculate').on('click', recalculate)

  /* dispatcher events */
  let dispatcher = d3.dispatch('changeYear')
  dispatcher.on('changeYear', function(year){
    var sel = document.getElementById('data-year-dropdown');
    var curYear = sel.options[sel.selectedIndex].value
    if (!year) year = curYear
    curData = allData
    // curData = chooseYear(allData, year)
    setColorKey(curData,year)

    d3.selectAll(".state")
        .attr("class", function(d){
          return 'state ' + quantize(colorMap.get(d.id))
        })
    setStateCallout(curState)
  })


  function setStateCallout (id) {
    curState = id
    var sel = document.getElementById('data-year-dropdown');
    var curYear = sel.options[sel.selectedIndex].value
    var data = curData.find(function(el) {
      return +el.id === id
    })
    d3.select("#callout-statename").html(fipsToState(curState))

    for (prop in data) {
      var domEl = d3.select("#callout-" + prop)
      if (domEl[0][0]) {
        domEl.html(Math.round(data[prop]))
      }
    }
    // debugger
    d3.select("#callout-predicted-value").html(Math.round(data.predicted_incidents_2015))
    d3.select("#callout-actual-value").html(data.actual_incidents_2015)
  }

  function fipsToState (fips) {
    var stateObj = fipsData.find(function(el){
      return +el.id === fips
    })
    return stateObj.name
  }

  function recalculate() {
    var inputs = [
      d3.select("#inputf1").node().value,
      d3.select("#inputf2").node().value,
      d3.select("#inputf3").node().value
    ]

    var data = theMODEL(inputs)
    allData = data

    var sel = document.getElementById('data-year-dropdown');
    var curYear = +sel.options[sel.selectedIndex].value

    curData = allData
    // curData = chooseYear(allData, curYear)
    setColorKey(curData,curYear)
    d3.selectAll(".state")
        .attr("class", function(d){
          return 'state ' + quantize(colorMap.get(d.id))
        })
    setStateCallout(curState)
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


(function() {
  'use strict';
  var DATAFILE = 'data/model_demo_df.csv' // input data file

  var FACTORS = [ {name:"Producing Acres", min:"0", max:"90000", start:"44000", step:2000},
                  {name:"Mining/Logging Employees", min:"0", max:"40000", start:"12000", step:1000} ]
  // FACTORS will auto populate the HTML file with the above values

  var lookupTable = []

  function theMODEL(inputs) {
    // inputs is an array of integers scraped from the sliders: [ f1, f2, f2 ]
    var result

    //lookup in the lookup table and return the prediction

    return result
  }

  //change names on sliders
  FACTORS.forEach(function(el,i){
    d3.select('#labelf'+(i+1)).html(el.name)
    d3.select('#inputf'+(i+1))
        .attr('min',el.min)
        .attr('max',el.max)
        .attr('step',el.step)
        .attr('value',el.start)
    d3.select('#outputf'+(i+1))
        .html(el.start)
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


  let color = d3.scale.quantize()
      .range([
        'rgb(255,245,240)',
        'rgb(254,224,210)',
        'rgb(252,187,161)',
        'rgb(252,146,114)',
        'rgb(251,106,74)',
        'rgb(239,59,44)',
        'rgb(203,24,29)',
        'rgb(165,15,21)',
        'rgb(103,0,13)'
      ])




  let width = 900,
      height = 50,
      gaugeMax = width-200

  let svg = d3.select("#chart_container").append("svg")
      .attr("width", width)
      .attr("height", height)

  let g = svg.append('g')
      .attr("class", "gauge-container")
      .attr("width", gaugeMax)
      .attr("height", height)

  g.append("rect")
      .attr("class", "gauge-bar")
      .attr("width", 0)
      .attr("height", height)
      .attr('fill','#fff')
      .attr('stroke','#000')

  g.append("rect")
      .attr("class", "gauge-outline")
      .attr("width", gaugeMax)
      .attr("height", height)

  g.append('text')
      .attr('class', 'gauge-readout')
      .attr('text-anchor','start')
      .attr('alignment-baseline','middle')
      .attr('dx', gaugeMax +10)
      .attr('dy',height/2)
      .text('0')

  let gaugeScale = d3.scale.linear()
        .range([0,gaugeMax])

  function updateGauge(value) {
    let gaugeBar = d3.select('.gauge-bar')
    let gaugeReadout = d3.select('.gauge-readout')
    let newWidth = gaugeScale(value)
    let rounded = Math.round(value*100)/100

    gaugeReadout.text(rounded)
    gaugeBar.transition(200).attr('width',newWidth)
            .attr('fill', color(value))
  }

  queue()
    .defer(d3.csv, DATAFILE, toNum) //data file here
    .await(renderFirst)

  function toNum(d) {
    for (let prop in d) {
        d[prop] = +d[prop]
    }
    return d
  }

  function renderFirst(error, csvData) {
    if (error) throw error;
    lookupTable = csvData;

    let predictionDomain = [0, d3.max(lookupTable, function(el){return +el.prediction})]
    gaugeScale.domain(predictionDomain)
    color.domain(predictionDomain)
    dispatcher.recalculate();
  };


  function getInputValues () {
    let f1 = document.getElementById('inputf1').valueAsNumber,
        f2 = document.getElementById('inputf2').valueAsNumber/1000
    return [f1,f2]
  }

  function lookupPrediction (row, values) {
    return row.num_producing_acres === this[0] && row.employees_mining_logging_1000 === this[1]
  }

  /* page listeners */
  d3.select('#inputf1').on('change', function(){
    return dispatcher.recalculate();
  })

  d3.select('#inputf2').on('change', function(){
    return dispatcher.recalculate();
  })


  /* dispatcher events */
  let dispatcher = d3.dispatch('recalculate')

  dispatcher.on('recalculate', function(){
    //get inputs
    let inputs = getInputValues()

    //lookup prediction from table
    let newVal = lookupTable.find(lookupPrediction,inputs).prediction

    //update gauge
    updateGauge(newVal)
  })


}());