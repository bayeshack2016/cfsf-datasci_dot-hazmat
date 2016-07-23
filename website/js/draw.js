// (function() {
  'use strict';

  let Dataset = {
    defaults: {
      parameter: 'precip',
      year: 2009
    },
    dataByBoundary: function(val){
      let result = {}
      this.rawData.forEach((boundary)=>{
        result[boundary.id] = boundary[val];
      })
      return result;
    },
    parameter: function(){ //formerly 'parameter'
        return d3.select('input[name=radio-category]:checked').node().value;
    }
  };


  let mapchart = d3.select('#map_container')
    .append("svg")
    .chart("Choropleth")
    .range('q9s')
    .projection(d3.geo.mercator().center([-122.3129835144942, 37.95379741727219]))
    .scale(10000)
    .height(500)
    .width(480)
    .boundaryClass('temp');



  queue()
    .defer(d3.json, 'data/annual/2009.json')
    .defer(d3.json, 'data/watersheds-topo2.json')
    .await(drawFirst)

  function drawFirst(error, data, geo) {
    Dataset.rawData = data;
    let topoFeat = topojson.feature(geo, geo.objects['watersheds.geo']).features;
    let dataBind = Dataset.dataByTract();
    mapchart.draw({'Geo': topoFeat, 'ToBind': dataBind});
  };

  function drawMap(data){
    Dataset.rawData = data;
    let dataBind = Dataset.dataByBoundary(Dataset.parameter());
    mapchart.draw({'Geo': Dataset.topoFeat, 'ToBind': dataBind});
  }

  /* page listeners */
  // d3.select(window).on('resize', resize);
  d3.select('#dropdown').on('change', function(){
    return dispatcher.changeDemog()
  })
  d3.selectAll('input[name=mf]').on('change', function(){
    return dispatcher.changeParameter()
  })
  d3.select("#citywide").on('click', function(){
    dispatcher.changeTract('citywide')
  });
  d3.select('#something').on('click', function(){
    d3.json('data/annual/1920.json', function(data){
      drawMap(data)
      // mapchart.draw({'Geo': Dataset.topoFeat, 'ToBind': dataBind});
      console.log('did something')
      console.log(data)
    })
  });


  /* dispatcher for events */
  let dispatcher = d3.dispatch('changeTract', 'changeParameter', 'changeDemog')
  dispatcher.on('changeTract', function(tract){
    Dataset.censusTract = tract;
    barchart.draw(Dataset.dataByDemographic());
    // redrawCharts();
  })
  dispatcher.on('changeParameter', function(){
    barchart.parameter(Dataset.parameter())
    barchart.draw(Dataset.dataByDemographic());
    // setMapParameter()
    // redrawMap() //choropleth.js needs redraw method
  })
  dispatcher.on('changeDemog', function(inputDemog){
    Dataset.demographic = inputDemog
    // if (inputDemog) {
    //   setActiveDropdown(inputDemog)
    //   return changeDemographic(inputDemog)
    // }
    // return changeDemographic(selectKey[demog][parameter] )
  })


  // function setActiveDropdown(demog){
  //   var title = categoryDict[demog]
  //   var selList = document.getElementById('dropdown');
  //   for (var i = 0; i < selList.options.length; i++) {
  //    var tmpOptionText = selList.options[i].text;
  //    if(tmpOptionText == title) selList.selectedIndex = i;
  //   }
  // }


  function setTitle(newTitle){
    d3.select('#selected-title').text(newTitle)
  }

// }());