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

  let predictionDomain = d3.extent(lookupTable, function(el){return +el.prediction})
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

