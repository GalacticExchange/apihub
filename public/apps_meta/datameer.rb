# config properties

data = {

    # network
    #"network.network_with_mask" => { description: "Network mask", default_value: "51.0.0.1/8", mandatory: 1, basic: 0, editable: 1},

    #
    "master.host" => {description: "Host of hadoop master node", default_value: "{{master.host}}", mandatory: 1, basic: 1, editable: 0, },
    "master.ip" => {description: "IP of Hadoop master node", default_value: "{{master.ip}}", mandatory: 1, basic: 1, editable: 0, },
    "master.ssh.user" => {description: "ssh user", default_value: "{{master.ssh.user}}", mandatory: 1, basic: 1, editable: 0, visible: 0},
    "master.ssh.password" => {description: "ssh password", default_value: "{{master.ssh.password}}", mandatory: 1, editable: 0, visible: 0},

    # zookeeper
    "zookeeper.url" => {description: "Zookeeper URL", default_value: "{{zookeeper.url}}", mandatory: 1, editable: 0, },
    "zookeeper.host" => {description: "Zookeeper host", default_value: "{{zookeeper.host}}", mandatory: 1, editable: 0, },
    "zookeeper.port" => {description: "Zookeeper port", default_value: "{{zookeeper.port}}", mandatory: 1, editable: 0, },

    # hdfs
    "hdfs.url" => {description: "HDFS URL", default_value: "{{hdfs.url}}", mandatory: 1, editable: 0, },
    "hdfs.host" => {description: "HDFS host", default_value: "{{hdfs.host}}", mandatory: 1, editable: 0, },
    "hdfs.port" => {description: "HDFS port", default_value: "{{hdfs.port}}", mandatory: 1, editable: 0, },

    #datameer
    "datameer.user" => {description: "The user that the application should be started at", default_value: "root", mandatory: 1, editable: 0, },
    "datameer.db_name" => {description: "Mysql database name you will be using, e.g. when running/testing multiple instances", default_value: "embeded_db", mandatory: 1, editable: 0, },
    "datameer.deploy_mode" => {description: "Change deploy mode to live when you want to run in live mode against a mysql db", default_value: "trial", mandatory: 1, editable: 0, },
    "datameer.max_available_mem" => {description: "Adjust max available memory according to your needs ()", default_value: "1024m", mandatory: 1, editable: 0, },
    "datameer.max_http_header_size" => {description: "Edit this if you need to increase the maximum http header size", default_value: "8192", mandatory: 1, editable: 0, },
    "datameer.memory_gc_profiling" => {description: "Type 'y' if you want to do memory/gc profiling", default_value: "no", mandatory: 1, editable: 0, },
    "datameer.log_rotation" => {description: "If gc profiling above is active and you would like log rotation and you have a sun jvm version Java 6 Update 34 or higher. The following will rotate 10 files every time a file reaches 100 MB. Type 'y' to on.", default_value: "no", mandatory: 1, editable: 0},


    # neo4j
    "neo4j.host" => {description: "neo4j host", default_value: "{{neo4j.host}}", mandatory: 1, editable: 0, },
    "neo4j.port" => {description: "neo4j port", default_value: "{{neo4j.port}}", mandatory: 1, editable: 0, },


}


config_params(data)


### services
services({
             'webui' => {name: 'webui', protocol: 'http', port: 8080},
         })


### app_info
app_info = {
    metrics: {
        datameer: {
            memory: 1.35,
            hdd: 3.0
        }
    }
}

app_info(app_info)
