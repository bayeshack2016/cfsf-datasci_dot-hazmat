var DATAFILE = 'data/data.csv' // input data file

var FACTORS = [ {name:"Inflation", min:"0", max:"10", start:"1.1", step:0.1},
                {name:"Gas Price", min:"1", max:"10", start:"2.62", step:0.01},
                {name:"Oil PRice", min:"10", max:"120", start:"50.53", step:0.01} ]
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
      .attr('step',el.step)
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

var width = 900,
    height = 500,
    active = d3.select(null);

var projection = d3.geo.albersUsa()
    .scale(1000)
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
  d3.select("#callout-state").html(fipsToState(id))
  for (prop in data) {
    var domEl = d3.select("#callout-" + prop)
    if (domEl[0][0]) {
      domEl.html(data[prop])
    }
  }
  // debugger
  d3.select("#callout-value").html(data[curYear])
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

debugger
}