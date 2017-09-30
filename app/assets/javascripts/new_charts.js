;(function () {
    'use strict';

    var statisticSection = {};
    var gex_beta = true;


    //global vars ///////////////////////////////////////////////////////////////////
    Chart.defaults.global.elements.arc.borderWidth = 0;


    // COMMONS ///////////////////////////////////////

    // CHART FACTORY
    statisticSection.chartFactory = {

        createDoughnutChart: function (canvas_id, uid) {
            var data = {labels: [""], datasets: [{data: [0], backgroundColor: []}]};
            var ctx = document.getElementById(canvas_id);
            var newChart = new Chart(ctx, {
                type: 'doughnut',
                data: data,
                options: returnDefaultDoughnutOptions()
            });

            newChart.config.options.elements.center.text = "N/A";
            return {newChart: newChart, uid: uid};
        },

        createBarChart: function (canvas_id, uid, type) {
            var bar_data = {
                labels: [""],
                datasets: [{
                    label: "Memory Usage",
                    backgroundColor: "rgba(29,135,228,0.6)",
                    borderWidth: 0,
                    hoverBackgroundColor: "rgba(29,135,228,0.8)",
                    data: [0]
                }]
            };
            var ctx = document.getElementById(canvas_id);
            var newChart = new Chart(ctx, {
                type: 'bar',
                data: bar_data,
                options: returnDefaultBarOptions(type)
            });

            return {newChart: newChart, uid: uid};
        },

        createLineChart: function (canvas_id, type) {

            var ctx = document.getElementById(canvas_id);
            var data = {
                datasets: []
            };

            var options = returnDefaultCPULineOptions();

            var chart = new Chart(ctx, {
                type: 'line',
                data: data,
                options: options
            });

            if (type == 'memory' || type == 'disk') {
                chart.options.legend.display = false;
            }

            return [chart, [{id: canvas_id, dataset_name: ''}]];
        }

    };


    // CLUSTER STATISTICS PAGE
    statisticSection.update_nodes = function () {
        $.ajax({
            type: "GET",
            url: "/stats/nodes",
            data: {clusterID : GexUtils.currentClusterId},
            dataType: "json",
            //data: {},
            success: function (raw_data) {
                for (var node_uid in raw_data) {
                    if (!raw_data[node_uid].working) {

                        var dou_chart = find_by_chart_by_uid(node_uid, dou_charts);
                        dou_chart.config.options.elements.center.text = "N/A";
                        dou_chart.config.data.datasets[0].data = 0;
                        dou_chart.update();


                        $('#' + node_uid + '_node_name').css('background-color', 'rgba(212, 208, 208, 0.27)');
                        //$('#node_' + node_uid + '_state_dot').attr("src", sessionImages.orange_dot);
                       // $('#node_' + node_uid + '_state_text').text('Disconnected');
                        $('#node_' + node_uid + '_state_div').hide();

                        var bar_chart = find_by_chart_by_uid(node_uid, ram_charts);
                        var bar_chart1 = find_by_chart_by_uid(node_uid, disk_charts);

                        bar_chart.config.data.datasets[0].data[0] = 0;
                        bar_chart1.config.data.datasets[0].data[0] = 0;

                        bar_chart.update();
                        bar_chart1.update();

                        $('#' + node_uid + '_disk_tooltip').text("Node disconnected");
                        $('#' + node_uid + '_ram_tooltip').text("Node disconnected");

                    }
                    else {

                        //$('#node_' + node_uid + '_state_dot').attr("src", sessionImages.green_dot);
                        //$('#node_' + node_uid + '_state_text').text('Running');

                        $('#' + node_uid + '_node_name').css('background-color', '#fff');
                        $('#node_'+ node_uid +'_state_div').show();

                        var data = format_data(raw_data[node_uid]);

                        if (update_charts(node_uid, data) == false) {
                            console.log('Chart update failed :(');
                        }
                    }
                }
            }
        });
    };



    statisticSection.format_data_for_cpu_dou = function (raw_data) {

        // raw_data format: [[],[],[],[]]

        var labels = [];
        var colors = [];
        var cpu_values = [];
        var cpu_load = 0;

        // CPU chart
        var cpu_apps = raw_data.apps;
        //var cpu_colors = raw_data.cpu.colors;

        for (var app_name in cpu_apps) {

            var used_by_app = cpu_apps[app_name].data[Object.keys(cpu_apps[app_name].data)[0]];
            //cpu_load +=parseInt(used_by_app);
            labels.push(cpu_apps[app_name].name);
            cpu_values.push(used_by_app);
            colors.push(cpu_apps[app_name].color);
        }

        //adding 'Free'
        labels.push('Free CPU');
        cpu_values.push(100 - raw_data.total_cpu);


        return [raw_data.total_cpu, labels, cpu_values, colors];
    };


    function format_data(raw_data) {

        var labels = [];
        var colors = [];
        var cpu_values = [];

        // CPU chart
        var cpu_apps = raw_data.cpu.apps;
        var cpu_colors = raw_data.cpu.colors;

        var cpu_load = 0;

        // RAM chart

        // TODO!! raw_data.ram.used <= it should be raw_data.ram.free
        // tmp fx!
        //var used_ram = raw_data.ram.all - raw_data.ram.used;
        var used_ram = parseFloat(raw_data.ram.all - raw_data.ram.used).toFixed(1);
        var total_ram = parseFloat(raw_data.ram.all).toFixed(1);

        var ram_perc = calc_percent_bar(total_ram, used_ram);
        var ram_data = [ram_perc, total_ram, used_ram];

        // Disk chart
        var total_disk = parseFloat(raw_data.disk.all).toFixed(2);
        var used_disk = parseFloat(raw_data.disk.used).toFixed(2);

        var disk_perc = calc_percent_bar(total_disk, used_disk);
        var disk_data = [disk_perc, total_disk, used_disk];

        for (var app_name in cpu_apps) {

            var used_by_app = cpu_apps[app_name].used;
            var app_color = cpu_colors[app_name];

            cpu_load += parseInt(used_by_app);
            labels.push(app_name);
            cpu_values.push(used_by_app);
            colors.push(app_color);
        }

        //adding 'Free'
        labels.push('Free CPU');
        cpu_values.push(100 - cpu_load);

        return [[cpu_load, labels, cpu_values, colors], ram_data, disk_data];
    }


    statisticSection.update_dou_chart = function(uid, data) {

        var dou_chart = find_by_chart_by_uid(uid, dou_charts);

        dou_chart.config.options.elements.center.text = data[0] + "%";
        dou_chart.config.data.labels = data[1];
        dou_chart.config.data.datasets[0].data = data[2];
        dou_chart.config.data.datasets[0].backgroundColor = data[3];

        dou_chart.update();
    };

    function update_bar_chart(uid, data, type) {

        var bar_chart;
        var tooltip_type;
        var units;

        if (type == 'ram') {
            bar_chart = find_by_chart_by_uid(uid, ram_charts);
            tooltip_type = 'RAM';
            units = "GB";
        }
        if (type == 'disk') {
            bar_chart = find_by_chart_by_uid(uid, disk_charts);
            tooltip_type = 'DISK';
            units = "GB";
        }

        bar_chart.config.data.datasets[0].data[0] = data[0];
        check_danger(bar_chart);
        $('#' + uid + '_' + type + '_tooltip').text(tooltip_type + ' usage: ' + data[2] + units + ' of ' + data[1] + units);

        bar_chart.update();
    }


    function update_charts(uid, data) {
        var success = true;
        //dou update
        statisticSection.update_dou_chart(uid, data[0]);
        //ram update
        update_bar_chart(uid, data[1], 'ram');
        //disk update
        update_bar_chart(uid, data[2], 'disk');
        return success;
    }











    // NODE PAGE ///////////////////////////////////////////////////////////////////////////////

    // line_charts[x][0]  x = 1 || 2 || 3

    // new#func used_now
    function addPoints(line_chart,points) {
        for (var point in points){

            var time = points[point][0];
            var value = parseFloat(points[point][1]).toFixed(3);
           // var value = points[point][1];

            line_chart.chart.config.data.datasets[0].data.push({x: time, y: value});
            line_chart.update();

        }
    }

    // new#func used_now
    function addPoint(line_chart,point,interval) {

        var time = point[0];
        var value = parseFloat(point[1]).toFixed(3);
        //var value = point[1];

        var last_time = line_chart.chart.config.data.datasets[0].data[line_chart.chart.config.data.datasets[0].data.length-1].x;
        var points_on_screen = 120;

        if(last_time != time){
            line_chart.chart.config.data.datasets[0].data.push({x: time, y: value});

            var last_onscreen_now = new Date(line_chart.config.options.scales.xAxes[0].time.min);
            last_onscreen_now.setSeconds(last_onscreen_now.getSeconds() + interval);

            changeMinValue(line_chart,last_onscreen_now,points_on_screen);

            line_chart.update();
        }
    }

    // new#helper used_now
    function changeMinValue(line_chart,value,points_on_screen) {
        if(line_chart.chart.config.data.datasets[0].data.length > points_on_screen){
            line_chart.config.options.scales.xAxes[0].time.min = value;
        }
    }

    // new#helper used_now
    function changeMaxValue(line_chart,value) {
        line_chart.config.options.scales.xAxes[0].time.max = value;
    }

    // new#helper used_now
    function hide_animate(selector) {
        $(selector).animate({opacity: 0}, 800);
        $(selector).hide();
    }

    // new#helper used_now
    function show_animate(selector) {
        $(selector).show();
        $(selector).animate({opacity: 1}, 800);
    }

    // new#helper used_now
    function calcPercent(all,used){
        return Math.round((used/all)*100);
    }

    // new#helper used_now
    function chartByType(type){
        switch(type) {
            case 'cpu':
                return line_charts[0][0];
                break;
            case 'memory':
                return line_charts[1][0];
                break;
        }
    }



    ////// INIT NODE

    // new#request used_now
    statisticSection.requestInitData = function (type, node_uid) {

        var counter_name = 'metrics_'+type;
        if (type=='disk'){counter_name = 'metrics_hdd_total'}

        $.ajax({
            type: "GET",
            url:  "/stats/nodes_history/"+node_uid+"/"+counter_name,
            dataType: "json",
            success: function (data) {

                hide_animate('.'+type+'_loader');

                if (data[0]) {

                    switch (type) {
                        case 'cpu':

                            InitCpu(node_uid, data);
                            show_animate('#dou_chart');
                            break;
                        case 'memory':
                            InitMemory(node_uid, data);
                            show_animate('#memory_data_text');
                            break;
                        case 'disk':
                            InitDisk(node_uid, data);
                            break;
                    }
                    show_animate('#' + type + '_line_chart');
                }
                else{
                    show_animate('#' + type + '_fail_text');
                }
            }
        });
    };

    // used_now
    function InitCpu(node_uid,data){

        //line_chart_add_dataset(line_charts[0][0], 'rgba(0,176,255,0.25)', 'Total');
        line_chart_add_dataset(line_charts[0][0], 'rgba(29, 135, 228, 0.5)', 'Total');
        addPoints(line_charts[0][0],data[1]);

        line_charts[0][0].config.options.scales.xAxes[0].time.min = data[1][0][0];

        updateChart('cpu', node_uid);

        var refreshIntervalId = setInterval(updateChart, refresh_rate,'cpu',node_uid);

    }

    // used_now
    function InitMemory(node_uid,data){
        //line_chart_add_dataset(line_charts[1][0], 'rgba(250,168,0,0.5)', 'Memory');
        //line_chart_add_dataset(line_charts[1][0], 'rgba(100, 255, 218, 0.61)', 'Memory');
        //line_chart_add_dataset(line_charts[1][0], 'rgba(56, 142, 60, 0.4)', 'Memory');

        line_chart_add_dataset(line_charts[1][0], 'rgba(168, 62, 245, 0.4)', 'Memory');


        // TODO!!! - fix free memory/used memory
        // TODO! tmp fix for total & used memory here
        if(data[2]){var total_memory = data[2];}
        var points = data[1];

        for (var point in points){
            if (points[point][1]!=null){
                var used_memory = total_memory - points[point][1];
                points[point][1] = used_memory;
            }
        }


        //addPoints(line_charts[1][0],data[1]);
        addPoints(line_charts[1][0],points);

        line_charts[1][0].config.options.scales.xAxes[0].time.min = data[1][0][0];

        updateChart('memory', node_uid);

        var refreshIntervalId = setInterval(updateChart, refresh_rate,'memory',node_uid);
    }

    // used_now
    function InitDisk(node_uid,data){
        line_chart_add_dataset(line_charts[2][0], 'rgba(0,230,118,0.5)', 'Disk');
        addPoints(line_charts[2][0],data[1]);

        //disk_update(node_uid);
       // var refreshIntervalId = setInterval(disk_update, refresh_rate,node_uid);
    }




    ////// UPDATE NODE

    // used_now
    function updateChart(type, node_uid) {

        var line_chart = chartByType(type);
        var counter_name = 'metrics_'+type;
        if (type=='disk'){counter_name = 'metrics_hdd_total'}

        var last_time = line_chart.chart.config.data.datasets[0].data[line_chart.chart.config.data.datasets[0].data.length - 1].x;
        var date_tmp = new Date(last_time);
        var seconds = Math.round(date_tmp.getTime() / 1000);
        var interval = 60;

        updateChartRequest(node_uid,line_chart,type,counter_name,seconds,interval);

    }

    //  new#request used_now
    function updateChartRequest(node_uid,line_chart,type,counter_name,last_time,interval) {

        $.ajax({
            type: "GET",
            url:  "/stats/nodes/"+node_uid+"/"+counter_name+"/"+last_time+"/"+interval,
            dataType: "json",
            success: function (data) {

                if (data[0] != false) {

                    var res = data[1];
                    var all = res[0];
                    var used = res[1];
                    var time = res[2];

                    switch (type) {
                        case 'cpu':
                            addPoint(line_chart, [time, used],interval);
                            update_cpu_right_block(all,used);
                            line_chart.update();
                            break;
                        case 'memory':

                            // divide 'y' scales (4 parts)
                            line_chart.options.scales.yAxes[0].ticks.max = all;
                            line_chart.options.scales.yAxes[0].ticks.stepSize = Math.round(all / 4);

                            // TODO!!! - fix free memory/used memory
                            used = all - used;

                            update_memory_right_block(all,used);
                            addPoint(line_chart, [time, used],interval);
                            line_chart.update();
                            break;
                        case 'disk':
                            //todo InitDisk(node_uid,data);
                            break;
                    }

                }

            }
        });

    }

    function update_cpu_right_block(all,used) {

        var dou_chart = find_by_chart_by_uid(1234, dou_charts);

        var dou_data = [used, ['Used CPU', 'Free CPU'], [used, 100 - used], ['#1d87e4']];
        statisticSection.update_dou_chart(1234, dou_data);

    }

    function update_memory_right_block(all,used) {

        var perc = calcPercent(all, used);
        var str = 'out of ' + all.toFixed(1) + ' GB';

        $("#all_memory").empty();
        $("#all_memory").append(str);


        $("#used_memory").empty();
        $("#used_memory").append(used.toFixed(1) + ' GB');


        $("#used_memory_perc").empty();
        $("#used_memory_perc").append('(' + perc + '%)');

    }










    // todo remove =>
    var last_onscreen_ind_cpu = 0;
    var last_onscreen_ind_memory = 0;

    // to_remove =>
    function checkPoints(line_chart,period,type){

        //last time point
        var latest = new Date(line_chart.chart.config.data.datasets[0].data[line_chart.chart.config.data.datasets[0].data.length-1].x);

        //oldest time point
        var last_onscreen = new Date(line_chart.config.options.scales.xAxes[0].time.min);

        var diff = (Math.abs(latest - last_onscreen))/1000;

        //line_chart.config.options.scales.xAxes[0].time.unitStepSize = (line_chart.chart.config.data.datasets[0].data.length % 72);


        while(parseInt(diff) > parseInt(period)){



            diff = (Math.abs(latest - last_onscreen))/1000;

            if(type=="cpu"){
                last_onscreen = new Date(line_chart.chart.config.data.datasets[0].data[last_onscreen_ind_cpu].x);
                last_onscreen_ind_cpu = last_onscreen_ind_cpu + 1;
            }
            if(type=="memory"){


                last_onscreen = new Date(line_chart.chart.config.data.datasets[0].data[last_onscreen_ind_memory].x);
                last_onscreen_ind_memory = last_onscreen_ind_memory + 1;
            }
        }

        line_chart.config.options.scales.xAxes[0].time.min = last_onscreen;
    }



    // to_rewrite =>
    function update_cpu_bages(raw_data) {

        $("#apps_bages").html('');
        var bages = raw_data.apps;
        for (var app_item in bages) {

            var s_name = '\'' + bages[app_item].name + '\'';
            var name = bages[app_item].name;
            var data = bages[app_item].data[Object.keys(bages[app_item].data)[0]];


            if (name == app_name) {
                var color = bages[app_item].color;
            }
            else {
                var color = 'rgba(128,128,128,0.3)';
            }

            $("#apps_bages").append('<div class="col-lg-2 col-md-4 col-sm-4 col-xs-6 hand_cursor padd_bott_md"><div class="table-row app_bage_stats" id="bage_stats_' + name + '" style="border-right: 8px ' + color + ' solid;" onclick="add_app_cpu(' + s_name + ')"><div class="padd_left_md padd_ri_md border" style="padding-top: 10px; padding-bottom: 10px"> <h5 class="no_marg inl">' + name + '</h5><div class="pull-right inl"><h5 class="inl gr">' + data + '%</h5></div></div></div></div>');
        }
    }

    // to_remove =>
    function update_cpu_line_chart_old(raw_data) {

        var time = raw_data.total_time;
        var value = raw_data.total_cpu;

        // if app turned on
        if (app_flag) {

            for (var app_item in raw_data.apps) {
                if (raw_data.apps[app_item].name == app_name) {
                    var item1 = raw_data.apps[app_item]
                }
            }

            var color1 = item1.color;
            var data1 = item1.data;
            //var name1 = item1.name;

            line_charts[0][0].chart.config.data.datasets[1].backgroundColor = color1;

            for (var cpu_data in data1) {

                var time = cpu_data;
                var val = data1[cpu_data];

                line_charts[0][0].chart.config.data.datasets[1].data.push({x: moment.utc(time).toDate(), y: val});

            }
        }


        line_charts[0][0].chart.config.data.datasets[0].data.push({x: moment.utc(time).toDate(), y: value});
        line_charts[0][0].update();

        line_charts[0][0].config.options.scales.xAxes[0].time.min = line_charts[0][0].chart.config.data.datasets[0].data[line_charts[0][0].chart.config.data.datasets[0].data.length - onscreen_points].x;
        line_charts[0][0].config.options.scales.xAxes[0].time.max = moment.utc(time).toDate();

        check_chart_arr(line_charts[0][0].chart.config.data.datasets[0].data);

    }


    // to_remove =>
    function cpu_update(uid) {
        $.ajax({
            type: "GET",
            url: "/stats/nodes/"+uid+"/cpu",
            dataType: "json",
            success: function (raw_data) {

                //console.log(raw_data);

                statisticSection.update_dou_chart(1234, statisticSection.format_data_for_cpu_dou(raw_data));
                statisticSection.old_raw_data = raw_data.apps;

                update_cpu_bages(raw_data);
                update_cpu_line_chart(raw_data);

            }
        });
    }

    // to_remove =>
    function memory_update(uid) {
        $.ajax({
            type: "GET",
            url: "/update_stats/"+uid+"/memory",
            dataType: "json",
            success: function (raw_data) {
                update_memory_chart(raw_data);
            }
        });
    }

    // to_remove =>
    function update_memory_chart(raw_data) {
        var time = raw_data.time;
        var value = raw_data.value;

        line_charts[1][0].chart.config.data.datasets[0].data.push({x: time, y: value});
        line_charts[1][0].update();

        line_charts[1][0].config.options.scales.xAxes[0].time.min = line_charts[1][0].chart.config.data.datasets[0].data[line_charts[1][0].chart.config.data.datasets[0].data.length - onscreen_points].x;
        line_charts[1][0].config.options.scales.xAxes[0].time.max = time;

        check_chart_arr(line_charts[1][0].chart.config.data.datasets[0].data)
    }


    // to_remove =>
    function disk_update() {
        $.ajax({
            type: "GET",
            url: "/node_stats_update_disk",
            dataType: "json",
            success: function (raw_data) {
                update_disk_chart(raw_data);
            }
        });
    }

    // to_remove =>
    function update_disk_chart(raw_data) {
        var time = raw_data.time;
        var value = raw_data.value;

        line_charts[2][0].chart.config.data.datasets[0].data.push({x: time, y: value});
        line_charts[2][0].update();

        line_charts[2][0].config.options.scales.xAxes[0].time.min = line_charts[2][0].chart.config.data.datasets[0].data[line_charts[2][0].chart.config.data.datasets[0].data.length - onscreen_points].x;
        line_charts[2][0].config.options.scales.xAxes[0].time.max = time;

        check_chart_arr(line_charts[2][0].chart.config.data.datasets[0].data)
    }


    //helpers ///////////////////////////////////////////////////////////////////
    function check_chart_arr(arr) {
        if (arr.length > 200) arr.splice(0, arr.length - 20)
    }


    function find_by_chart_by_uid(uid, arr) {
        var result = arr.filter(function (obj) {
            return obj.uid == uid;
        });
        return result[0].newChart;
    }

    function calc_percent_bar(all, used) {
        return Math.round(used / (all / 100))
    }

    function rand() {
        return Math.floor(Math.random() * (100 + 1));
    }

    function check_danger(bar_chart) {
        if (bar_chart.config.data.datasets[0].data[0] > 90) {
            bar_chart.config.data.datasets[0].backgroundColor = 'rgba(245, 0, 41, 0.62)';
            bar_chart.config.data.datasets[0].hoverBackgroundColor = 'rgba(245, 0, 41, 0.8)';
        }
        else {
            bar_chart.config.data.datasets[0].backgroundColor = 'rgba(29,135,228,0.6)';
            bar_chart.config.data.datasets[0].hoverBackgroundColor = 'rgba(29,135,228,0.8)';
        }
    }

    //options ///////////////////////////////////////////////////////////////////
    function returnDefaultDoughnutOptions() {
        return {
            legend: {
                display: false
            },
            cutoutPercentage: 60,
            elements: {
                center: {
                    // the longest text that could appear in the center
                    maxText: '100%',
                    text: '0%',
                    fontColor: 'rgba(67,67,67,0.5)',
                    fontFamily: "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
                    fontStyle: 'normal',
                    // fontSize: 12,
                    // if a fontSize is NOT specified, we will scale (within the below limits) maxText to take up the maximum space in the center
                    // if these are not specified either, we default to 1 and 256
                    minFontSize: 1,
                    maxFontSize: 256
                }
            }
        }
    }

    function returnDefaultBarOptions(type) {
        var text;
        if (type == "ram") {
            text = "RAM"
        }
        if (type == "disk") {
            text = "DISK"
        }

        return {
            title: {
                display: true,
                text: text,
                padding: 15
            },
            legend: {
                display: false
            },
            tooltips: {
                enabled: false
            },
            showInlineValues: true,
            scales: {
                xAxes: [{
                    ticks: {
                        max: 100,
                        min: 0,
                        stepSize: 10
                    },
                    barPercentage: 1,
                    categoryPercentage: 1,
                    display: false
                }],
                yAxes: [{
                    ticks: {
                        fontColor: 'rgba(67,67,67,0.5)',
                        padding: 5,
                        fontSize: 10,
                        max: 100,
                        min: 0,
                        stepSize: 25
                    },
                    gridLines: {
                        drawBorder: false,
                        drawTicks: false,
                        offsetGridLines: true
                    },
                    barPercentage: 0.2,
                    categoryPercentage: 0.5,
                }]
            }
        }
    }

    function returnDefaultCPULineOptions() {
        return {
            borderColor: "#434343",

            animationEasing: "easeOutExpo",
            animation: {
                //easing: "easeInQuad"
                duration: 800
            },
            //responsive: false,
            scales: {
                xAxes: [{
                    position: 'bottom',
                    type: 'time',
                    time: {
                        unitStepSize: 12,
                        displayFormats: {
                            quarter: 'MMM YYYY'
                        }
                    }
                }],
                yAxes: [{
                    ticks: {
                        mirror: true,
                        padding: -2,
                        fontColor: 'rgba(67,67,67,0.5)',
                        fontSize: 10,
                        max: 100,
                        min: 0,
                        stepSize: 25

                    }
                }],
                gridLines: {
                    tickMarkLength: 1500,
                    drawBorder: true
                    //offsetGridLines: true
                }
            }
        }
    }


    Chart.pluginService.register({
        afterUpdate: function (chart) {
            if (chart.config.options.elements.center) {
                var helpers = Chart.helpers;
                var centerConfig = chart.config.options.elements.center;
                var globalConfig = Chart.defaults.global;
                var ctx = chart.chart.ctx;

                var fontStyle = helpers.getValueOrDefault(centerConfig.fontStyle, globalConfig.defaultFontStyle);
                var fontFamily = helpers.getValueOrDefault(centerConfig.fontFamily, globalConfig.defaultFontFamily);

                if (centerConfig.fontSize)
                    var fontSize = centerConfig.fontSize;
                // figure out the best font size, if one is not specified
                else {
                    ctx.save();
                    var fontSize = helpers.getValueOrDefault(centerConfig.minFontSize, 1);
                    var maxFontSize = helpers.getValueOrDefault(centerConfig.maxFontSize, 256);
                    var maxText = helpers.getValueOrDefault(centerConfig.maxText, centerConfig.text);

                    do {
                        ctx.font = helpers.fontString(fontSize, fontStyle, fontFamily);
                        var textWidth = ctx.measureText(maxText).width;

                        // check if it fits, is within configured limits and that we are not simply toggling back and forth
                        if (textWidth < chart.innerRadius * 2 && fontSize < maxFontSize)
                            fontSize += 1;
                        else {
                            // reverse last step
                            fontSize -= 1;
                            break;
                        }
                    } while (true)
                    ctx.restore();
                }

                // save properties
                chart.center = {
                    font: helpers.fontString(fontSize, fontStyle, fontFamily),
                    fillStyle: helpers.getValueOrDefault(centerConfig.fontColor, globalConfig.defaultFontColor)
                };
            }
        },
        afterDraw: function (chart) {
            if (chart.center) {
                var centerConfig = chart.config.options.elements.center;
                var ctx = chart.chart.ctx;

                ctx.save();
                ctx.font = chart.center.font;
                ctx.fillStyle = chart.center.fillStyle;
                ctx.textAlign = 'center';
                ctx.textBaseline = 'middle';
                var centerX = (chart.chartArea.left + chart.chartArea.right) / 2;
                var centerY = (chart.chartArea.top + chart.chartArea.bottom) / 2;
                ctx.fillText(centerConfig.text, centerX, centerY);
                ctx.restore();
            }
        }
    });

    window.statisticSection = statisticSection;

}());
